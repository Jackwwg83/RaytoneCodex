# RaytoneCodex 后端：基于 Codex 源码的 app-server 集成方案

日期：2026-06-09
来源：OpenAI「Codex App Server」官方协议文档 https://developers.openai.com/codex/app-server ，开源 `openai/codex` 的 `codex-rs/app-server`。

## 0. 结论先行
- **不必为了"能用"去改 Codex 源码**。Codex 桌面端的真实后端就是 `codex app-server`（JSON-RPC over stdio）。我们要做的 90% 是写一个 **Swift app-server 客户端**，把现在的一次性 `codex exec` 换成长连接、流式。
- **从源码构建**：`git clone openai/codex` → 固定 commit → `cargo build --release` 出 `codex` 二进制 → 放进 `RaytoneCodex.app/Contents/Resources/codex`（沿用现有打包脚本）。这样满足"基于 cli 源代码"。
- **要"改"才 fork**：分支化定制（品牌/默认配置/模型列表/自定义工具/遥测/新增 app-server 方法）。见 §6 补丁点。
- 许可：openai/codex 是 Apache-2.0。bundle 里必须带 `LICENSE` 和 `NOTICE`（脚本已有 `third_party/openai-codex/` 占位）。修改要保留版权声明，建议在 NOTICE 注明"含基于 openai/codex 的修改"。

## 1. 运行架构
```
RaytoneCodex (SwiftUI)
   └─ RaytoneCodexCore.CodexAppServerClient
        └─ spawn: <bundled>/codex app-server        (stdio, JSONL)
             ├─ 出: initialize / thread/start / turn/start / turn/interrupt / model/list / *requestApproval 的 result
             └─ 入: thread/* turn/* item/* 通知 + 服务端发起的 *requestApproval 请求
```
- 每个"线程"= 一个 `thread/start` 得到的 thread；UI 的 `ChatThread` 持有其 `threadId`、`sessionId`。
- 保留 `codex exec` 作为**降级路径**（无法连 app-server 时）。用一个开关/能力探测决定走哪条。

## 2. 协议参考（stdio，实现要点，标识符照抄勿改写）
**传输**：JSON-RPC 2.0 但**不写 `"jsonrpc"` 字段**；**按行分隔的 JSON（JSONL）**，每条消息一行 `\n` 结尾。启动：`codex app-server`（默认 `--listen stdio://`）。
- 请求：`{ "method":…, "id":…, "params":{…} }`
- 响应：`{ "id":…, "result":{…} }` 或 `{ "id":…, "error":{ "code":…, "message":… } }`
- 通知：`{ "method":…, "params":{…} }`（无 id）
- 路由：入站消息**有 `id` 且有 `method`** = 服务端发起的请求（要回 result）；**有 `id` 无 `method`** = 对我们请求的响应；**无 `id`** = 通知。

**握手**（每连接一次，且在任何其它方法之前）：
1. 请求 `initialize`，params：`clientInfo:{ name, title, version }`（name 用于合规日志，如 `"RaytoneCodex"`）、可选 `capabilities:{ experimentalApi: Bool, optOutNotificationMethods:[String] }`。
2. 通知 `initialized`，params `{}`。

**建线程**：请求 `thread/start`，params：`model`、`cwd`、`approvalPolicy`、`sandbox`/`sandboxPolicy`、`personality`、可选 `serviceName`。返回 `{ thread:{ id, sessionId, preview, modelProvider, createdAt } }` 并自动订阅该线程事件。续接用 `thread/resume{ threadId }`，分叉 `thread/fork{ threadId }`。
- 取 `thread.sessionId` 直接用，别从 id 推。

**发起一轮**：请求 `turn/start`，params：`threadId`、`input`（数组，文本用 `{ type:"text", text }`，本地图片 `{ type:"localImage", path }`，技能 `{ type:"skill", name, path }`）+ 可选 per-turn 覆盖：`cwd, approvalPolicy, sandboxPolicy, model, effort, summary, personality, outputSchema`。返回 `{ turn:{ id, status:"inProgress", items:[], error:null } }`。
- 追加输入到同一轮：`turn/steer{ threadId, input, expectedTurnId }`。
- 取消：`turn/interrupt{ threadId, turnId }` → 该轮以 `status:"interrupted"` 结束。

**模型列表**：请求 `model/list{ limit, includeHidden }` → `{ data:[{ id, model, displayName, defaultReasoningEffort, supportedReasoningEfforts, isDefault, inputModalities }], nextCursor }`。喂给 composer 的模型下拉。

**通知（持续读 stdout）**：
- 线程：`thread/started{ thread:{id} }`、`thread/status/changed{ threadId, status:{type} }`（type ∈ notLoaded|idle|systemError|active，active 带 `activeFlags`，如 `["waitingOnApproval"]`）、`thread/closed`。
- 轮：`turn/started{ turn }`、`turn/completed{ turn }`（status ∈ completed|interrupted|failed；failed 带 `error:{ message, codexErrorInfo? }`）、`turn/diff/updated{ threadId, turnId, diff }`（整轮聚合 unified diff）、`turn/plan/updated{ turnId, explanation?, plan:[{ step, status }] }`（status ∈ pending|inProgress|completed）、`thread/tokenUsage/updated`。
- Item 流式：`item/started{ item }`（开始，`item.id` 即后续 delta 的 itemId）、`item/completed{ item }`（最终权威）、增量：`item/agentMessage/delta`、`item/reasoning/summaryTextDelta`(+`summaryIndex`)、`item/reasoning/textDelta`、`item/commandExecution/outputDelta`（stdout/stderr，按序追加）。`item/fileChange/outputDelta` 已废弃——改用 `fileChange` item + `turn/diff/updated`。
- `serverRequest/resolved{ threadId, requestId }`：确认某个服务端请求已被回答/清除。

**Item 类型（`type` 标签联合，关键字段）**：
- `userMessage{ id, content }`
- `agentMessage{ id, text, phase? }`（phase ∈ commentary|final_answer）
- `reasoning{ id, summary, content }`
- `commandExecution{ id, command, cwd, status, aggregatedOutput?, exitCode?, durationMs? }`
- `fileChange{ id, changes:[{ path, kind, diff }], status }`
- `mcpToolCall` / `dynamicToolCall` / `webSearch{ query, action }` / `imageView` / `enteredReviewMode` / `exitedReviewMode` / `contextCompaction`
- 错误：失败轮发 `error` 事件 `{ error:{ message, codexErrorInfo?, additionalDetails? } }`，随后 `turn/completed status:"failed"`。`codexErrorInfo` ∈ ContextWindowExceeded|UsageLimitExceeded|Unauthorized|HttpConnectionFailed|SandboxError|… （`Unauthorized` = 未登录/无权限）。

**审批（服务端发起请求，客户端用 JSON-RPC `result` 回决定）**：
- 命令执行：请求 `item/commandExecution/requestApproval`，params `{ itemId, threadId, turnId, reason?, command?, cwd?, commandActions?, networkApprovalContext?, availableDecisions? }`。
  - 决定值（照抄）：`"accept"` | `"acceptForSession"` | `"decline"` | `"cancel"` | `{ "acceptWithExecpolicyAmendment": { "execpolicy_amendment": ["cmd","…"] } }`。
  - 若带 `networkApprovalContext`（含 `host`/`protocol`）→ 渲染"网络访问"提示，别把 command 当 shell 预览。
- 文件改动：请求 `item/fileChange/requestApproval`，params `{ itemId, threadId, turnId, reason?, grantRoot? }`。决定值：`"accept"|"acceptForSession"|"decline"|"cancel"`。
- 顺序：`item/started`(pending) → `…/requestApproval` → 我方回 result → `serverRequest/resolved` → `item/completed`(status completed|failed|declined)。
- 工具/连接器副作用用 `tool/requestUserInput`（Accept/Decline/Cancel）。

**鉴权**：协议**没有**显式 login 方法；app-server 复用宿主机 `codex login`（ChatGPT 或 API key）的凭据。未登录表现为某轮失败 `codexErrorInfo:"Unauthorized"`。→ 我们据此切 `ConnectionState.loginRequired`。

**版本/实验**：schema **按 Codex 版本绑定**，用 `codex app-server generate-json-schema --out ./schemas` 和 `codex app-server generate-json-schema --experimental --out ./schemas/experimental`（或 `generate-ts`）对**所发布的同一 codex 二进制**生成并校验类型。实验方法需 `initialize` 时 `capabilities.experimentalApi:true`。

## 3. Swift 客户端设计（放 RaytoneCodexCore）
新增 `CodexAppServerClient`（actor / @unchecked Sendable）：
- 用 `Process` 起 `codex app-server`，`cwd` 设工作区；`stdin`/`stdout` 用 `Pipe`，`stderr` 透传日志。
- 出站：`encode(JSON)+"\n"` 写 stdin；维护 `id → continuation` 表做请求/响应配对（async/await）。
- 入站：后台读 stdout，**按行**切，逐行 JSON 解析，路由：响应→唤醒 continuation；通知→投递到 `AsyncStream<ServerEvent>`；服务端请求(`*requestApproval`/`tool/requestUserInput`)→投递到事件流并记下 `id`，等 UI 决定后回 `result`。
- 公开 API（async）：`initialize()`, `startThread(opts) -> Thread`, `startTurn(threadId,input,overrides) -> Turn`, `steer(...)`, `interrupt(...)`, `respondApproval(requestId, decision)`, `listModels()`, 以及 `events: AsyncStream<ServerEvent>`。
- 类型：优先用 `codex app-server generate-json-schema` 生成的 schema 反推 Codable 结构；先按 §2 手写最小可用子集，字段用 `Decodable` 容错（未知字段忽略）。

### 协议 → 现有 UI 模型映射
| app-server item / 事件 | 现有类型 |
|---|---|
| `agentMessage`(+delta) | `.agentMessage(text)`（commentary 可弱化，final_answer 为主） |
| `reasoning`(+delta) | `.reasoning(ReasoningBlock{ title:"已思考 N 秒"或"思考", detail:summary/content })` |
| `commandExecution`(+outputDelta) | `.command(CommandRun{ command, directory:cwd, output:aggregatedOutput, exitCode, status: inProgress→running / completed→succeeded / failed,declined→failed })` |
| `fileChange.changes[]` | 每个 change → `.fileChange(FileChange{ path, type: add/modify/delete/rename, additions/deletions+hunks 解析自 diff })` |
| `turn/diff/updated` | 环境信息「变更」计数 + diff 全屏数据源 |
| `turn/plan/updated` | 环境信息「进度」`ProgressStep[]`（pending/inProgress/completed → 空心圈/spinner/✓） |
| `item/commandExecution/requestApproval` | `.approval(ApprovalRequest{ kind:.command, command, rationale:reason, commandPrefix })` → 决定 approved→accept / approvedAlways→acceptForSession / denied→decline |
| `item/fileChange/requestApproval` | `.approval(kind:.patch)` → 同上决定值 |
| `turn/completed failed + Unauthorized` | `ConnectionState.loginRequired` |
| spawn 失败 / 找不到二进制 | `ConnectionState.notInstalled` |
| `thread/tokenUsage/updated` | 「进行中的目标」用量/计时辅助 |
| `model/list` | composer 模型下拉 |

### AccessMode → thread/turn 参数
- 请求批准 `ask` → `approvalPolicy:"on-request"`（或 untrusted）+ `sandbox:"workspace-write"`
- 替我审批 `autoReview` → `approvalPolicy:"on-failure"` + `sandbox:"workspace-write"`
- 完全访问 `full` → `approvalPolicy:"never"` + `sandbox:"danger-full-access"`
（确切枚举字符串以 `codex` 源/`config` 为准；Codex 实现时核对。）

## 4. Store 接线
- `SessionStore.runPrompt()`：改为——确保有 client、有 thread（无则 `thread/start`）→ `turn/start` 用 prompt → 订阅 `events` 流，在 `@MainActor` 上把 item/delta 增量映射进 `selectedThread.items`（item.id 去重/更新，复用现有 .command/.fileChange/.agentMessage 行）。
- `isRunning` ← turn 生命周期（started→true，completed→false）。
- 审批：UI 的内联审批卡（§8c）选项 → `respondApproval(requestId, decision)`；`serverRequest/resolved` 后清 pending。
- 连接态：client 启动/initialize 成功→`.connected(version)`；Unauthorized→`.loginRequired`；spawn 失败→`.notInstalled`；断开→`.disconnected`。`refreshRuntime()` 改为探测 app-server（仍可 `--version`）。
- `turn/interrupt`：composer 的"停止"按钮 + 菜单「对话→停止」。

## 5. 从源码构建 + 打包
- `script/`：加一个 `build_codex_from_source.sh`：`git clone --depth 1 --branch <PINNED_TAG_OR_COMMIT> https://github.com/openai/codex third_party/openai-codex`（或 submodule）→ 进 `codex-rs` → `cargo build --release`（产物如 `target/release/codex`）→ 拷到 `dist/RaytoneCodexCLI/codex` 供打包。需要 Rust 工具链（rustup）。
- 固定版本：记下 commit/tag，和生成的 schema 一起 pin，保证协议匹配。
- `build_and_run.sh` 的 `find_codex_cli` 优先用"源码构建产物"，否则回退现有逻辑（/Applications/Codex.app、PATH、Homebrew）。
- bundle 带 `OPENAI_CODEX_LICENSE.txt`(Apache-2.0) + `OPENAI_CODEX_NOTICE.txt`，NOTICE 写明"基于 openai/codex@<commit> 构建/修改"。
- 用 `codex app-server generate-json-schema --out RaytoneCodex/Schemas` 生成稳定 schema，并用 `codex app-server generate-json-schema --experimental --out RaytoneCodex/Schemas/experimental` 生成实验 schema，一起提交；Swift 侧据此对类型。

## 6. 要"改"源码时的补丁点（fork，phase 2，非必须）
在 `third_party/openai-codex` 开分支 `raytone/main`，小步补丁、可 rebase 跟上游：
- `codex-rs/core`：默认 config（默认 model/approval/sandbox）、system prompt/品牌串、内置工具策略。
- `codex-rs/app-server` + `app-server-protocol`：新增/扩展方法或通知（如自定义"目标/进度"持久化、Raytone 专属事件）；改完重生成 schema。
- 模型列表/Provider：`model/list` 数据源、自定义 provider。
- MCP/工具：内置 MCP server 默认项、自定义 dynamicTools。
- 遥测/日志：接 Raytone 自己的埋点（注意隐私与许可）。
原则：能用配置/参数解决就不改源码；改就集中在分支、注释清楚、保留上游版权。

## 7. 风险与注意
- schema 随版本变 → 必须对**所发布的同一二进制**生成 schema 并校验；Swift 解码要容错。
- 审批决定值字符串**必须照抄**（accept/acceptForSession/decline/cancel）。
- 鉴权靠宿主 `codex login`；首启若 Unauthorized → 走登录引导（我们已有 loginRequired 横幅）。
- 实验方法要 `experimentalApi:true`，否则被拒。
- 沙箱/审批语义要和 UI 的 AccessMode 对齐，别给用户"完全访问"却仍被频繁询问。
