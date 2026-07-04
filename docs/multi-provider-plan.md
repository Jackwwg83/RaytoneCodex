# RaytoneCodex 多 Provider 方案(面向普通用户 · 内置中国模型)

日期：2026-06-09
范围：在现有原生 SwiftUI Mac 客户端上加"多 Provider"能力,让普通用户一键用 GLM-5.1 / Kimi / DeepSeek / MiniMax / 本地 vLLM,无需配 config.toml/环境变量。

## 0. 关键事实与决策
- **Codex(latest main 已确认)只支持 `wire_api = "responses"`**,`"chat"` 已删除(`codex-rs/model-provider-info/src/lib.rs`:`WireApi` 仅 `Responses`)。
- GLM/Kimi/DeepSeek/MiniMax 对外是 **Chat Completions**,所以必须有一层 **Responses→Chat 翻译**。
- 不用 LiteLLM(企业级大网关、捆 Python、太重)。不 patch Codex 源码(逆上游、每次升级要 rebase)。
- **决策:做一个本地 sidecar 翻译层,夹在 Codex 与各 provider 之间;Codex 不改一行,只把 `model_providers.<x>.base_url` 指向 sidecar。**
- sidecar 实现:**vendor cc-switch(MIT)的翻译内核 3-4 个文件 + 自写 ~200 行 axum/reqwest 壳**(方案 B)。
  - 兼容性好:sidecar 只依赖稳定的 HTTP Responses/Chat 协议,Codex 怎么升级都不影响它。
  - 体积小:Rust 单二进制 sidecar,随 app bundle。
  - 法务:cc-switch 是 **MIT**;vendor 的文件保留其 MIT 版权+许可声明,NOTICE 注明"含基于 cc-switch (MIT) 的修改"。

## 1. 架构
```
RaytoneCodex(SwiftUI 原生)
  ├ 起 codex app-server(你现有源码构建,wire_api="responses",不改)
  │    └ model_providers.<id>.base_url → http://127.0.0.1:<port>/v1
  └ 起 raytone-proxy(本地 sidecar,Rust,随 app bundle)
       └ POST /v1/responses ── Responses→Chat 翻译(vendor cc-switch 内核)──▶ 各 provider /v1/chat/completions
                                                                              (GLM / Kimi / DeepSeek / MiniMax / 本地 vLLM)
```
- 一个 provider 一个端口,或单二进制按 `?provider=` / 路径前缀分发(二选一,先单 provider 简单)。
- Codex 仍走 §(之前)的 app-server 流式;provider 切换 = 改 Codex 的 `model`/`model_provider` + 让 sidecar 指向对应上游。

## 2. sidecar 实现(方案 B)
**Vendor 自 cc-switch(原样搬,勿重写——内含大量边界处理)**,路径 `third_party/cc-switch-main/src-tauri/src/proxy/`:
- `providers/transform_codex_chat.rs`(请求 Responses→Chat + 非流式响应转换)
- `providers/streaming_codex_chat.rs`(Chat SSE → Responses SSE 状态机:文本/`reasoning_content`/`<think>` 内联/tool_calls 增量/usage)
- `providers/codex_chat_common.rs`(reasoning 字段提取、function_call item)
- `proxy/codex.rs:28-398` 的 gate + per-provider reasoning 推断;`proxy/error.rs`、`json_canonical.rs`、`sse.rs`
- 可选 `providers/codex_chat_history.rs`(`previous_response_id` 的工具调用上下文回放)
- 这些只依赖两个普通 struct(`Provider`、`CodexChatReasoningConfig`,见 `src-tauri/src/provider.rs:368`)——用我们自己的配置 struct 替换即可,**不碰 Tauri/DB**。

**自写的壳(~200 行):**
- `axum 0.7` + `axum::serve`,`reqwest 0.12`(stream),`tokio`。
- 路由:`POST /v1/responses`(+ `/responses`)→ handler;`GET /v1/models` 返回静态目录(Codex 会做可达性探测);`GET /health`。
- handler 流程:读 Responses JSON → 建 tool context → `responses_to_chat_completions_with_reasoning(body, reasoning)` → 改 `model` 为 provider.model、POST `{base_url}/chat/completions`(`Authorization: Bearer`)→ 流式:`create_responses_sse_stream_from_chat_with_context(upstream, ctx)`;非流式:`chat_completion_to_response_with_context`;错误:`chat_error_to_response_error`。
- provider 配置(sidecar 侧 TOML):`id / base_url / api_key / model / reasoning{thinking_param, effort_param, output_format, supports_thinking}`。
- 监听 `127.0.0.1`(仅回环),端口随机或固定;app 退出时关掉。
- vLLM 开箱可用(翻译层已在空工具时去掉 `tool_choice/parallel_tool_calls`、注入 `stream_options.include_usage`)。

## 3. Provider 预设(抄自 cc-switch `src/config/codexProviderPresets.ts`,均 `apiFormat:"openai_chat"`)
> 注:cc-switch 这份是前瞻版,**model id 以各家官方当前文档为准**,base_url 形态如下、用户可改;首启用"测试连接"校验。

| Provider | base_url | model(示例) | reasoning 映射 |
|---|---|---|---|
| DeepSeek | `https://api.deepseek.com` | deepseek 系列 | thinking_param=`thinking`,effort_param=`reasoning_effort`(deepseek 风格),output=`reasoning_content`,支持 effort |
| Zhipu GLM | `https://open.bigmodel.cn/api/coding/paas/v4`(海外 `https://api.z.ai/api/coding/paas/v4`) | glm 系列 | thinking_param=`thinking`,无 effort,output=`reasoning_content` |
| Kimi(Moonshot) | `https://api.moonshot.cn/v1` | kimi 系列 | thinking_param=`thinking`,output=`reasoning_content` |
| MiniMax | `https://api.minimaxi.com/v1`(海外 `.io`) | MiniMax 系列 | thinking_param=`reasoning_split`,output=`reasoning_details` |
| 通义 Qwen/Bailian | `https://dashscope...` | qwen 系列 | `enable_thinking` |
| 本地 vLLM | `http://127.0.0.1:<port>/v1` | 自填 | 视模型而定 |

第三方鉴权统一 `Authorization: Bearer <API_KEY>`;config.toml 侧 `requires_openai_auth=true`。

## 4. Codex 端配置(由 app 生成/管理)
`~/.codex/config.toml`(或 app 私有 CODEX_HOME):
```toml
model = "<provider 的 model>"
model_provider = "raytone-<id>"
[model_providers.raytone-glm]
name = "GLM (via Raytone)"
base_url = "http://127.0.0.1:<port>/v1"
env_key = "RAYTONE_PROXY_KEY"     # 占位;真实 key 在 sidecar 侧注入上游
wire_api = "responses"
```
> Codex→sidecar 这段本地不需要真 key(可用占位);真正的 provider API key 由 sidecar 持有并加到上游请求。Key 存 macOS Keychain,不明文落盘。

## 5. 与 RaytoneCodex 集成(Swift 侧,改动小)
- 打包:把 `raytone-proxy` 二进制随 app bundle(类似现在 bundle codex);构建脚本加一步 `cargo build --release`。
- `SessionStore`/runtime:加 provider 状态(当前 provider、列表、各自连接态);起 app-server 前先起 sidecar(选端口、写 config.toml 的 model_providers、健康检查),app 退出时一并关。
- 连接态扩展:sidecar 未起/崩 → 一个明确状态;provider key 缺失/无效(上游 401)→ 引导去"模型与提供方"填 key。
- AccessMode/沙箱、app-server 流式、审批等**都不变**。

## 6. UI 新增(挂到现有结构)
1. **首启向导**:选 Provider → 贴 API Key → 测试连接 → 完成(普通用户最关键的一屏)。
2. **设置 →「模型与提供方」pane**:provider 列表(GLM/Kimi/DeepSeek/MiniMax/本地/OpenAI),每项:启用、API Key(掩码+Keychain)、base_url、model、Thinking 开关、测试连接、状态徽章。
3. **composer 模型下拉 → 升级为「Provider › Model」两级**:provider 图标 + 模型 + thinking 徽章。
4. **代理/运行时状态**:在「环境信息」或状态栏显示 sidecar 运行/端口/健康 + 当前 provider 连接态。
5. **「使用情况和计费」做成 per-provider** token/费用(现在是占位页)。
6. **本地模型接入**(Mac Studio vLLM):endpoint + model + 测试。
7. 友好诊断:Key 无效 / 连不上 sidecar / 模型不支持 thinking 的明确中文提示。

## 7. 法务 / 风险
- cc-switch MIT:vendor 文件头保留其版权+许可;NOTICE 写明来源与修改。codex 仍 Apache-2.0,沿用现有 LICENSE/NOTICE。
- model id 用前瞻命名,务必以各家官方文档当前值为准;base_url 用户可改。
- 各家 reasoning 字段差异由 vendor 的 `codex.rs` 推断表 + per-provider reasoning 配置覆盖;新 provider 照表加。
- schema 仍按所发布 codex 版本生成校验(见 backend-app-server-integration.md)。

## 8. 工作量(粗估)
- vendor 翻译内核 + 写 axum/reqwest 壳:~1 天(翻译逻辑"免费",主要是壳 + provider 配置 + 打包)。
- Swift 集成(sidecar 起停/状态 + Codex config 生成):~1-2 天。
- UI(向导 + 模型与提供方 + 两级选择器 + 状态/用量):~2-3 天。
