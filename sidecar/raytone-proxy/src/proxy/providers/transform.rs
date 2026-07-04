// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Jason Young
// Source: cc-switch src-tauri/src/proxy/providers/transform.rs

/// Detect OpenAI o-series reasoning models (o1, o3, o4-mini, etc.).
pub fn is_openai_o_series(model: &str) -> bool {
    model.len() > 1
        && model.starts_with('o')
        && model.as_bytes().get(1).is_some_and(|b| b.is_ascii_digit())
}

/// Detect OpenAI models that support reasoning_effort.
pub fn supports_reasoning_effort(model: &str) -> bool {
    is_openai_o_series(model)
        || model
            .to_lowercase()
            .strip_prefix("gpt-")
            .and_then(|rest| rest.chars().next())
            .is_some_and(|c| c.is_ascii_digit() && c >= '5')
}

