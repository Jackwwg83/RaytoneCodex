use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::{env, fs, path::Path};

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct CodexChatReasoningConfig {
    #[serde(rename = "supportsThinking", skip_serializing_if = "Option::is_none")]
    pub supports_thinking: Option<bool>,
    #[serde(rename = "supportsEffort", skip_serializing_if = "Option::is_none")]
    pub supports_effort: Option<bool>,
    #[serde(rename = "thinkingParam", skip_serializing_if = "Option::is_none")]
    pub thinking_param: Option<String>,
    #[serde(rename = "effortParam", skip_serializing_if = "Option::is_none")]
    pub effort_param: Option<String>,
    #[serde(rename = "effortValueMode", skip_serializing_if = "Option::is_none")]
    pub effort_value_mode: Option<String>,
    #[serde(rename = "outputFormat", skip_serializing_if = "Option::is_none")]
    pub output_format: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ProviderMeta {
    #[serde(rename = "apiFormat", skip_serializing_if = "Option::is_none")]
    pub api_format: Option<String>,
    #[serde(rename = "codexChatReasoning", skip_serializing_if = "Option::is_none")]
    pub codex_chat_reasoning: Option<CodexChatReasoningConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Provider {
    pub id: String,
    pub name: String,
    #[serde(default)]
    pub settings_config: Value,
    #[serde(default)]
    pub meta: Option<ProviderMeta>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ProxyConfig {
    pub current_provider: Option<String>,
    #[serde(default)]
    pub providers: Vec<ProviderConfig>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ProviderConfig {
    pub id: String,
    pub name: Option<String>,
    pub base_url: String,
    pub api_key: Option<String>,
    pub api_key_env: Option<String>,
    pub model: String,
    #[serde(default)]
    pub models: Vec<String>,
    #[serde(default)]
    pub reasoning: Option<CodexChatReasoningConfig>,
}

#[derive(Debug, Clone)]
pub struct ProviderRuntime {
    pub provider: Provider,
    pub base_url: String,
    pub api_key: Option<String>,
    pub model: String,
    pub models: Vec<String>,
}

impl ProxyConfig {
    pub fn load(path: &Path) -> anyhow::Result<Self> {
        let text = fs::read_to_string(path)?;
        Ok(toml::from_str(&text)?)
    }

    pub fn selected_provider(&self, id_override: Option<&str>) -> anyhow::Result<ProviderRuntime> {
        let selected = id_override
            .or(self.current_provider.as_deref())
            .or_else(|| self.providers.first().map(|provider| provider.id.as_str()))
            .ok_or_else(|| anyhow::anyhow!("no provider configured"))?;

        let config = self
            .providers
            .iter()
            .find(|provider| provider.id == selected)
            .ok_or_else(|| anyhow::anyhow!("provider '{selected}' not found"))?;

        Ok(config.runtime())
    }
}

impl ProviderConfig {
    fn runtime(&self) -> ProviderRuntime {
        let name = self.name.clone().unwrap_or_else(|| self.id.clone());
        let mut catalog_models = self.models.clone();
        if !catalog_models.iter().any(|model| model == &self.model) {
            catalog_models.insert(0, self.model.clone());
        }

        let model_catalog = json!({
            "models": catalog_models
                .iter()
                .map(|model| json!({ "model": model }))
                .collect::<Vec<_>>()
        });
        let settings_config = json!({
            "api_format": "openai_chat",
            "apiFormat": "openai_chat",
            "base_url": self.base_url,
            "model": self.model,
            "modelCatalog": model_catalog
        });
        let provider = Provider {
            id: self.id.clone(),
            name,
            settings_config,
            meta: Some(ProviderMeta {
                api_format: Some("openai_chat".to_string()),
                codex_chat_reasoning: self.reasoning.clone(),
            }),
        };

        ProviderRuntime {
            provider,
            base_url: self.base_url.clone(),
            api_key: self.resolve_api_key(),
            model: self.model.clone(),
            models: catalog_models,
        }
    }

    fn resolve_api_key(&self) -> Option<String> {
        self.api_key
            .as_deref()
            .map(str::trim)
            .filter(|key| !key.is_empty())
            .map(ToString::to_string)
            .or_else(|| {
                self.api_key_env
                    .as_deref()
                    .and_then(|name| env::var(name).ok())
                    .map(|key| key.trim().to_string())
                    .filter(|key| !key.is_empty())
            })
            .or_else(|| {
                let fallback = format!(
                    "RAYTONE_{}_API_KEY",
                    self.id
                        .chars()
                        .map(|ch| if ch.is_ascii_alphanumeric() { ch } else { '_' })
                        .collect::<String>()
                        .to_ascii_uppercase()
                );
                env::var(fallback)
                    .ok()
                    .map(|key| key.trim().to_string())
                    .filter(|key| !key.is_empty())
            })
    }
}

