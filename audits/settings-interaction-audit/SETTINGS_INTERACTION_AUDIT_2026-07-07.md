# RaytoneCodex 设置页交互审计

日期：2026-07-07  
范围：RaytoneCodex macOS app 的设置全窗口页，以及设置页下 19 个子页面的按钮、菜单、开关、空态和运行时入口。  
目标：找出点击无反应、语义不成立、依赖官方 OpenAI 云服务但 Raytone 多模型版没有等价后端的功能，并给出替代或舍弃建议。

## 结论摘要

当前设置页不是简单“按钮没接上”的状态。大部分入口已经有 SwiftUI 路由、运行时方法和 smoke 覆盖，静态 wiring 检查也通过；真正的问题集中在两类：

1. **OpenAI 官方云服务依赖混在 Raytone 多模型产品里**：账户、登录、用量、加额度提醒、反馈上传、ChatGPT app 目录、远程控制云端模式、实时语音目录等功能都依赖官方 Codex app-server / OpenAI 后端。如果 Raytone 不提供自己的云服务，应默认隐藏或移到“OpenAI 专属”区域。
2. **部分按钮语义不准确**：例如 Profile 页的 `私有` 没有真正的 privacy 写接口，`Share` 实际只是复制摘要到剪贴板；这类按钮会让用户误以为完成了云端隐私或分享操作。

另外有一个真实运行问题：

- `--provider-sidecar-smoke` 没有输出最终 JSON，我手动中断。sidecar / app-server 长链路缺少可靠超时和清理，应该作为多 Provider 继续打磨的 P1。

## 已验证证据

### 构建

- `swift build` 通过。
- 日志：`audits/settings-interaction-audit/swift-build.log`

### 设置页 wiring

- `script/check_ui_runtime_wiring.sh` 通过。
- 结果：`audits/settings-interaction-audit/ui_runtime_wiring.json`
- 关键结果：
  - `settingsPanes`: 19
  - `settingsRuntimeSpecs`: 19
  - `clientRuntimeMethods`: 113
  - `failures`: []

### 设置 smoke

- 汇总：`audits/settings-interaction-audit/smoke/summary.tsv`
- 结果：42 PASS，1 TIMEOUT_MANUAL_INTERRUPTED。
- 唯一中断项：`--provider-sidecar-smoke`

### 真实 UI 点击

使用当前运行的 `dist/RaytoneCodex.app` 做了真实点击，不只看源码：

- 设置入口：从主窗口进入设置页成功。
- 搜索框：输入 `模型` / `个人` / `连接` 能筛选左侧设置导航。
- `模型与提供方`：点击 DeepSeek 行，详情切换；点击 `测试连接` 后显示缺少 Key / sidecar 未启动的错误。
  - 截图：`screenshots/raytonecodex-settings-audit-models.png`
- `个人资料`：点击 `Share` 后显示“已复制分享摘要”；点击 `私有` 后显示“app-server 未提供 profile/privacy 写接口”。
- `个人资料 -> 编辑`：会跳转到 `个性化` 页面。
- `连接`：进入页面后能看到 `remoteControl/status/read` 结果、`启用云端模式`、`生成配对码`、`停用` 等官方远程控制入口。
  - 截图：`screenshots/raytonecodex-settings-audit-connections.png`

我没有直接点击会产生外部副作用的按钮：上传反馈、发送额度提醒邮件、启用云端模式、生成远程配对码、停用远程控制、撤销客户端、重置记忆。这些通过 smoke / 源码确认了调用路径，真实产品里应加确认或隐藏。

## 源码依据

设置页子页面列表来自 `Sources/RaytoneCodex/Models/AppRoutes.swift:73`，共 19 个：

- 常规
- 模型与提供方
- 个人资料
- 外观
- 配置
- 实验功能
- 个性化
- 键盘快捷键
- 使用情况和计费
- 应用快照
- MCP 服务器
- 浏览器
- 电脑操控
- 钩子
- 连接
- Git
- 环境
- 工作树
- 已归档对话

关键云服务依赖在 `Sources/RaytoneCodex/Stores/SessionStore.swift`：

- `account/read` / `account/usage/read` / `account/rateLimits/read`：4198-4247
- Profile `私有` 只读账户，不写 privacy：4249-4268
- Profile `Share` 复制摘要到剪贴板：4270-4307
- `account/sendAddCreditsNudgeEmail`：4332-4351
- ChatGPT / 设备码 / API Key 登录：4353-4431
- `remoteControl/*`：5777-5945
- `feedback/upload`：7198-7240
- Provider sidecar 保存、Keychain、测试连接、401 处理：7333-7815

## 问题清单

### P1 - provider-sidecar smoke 卡住

现象：

- `--provider-sidecar-smoke` 构建通过，但没有最终 JSON 输出。
- 手动中断后只留下 release build / codesign 日志。
- 临时 mock upstream 已清理，没有发现残留 `RaytoneCodexMockModels` 进程。

影响：

- 多 Provider 是 Raytone 的核心能力；这个 smoke 本来应该证明 sidecar + Codex app-server + mock upstream 能完整跑通。
- 缺少超时会让测试、打包和 CI 都可能挂住。

建议：

- 给 provider-sidecar smoke 加总超时和分段超时：启动 sidecar、health check、写 `CODEX_HOME/config.toml`、启动 app-server、发 prompt、等待最终事件。
- 失败时打印最后一个 JSON-RPC id、sidecar 端口、健康检查结果、mock upstream request log。
- 确保退出时 kill mock upstream / sidecar / app-server 子进程。

### P1 - OpenAI 账户页不应作为 Raytone 通用账户页

现象：

- Profile 页顶部是 `登录 Codex`、`设备码`、`API Key`、`刷新账户`。
- 未登录时主状态是“需要登录 OpenAI”。
- smoke 证据显示登录 host 是 `auth.openai.com`。

影响：

- Raytone 多模型版用户如果选择 DeepSeek / GLM / Kimi / MiniMax / 本地 vLLM，会被错误引导到 OpenAI 登录。

建议：

- 把当前页改成 `OpenAI 账户`，只在 provider 为 OpenAI 时显示。
- 新增 Raytone 通用账户页：显示本地 provider、Keychain 状态、sidecar 状态、选中模型、provider 用量。
- 没有 Raytone 云账户前，不要承诺 profile、隐私、组织、计费等云功能。

### P1 - 远程控制云端模式依赖官方 remoteControl 后端

现象：

- 连接页明确调用 `remoteControl/status/read`。
- smoke 证据覆盖了 `remoteControl/enable`、`remoteControl/pairing/start`、`remoteControl/pairing/status`、`remoteControl/client/list`、`remoteControl/disable`。

影响：

- 这不是本地功能。没有 Raytone 自建 relay / pairing 服务时，按钮对用户没有稳定意义。

建议：

- 默认隐藏 `启用云端模式`、`生成配对码`、授权客户端列表、撤销客户端。
- 如果未来要做，替代方案是 Raytone Cloud Relay：设备注册、配对码、客户端 revoke、审计日志、加密通道、失效策略。
- 在 Raytone Cloud 未上线前，保留“本地模式”即可。

### P1 - 反馈上传会调用官方 feedback/upload

现象：

- 配置页 feedback sheet 文案写着调用 `feedback/upload`。
- smoke 证据显示请求带 `raytone_client=macos`、`raytone_surface=settings`，并可能附带日志、doctor report、当前线程 rollout。

影响：

- 对 Raytone 来说，这可能把日志交给非 Raytone 的上游 Codex 服务。

建议：

- 替换成 Raytone feedback endpoint。
- 没有后端前改成“导出诊断包”，只生成本地 zip / JSON。
- 上传日志必须有二次确认，并列出将包含哪些文件和字段。

### P2 - `私有` 按钮语义不成立

现象：

- 真实点击后返回：“个人资料保持私有；app-server 未提供 profile/privacy 写接口，已通过 account/read 刷新账户状态”。

影响：

- 用户会以为点击后更改了隐私状态，但实际只是读账户。

建议：

- 改名为 `刷新状态`，或直接删除。
- 如果未来 Raytone 有 profile privacy API，再恢复为真正开关。

### P2 - `Share` 实际是复制摘要

现象：

- 真实点击后状态为“已复制分享摘要”。
- 源码写入 `NSPasteboard.general`，没有打开系统分享面板。

影响：

- 用户会误解为分享给别人或生成公开链接。

建议：

- 改名 `复制摘要`。
- 内容里应加入 provider / sidecar 状态，减少 OpenAI account 字段权重。

### P2 - 使用情况和计费混合了 OpenAI Billing 与 Provider Usage

现象：

- `account/usage/read`、`account/rateLimits/read`、`account/sendAddCreditsNudgeEmail` 都是官方账户能力。
- sidecar provider usage 已有独立读取路径。

影响：

- 第三方 provider 的用量和 OpenAI 账户用量混在一个页面，用户不知道哪个账单会被扣费。

建议：

- 拆成两块：`Provider 用量` 和 `OpenAI 账户用量`。
- 加额度提醒邮件只在 OpenAI provider + OpenAI 登录后显示。
- 第三方 provider 只显示 Raytone sidecar 能采集到的 token / response 统计；无法获取官方账单时明确写“供应商账单请到对应平台查看”。

### P2 - ChatGPT app 目录不适合作为 Raytone 默认集成

现象：

- `app/list` 返回 2040 个 app，安装链接是 `https://chatgpt.com/apps/...`。

影响：

- 这属于 ChatGPT app ecosystem，不是 Raytone 本地多模型客户端的基础能力。

建议：

- 默认隐藏 ChatGPT app 安装入口。
- 替代为 Raytone 插件/MCP 目录；或者只保留 MCP 服务器、本地文件、浏览器、终端这些 provider-neutral 功能。

### P2 - 实时语音目录依赖 Codex realtime voice catalog

现象：

- smoke 证据显示 `thread/realtime/listVoices`，默认 voice 为 `marin`。

影响：

- 第三方模型未必支持 OpenAI realtime voices。

建议：

- 麦克风输入先做 provider-neutral：macOS Dictation / Speech framework / Whisper / 本地 ASR -> 文本输入。
- voice catalog 仅在 OpenAI realtime 可用时显示。

### P2 - modelProvider/capabilities 不能直接代表第三方 Provider 能力

现象：

- smoke 返回“命名空间工具 开、图像生成 开、网页搜索 关”。

影响：

- 这是 Codex app-server 看到的模型 provider capability，不一定是 DeepSeek / GLM / Kimi / MiniMax 的真实能力。

建议：

- 建立 Raytone `ProviderCapability`，从 sidecar provider 配置或真实探测得到：streaming、reasoning、tools、image、web、json schema、max tokens。
- UI 上显示“Raytone 探测结果”与“Codex 默认能力”区别。

### P2 - Windows Sandbox 不应在 macOS 默认露出

现象：

- smoke 能跑 `windowsSandbox/readiness` 和 `windowsSandbox/setupStart`。
- macOS 产品中该功能本身不成立。

建议：

- macOS 下隐藏 Windows Sandbox 设置。
- 如果保留，用“仅 Windows 可用”空态，不显示可点击 setup。

### P3 - 设置搜索只筛选，不自动切换内容

现象：

- 搜索 `连接` 后左侧只剩连接项，但右侧仍停留在个性化页。
- 必须再点搜索结果才切换。

建议：

- 只有一个搜索结果时自动选中。
- 或在右侧显示“选择一个搜索结果”。

### P3 - 实验功能数量过多

现象：

- smoke 显示上游 Codex experimental feature 列表很多。

影响：

- 对 Raytone 用户来说噪音大，且容易把未验证的官方实验功能暴露成产品承诺。

建议：

- 移到 `高级 / 开发者`。
- 默认只显示 Raytone 已支持的 feature flag。

## 每个设置子页建议

| 子页 | 当前状态 | Raytone 建议 |
| --- | --- | --- |
| 常规 | 可保留；权限、沙盒、打开目标、语言、服务层级、终端位置都有 wiring | 保留；服务层级若是 OpenAI 专属，按 provider 隐藏 |
| 模型与提供方 | Raytone 核心；真实点击 DeepSeek 缺 Key 提示正常 | 保留并优先打磨；修 provider-sidecar smoke 超时 |
| 个人资料 | 强 OpenAI 账户依赖 | 改成 OpenAI 专属；新增 Raytone 本地账户/Provider 状态 |
| 外观 | provider-neutral | 保留 |
| 配置 | 大部分可保留；反馈上传需替换 | 保留 config / approval / sandbox；feedback 改本地导出或 Raytone 上传 |
| 实验功能 | 上游 Codex 实验项过多 | 移到高级，默认折叠 |
| 个性化 | 指令、提交/PR 文案可保留；realtime voice 有 OpenAI 依赖 | 保留文字配置；语音目录按 provider capability 显示 |
| 键盘快捷键 | provider-neutral | 保留 |
| 使用情况和计费 | OpenAI usage + provider usage 混合 | 拆成 Provider 用量和 OpenAI 账户用量 |
| 应用快照 | ChatGPT app 目录依赖官方生态 | 保留截图/快照；ChatGPT app 安装入口隐藏或改 Raytone 插件目录 |
| MCP 服务器 | provider-neutral | 保留 |
| 浏览器 | provider-neutral | 保留 |
| 电脑操控 | Chronicle / Windows sandbox 混杂 | Chronicle 按插件可用性显示；Windows sandbox 在 macOS 隐藏 |
| 钩子 | provider-neutral，但有信任/启用风险 | 保留；信任和启用动作要确认 |
| 连接 | remoteControl 云能力强依赖官方后端 | 没有 Raytone Relay 前隐藏云端模式和配对 |
| Git | provider-neutral | 保留 |
| 环境 | 本地环境可保留，远端环境需 Raytone 后端 | 保留本地；远端能力 feature-gate |
| 工作树 | provider-neutral | 保留 |
| 已归档对话 | 依赖 app-server thread storage | 若继续使用 Codex app-server，保留 |

## OpenAI 云依赖分级

### 建议替代

- `feedback/upload` -> Raytone feedback API 或本地诊断包导出。
- `remoteControl/*` -> Raytone Cloud Relay；未上线前隐藏。
- `app/list` ChatGPT app 目录 -> Raytone 插件/MCP 目录。
- `thread/realtime/listVoices` -> macOS Dictation / Speech / Whisper / 本地 ASR；OpenAI realtime 仅作为可选。

### OpenAI 专属可选

- ChatGPT 登录、设备码、OpenAI API Key 登录。
- OpenAI account usage / rate limits。
- OpenAI add credits nudge。
- OpenAI model catalog / capability。

这些可以留，但需要放在 `OpenAI Provider` 详情里，不应出现在 Raytone 通用设置第一页。

### 建议舍弃或默认隐藏

- Profile `私有` 假按钮：没有写接口时删除。
- Windows sandbox：macOS 默认隐藏。
- 未验证的 upstream experimental flags：默认隐藏。

## 立即修复建议

1. 增加 `FeatureAvailability` 或 `CloudDependency` 层，按 selected provider 和 Raytone backend availability 控制设置项显示。
2. 修 `--provider-sidecar-smoke`：加 timeout、进程清理、最后请求日志、最后 JSON-RPC id。
3. 改文案：
   - `Share` -> `复制摘要`
   - `私有` -> `刷新状态` 或删除
   - `使用情况和计费` -> 拆成 `Provider 用量` / `OpenAI 账户`
4. 对高风险动作加确认：
   - 上传反馈含日志
   - 发送额度提醒邮件
   - 启用/停用云端模式
   - 生成配对码
   - 撤销客户端
   - 重置记忆
   - 信任/启用 hook
5. 把 OpenAI 专属能力移入 provider-specific 区域，Raytone 默认体验只露出本地多模型闭环：provider key、sidecar、model、approval/sandbox、browser、terminal、MCP、Git、worktree、archive。

## 明天可直接决策的产品取舍

如果短期没有 Raytone 云服务：

- 保留：模型与提供方、配置、个性化文本、键盘、MCP、浏览器、Git、环境本地模式、工作树、归档。
- 替换：反馈上传、应用目录、语音输入、用量页。
- 隐藏：OpenAI Profile 通用入口、远程控制云端模式、加额度提醒、Windows sandbox、上游实验功能。

如果计划做 Raytone 云服务：

- 先做一个薄切片：Raytone 登录 + provider usage + feedback upload + remote relay status。
- 只有这条链路有真实后端输出后，再恢复云端模式、配对码、客户端管理和计费页。
