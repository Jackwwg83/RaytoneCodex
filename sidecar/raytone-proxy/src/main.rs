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
use clap::Parser;
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
    net::{IpAddr, Ipv4Addr, SocketAddr},
    path::PathBuf,
    sync::Arc,
};
use tokio::net::TcpListener;
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
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/health/upstream", get(upstream_health))
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

    let Some(api_key) = state.runtime.api_key.as_deref() else {
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
    let upstream = state
        .client
        .post(upstream_url)
        .bearer_auth(api_key)
        .json(&chat_body)
        .send()
        .await
        .map_err(|error| ProxyError::ForwardFailed(error.to_string()))?;

    let status = upstream.status();
    if !status.is_success() {
        let text = upstream
            .text()
            .await
            .unwrap_or_else(|error| error.to_string());
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
        return Ok(Response::builder()
            .status(StatusCode::OK)
            .header(header::CONTENT_TYPE, "text/event-stream")
            .header(header::CACHE_CONTROL, "no-cache")
            .body(Body::from_stream(converted))
            .map_err(|error| ProxyError::Internal(error.to_string()))?);
    }

    let chat_response = upstream
        .json::<Value>()
        .await
        .map_err(|error| ProxyError::ForwardFailed(error.to_string()))?;
    let response = chat_completion_to_response_with_context(chat_response, &tool_context)?;
    if let Err(error) = record_history(&state.history, &response).await {
        warn!(%error, "failed to record response history");
    }
    Ok(Json(response).into_response())
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
