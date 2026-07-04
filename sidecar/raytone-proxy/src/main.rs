mod provider;
mod proxy;

use axum::{
    body::Body,
    extract::{OriginalUri, State},
    http::{header, HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    routing::{get, post},
    Json, Router,
};
use bytes::Bytes;
use clap::Parser;
use futures::{Stream, StreamExt};
use provider::{ProviderRuntime, ProxyConfig};
use proxy::{
    error::ProxyError,
    providers::{
        codex::{
            apply_codex_chat_upstream_model, is_origin_only_url,
            resolve_codex_chat_reasoning_config, should_convert_codex_responses_to_chat,
        },
        codex_chat_history::CodexChatHistoryStore,
        streaming_codex_chat::create_responses_sse_stream_from_chat_with_context,
        transform_codex_chat::{
            build_codex_tool_context_from_request, chat_completion_to_response_with_context,
            chat_error_to_response_error, responses_to_chat_completions_with_reasoning,
        },
    },
};
use reqwest::Client;
use serde_json::{json, Value};
use std::{
    io,
    net::{IpAddr, Ipv4Addr, SocketAddr},
    path::PathBuf,
    sync::Arc,
    time::{SystemTime, UNIX_EPOCH},
};
use tokio::net::TcpListener;
use tokio::sync::Mutex;
use tracing::{info, warn};

#[derive(Debug, Parser)]
#[command(author, version, about = "RaytoneCodex local Responses to Chat sidecar")]
struct Args {
    #[arg(long, default_value = "127.0.0.1")]
    host: IpAddr,
    #[arg(long, default_value_t = 8765)]
    port: u16,
    #[arg(long, value_name = "PATH", default_value = "sidecar/raytone-proxy/config.example.toml")]
    config: PathBuf,
    #[arg(long)]
    provider: Option<String>,
}

#[derive(Clone)]
struct AppState {
    client: Client,
    runtime: Arc<ProviderRuntime>,
    history: Arc<CodexChatHistoryStore>,
    usage: Arc<Mutex<UsageStats>>,
}

#[derive(Debug, Default)]
struct UsageStats {
    requests: u64,
    successful_responses: u64,
    failed_responses: u64,
    input_tokens: u64,
    output_tokens: u64,
    total_tokens: u64,
    reasoning_tokens: u64,
    last_usage: Option<Value>,
    last_error: Option<String>,
    last_updated_unix_ms: Option<u64>,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "raytone_proxy=info".into()),
        )
        .with_writer(std::io::stderr)
        .init();

    let args = Args::parse();
    let config = ProxyConfig::load(&args.config)?;
    let runtime = Arc::new(config.selected_provider(args.provider.as_deref())?);
    let state = AppState {
        client: Client::new(),
        runtime,
        history: Arc::new(CodexChatHistoryStore::default()),
        usage: Arc::new(Mutex::new(UsageStats::default())),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/health/upstream", get(upstream_health))
        .route("/usage", get(usage))
        .route("/v1/models", get(models))
        .route("/models", get(models))
        .route("/v1/responses", post(responses))
        .route("/responses", post(responses))
        .with_state(state.clone());

    let host = match args.host {
        IpAddr::V4(ip) => ip,
        IpAddr::V6(_) => Ipv4Addr::LOCALHOST,
    };
    let listener = TcpListener::bind(SocketAddr::from((host, args.port))).await?;
    let addr = listener.local_addr()?;
    println!(
        "{}",
        json!({
            "event": "listening",
            "host": addr.ip().to_string(),
            "port": addr.port(),
        })
    );
    info!(%addr, provider = %state.runtime.provider.id, model = %state.runtime.model, "raytone-proxy listening");

    axum::serve(listener, app)
        .with_graceful_shutdown(async {
            let _ = tokio::signal::ctrl_c().await;
        })
        .await?;

    Ok(())
}

async fn health(State(state): State<AppState>) -> impl IntoResponse {
    Json(json!({
        "ok": true,
        "provider": state.runtime.provider.id,
        "model": state.runtime.model,
        "hasApiKey": state.runtime.api_key.is_some(),
        "baseUrl": state.runtime.base_url,
    }))
}

async fn usage(State(state): State<AppState>) -> impl IntoResponse {
    let stats = state.usage.lock().await;
    Json(json!({
        "ok": true,
        "provider": state.runtime.provider.id,
        "model": state.runtime.model,
        "baseUrl": state.runtime.base_url,
        "requests": stats.requests,
        "successfulResponses": stats.successful_responses,
        "failedResponses": stats.failed_responses,
        "inputTokens": stats.input_tokens,
        "outputTokens": stats.output_tokens,
        "totalTokens": stats.total_tokens,
        "reasoningTokens": stats.reasoning_tokens,
        "lastUsage": stats.last_usage,
        "lastError": stats.last_error,
        "lastUpdatedUnixMs": stats.last_updated_unix_ms,
    }))
}

async fn upstream_health(State(state): State<AppState>) -> Response {
    match check_upstream_models(&state).await {
        Ok(body) => Json(body).into_response(),
        Err(error) => error.into_response(),
    }
}

async fn check_upstream_models(state: &AppState) -> Result<Value, ProxyError> {
    let Some(api_key) = state.runtime.api_key.as_deref() else {
        return Err(ProxyError::AuthError(format!(
            "provider '{}' has no API key",
            state.runtime.provider.id
        )));
    };

    let models_url = build_upstream_models_url(&state.runtime.base_url);
    let upstream = state
        .client
        .get(&models_url)
        .bearer_auth(api_key)
        .send()
        .await
        .map_err(|error| ProxyError::ForwardFailed(error.to_string()))?;

    let status = upstream.status();
    let text = upstream
        .text()
        .await
        .unwrap_or_else(|error| error.to_string());
    if !status.is_success() {
        return Err(ProxyError::UpstreamError {
            status: status.as_u16(),
            body: Some(text),
        });
    }

    let parsed = serde_json::from_str::<Value>(&text).unwrap_or_else(|_| json!({}));
    let model_ids = extract_model_ids(&parsed);
    Ok(json!({
        "ok": true,
        "provider": state.runtime.provider.id,
        "model": state.runtime.model,
        "modelsEndpoint": models_url,
        "modelCount": model_ids.len(),
        "models": model_ids,
    }))
}

async fn models(State(state): State<AppState>) -> impl IntoResponse {
    let provider = &state.runtime.provider.id;
    Json(json!({
        "object": "list",
        "data": state.runtime.models.iter().map(|model| {
            json!({
                "id": model,
                "object": "model",
                "created": 0,
                "owned_by": provider,
            })
        }).collect::<Vec<_>>()
    }))
}

async fn responses(
    State(state): State<AppState>,
    OriginalUri(uri): OriginalUri,
    headers: HeaderMap,
    Json(mut body): Json<Value>,
) -> Response {
    match forward_responses(state, uri.path(), headers, &mut body).await {
        Ok(response) => response,
        Err(error) => error.into_response(),
    }
}

async fn forward_responses(
    state: AppState,
    endpoint: &str,
    _headers: HeaderMap,
    body: &mut Value,
) -> Result<Response, ProxyError> {
    if !should_convert_codex_responses_to_chat(&state.runtime.provider, endpoint) {
        return Err(ProxyError::InvalidRequest(format!(
            "endpoint {endpoint} is not a Codex Responses route"
        )));
    }
    record_usage_request(&state.usage).await;

    let Some(api_key) = state.runtime.api_key.as_deref() else {
        record_usage_failure(
            &state.usage,
            format!("provider '{}' has no API key", state.runtime.provider.id),
        )
        .await;
        return Err(ProxyError::AuthError(format!(
            "provider '{}' has no API key",
            state.runtime.provider.id
        )));
    };

    let restored = state.history.enrich_request(body).await;
    if restored > 0 {
        info!(restored, "restored previous Codex tool calls from history");
    }

    apply_codex_chat_upstream_model(&state.runtime.provider, body);
    let tool_context = build_codex_tool_context_from_request(body);
    let reasoning = resolve_codex_chat_reasoning_config(&state.runtime.provider, body);
    let mut chat_body =
        responses_to_chat_completions_with_reasoning(body.clone(), reasoning.as_ref())?;
    apply_codex_chat_upstream_model(&state.runtime.provider, &mut chat_body);

    let upstream_url = build_upstream_url(&state.runtime.base_url, "chat/completions");
    let upstream = match state
        .client
        .post(upstream_url)
        .bearer_auth(api_key)
        .json(&chat_body)
        .send()
        .await
    {
        Ok(upstream) => upstream,
        Err(error) => {
            let message = error.to_string();
            record_usage_failure(&state.usage, message.clone()).await;
            return Err(ProxyError::ForwardFailed(message));
        }
    };

    let status = upstream.status();
    if !status.is_success() {
        let text = upstream
            .text()
            .await
            .unwrap_or_else(|error| error.to_string());
        record_usage_failure(
            &state.usage,
            format!("upstream returned {}: {}", status.as_u16(), text),
        )
        .await;
        let parsed = serde_json::from_str::<Value>(&text).ok();
        let body = chat_error_to_response_error(parsed.as_ref());
        let response_status =
            StatusCode::from_u16(status.as_u16()).unwrap_or(StatusCode::BAD_GATEWAY);
        return Ok((response_status, Json(body)).into_response());
    }

    let is_stream = chat_body
        .get("stream")
        .and_then(|value| value.as_bool())
        .unwrap_or(false);

    if is_stream {
        let stream = upstream.bytes_stream();
        let converted = create_responses_sse_stream_from_chat_with_context(stream, tool_context);
        let recorded = record_usage_from_responses_sse_stream(converted, state.usage.clone());
        return Ok(Response::builder()
            .status(StatusCode::OK)
            .header(header::CONTENT_TYPE, "text/event-stream")
            .header(header::CACHE_CONTROL, "no-cache")
            .body(Body::from_stream(recorded))
            .map_err(|error| ProxyError::Internal(error.to_string()))?);
    }

    let chat_response = upstream
        .json::<Value>()
        .await
        .map_err(|error| ProxyError::ForwardFailed(error.to_string()))?;
    let response = chat_completion_to_response_with_context(chat_response, &tool_context)?;
    record_usage_success(&state.usage, response.get("usage")).await;
    if let Err(error) = record_history(&state.history, &response).await {
        warn!(%error, "failed to record response history");
    }
    Ok(Json(response).into_response())
}

async fn record_usage_request(usage: &Arc<Mutex<UsageStats>>) {
    let mut stats = usage.lock().await;
    stats.requests += 1;
    stats.last_updated_unix_ms = Some(now_unix_ms());
}

async fn record_usage_failure(usage: &Arc<Mutex<UsageStats>>, error: String) {
    let mut stats = usage.lock().await;
    stats.failed_responses += 1;
    stats.last_error = Some(error);
    stats.last_updated_unix_ms = Some(now_unix_ms());
}

async fn record_usage_success(usage: &Arc<Mutex<UsageStats>>, value: Option<&Value>) {
    let usage_value = normalize_response_usage(value);
    let mut stats = usage.lock().await;
    stats.successful_responses += 1;
    stats.input_tokens += usage_value
        .get("input_tokens")
        .and_then(Value::as_u64)
        .unwrap_or(0);
    stats.output_tokens += usage_value
        .get("output_tokens")
        .and_then(Value::as_u64)
        .unwrap_or(0);
    stats.total_tokens += usage_value
        .get("total_tokens")
        .and_then(Value::as_u64)
        .unwrap_or(0);
    stats.reasoning_tokens += usage_value
        .pointer("/output_tokens_details/reasoning_tokens")
        .and_then(Value::as_u64)
        .unwrap_or(0);
    stats.last_usage = Some(usage_value);
    stats.last_error = None;
    stats.last_updated_unix_ms = Some(now_unix_ms());
}

fn record_usage_from_responses_sse_stream(
    stream: impl Stream<Item = Result<Bytes, io::Error>> + Send + 'static,
    usage: Arc<Mutex<UsageStats>>,
) -> impl Stream<Item = Result<Bytes, io::Error>> + Send {
    async_stream::stream! {
        tokio::pin!(stream);
        while let Some(chunk) = stream.next().await {
            match chunk {
                Ok(bytes) => {
                    if let Some(usage_value) = response_completed_usage_from_sse_bytes(&bytes) {
                        record_usage_success(&usage, Some(&usage_value)).await;
                    }
                    yield Ok(bytes);
                }
                Err(error) => {
                    record_usage_failure(&usage, error.to_string()).await;
                    yield Err(error);
                }
            }
        }
    }
}

fn response_completed_usage_from_sse_bytes(bytes: &[u8]) -> Option<Value> {
    let text = std::str::from_utf8(bytes).ok()?;
    for block in text.split("\n\n") {
        if !block.contains("event: response.completed") {
            continue;
        }
        let data = block
            .lines()
            .filter_map(|line| line.strip_prefix("data:"))
            .map(str::trim)
            .collect::<Vec<_>>()
            .join("\n");
        if data.is_empty() {
            continue;
        }
        let value = serde_json::from_str::<Value>(&data).ok()?;
        if let Some(usage) = value.pointer("/response/usage").cloned() {
            return Some(usage);
        }
    }
    None
}

fn normalize_response_usage(value: Option<&Value>) -> Value {
    let Some(value) = value.filter(|value| value.is_object()) else {
        return json!({
            "input_tokens": 0,
            "output_tokens": 0,
            "total_tokens": 0,
            "output_tokens_details": { "reasoning_tokens": 0 }
        });
    };
    let input_tokens = value
        .get("input_tokens")
        .and_then(Value::as_u64)
        .unwrap_or(0);
    let output_tokens = value
        .get("output_tokens")
        .and_then(Value::as_u64)
        .unwrap_or(0);
    let total_tokens = value
        .get("total_tokens")
        .and_then(Value::as_u64)
        .unwrap_or(input_tokens + output_tokens);
    let mut normalized = value.clone();
    normalized["input_tokens"] = json!(input_tokens);
    normalized["output_tokens"] = json!(output_tokens);
    normalized["total_tokens"] = json!(total_tokens);
    if normalized
        .pointer("/output_tokens_details/reasoning_tokens")
        .and_then(Value::as_u64)
        .is_none()
    {
        normalized["output_tokens_details"] = json!({ "reasoning_tokens": 0 });
    }
    normalized
}

fn now_unix_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_millis() as u64)
        .unwrap_or(0)
}

async fn record_history(
    history: &CodexChatHistoryStore,
    response: &Value,
) -> Result<(), ProxyError> {
    let _ = history.record_response(response).await;
    Ok(())
}

fn build_upstream_url(base_url: &str, endpoint: &str) -> String {
    let base_trimmed = base_url.trim_end_matches('/');
    let endpoint_trimmed = endpoint.trim_start_matches('/');

    let mut url = if base_trimmed.ends_with("/chat/completions") {
        base_trimmed.to_string()
    } else if base_trimmed.ends_with("/v1") {
        format!("{base_trimmed}/{endpoint_trimmed}")
    } else if is_origin_only_url(base_trimmed) {
        format!("{base_trimmed}/v1/{endpoint_trimmed}")
    } else {
        format!("{base_trimmed}/{endpoint_trimmed}")
    };

    while url.contains("/v1/v1") {
        url = url.replace("/v1/v1", "/v1");
    }
    url
}

fn build_upstream_models_url(base_url: &str) -> String {
    let base_trimmed = base_url.trim_end_matches('/');
    let mut url = if let Some(prefix) = base_trimmed.strip_suffix("/chat/completions") {
        format!("{}/models", prefix.trim_end_matches('/'))
    } else if base_trimmed.ends_with("/v1") {
        format!("{base_trimmed}/models")
    } else if is_origin_only_url(base_trimmed) {
        format!("{base_trimmed}/v1/models")
    } else {
        format!("{base_trimmed}/models")
    };

    while url.contains("/v1/v1") {
        url = url.replace("/v1/v1", "/v1");
    }
    url
}

fn extract_model_ids(value: &Value) -> Vec<String> {
    value
        .get("data")
        .or_else(|| value.get("models"))
        .and_then(|models| models.as_array())
        .map(|models| {
            models
                .iter()
                .filter_map(|model| {
                    if let Some(id) = model.get("id").and_then(Value::as_str) {
                        Some(id.to_string())
                    } else if let Some(model) = model.get("model").and_then(Value::as_str) {
                        Some(model.to_string())
                    } else {
                        model.as_str().map(ToString::to_string)
                    }
                })
                .collect()
        })
        .unwrap_or_default()
}
