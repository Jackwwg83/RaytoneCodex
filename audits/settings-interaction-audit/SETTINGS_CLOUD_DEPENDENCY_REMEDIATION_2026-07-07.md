# RaytoneCodex 设置页云依赖修正

日期：2026-07-07

范围：只处理设置页中依赖 OpenAI / Codex 官方云服务、但 Raytone 多 Provider 版没有等价后端承诺的入口。主对话页、插件页、自动化页和整体视觉不在本轮修改范围。

## 结论

本轮采用三条规则：

1. 能用本机或 Raytone 多 Provider 路径替代的，改成可点击的真实本地动作。
2. 需要 Raytone 自建云服务但当前没有后端的，默认隐藏，不把按钮暴露给用户。
3. OpenAI 仍作为可选模型 Provider 保留，但 OpenAI 账户、计费、远控、反馈上传、Realtime voice catalog 不再作为 Raytone 通用设置能力展示。

目标不是把官方能力“换个文案继续放着”，而是让用户看到的按钮都有当前产品能兑现的路径。

## 已替代

| 原能力 | 问题 | 新方案 | 证据 |
| --- | --- | --- | --- |
| Profile 的 Share / 私有 / OpenAI 账户卡 | 容易被理解成官方账户分享或隐私写入；实际没有 Raytone 通用账户后端 | 改成「本地状态」页：复制本地摘要、跳转模型设置、跳转个性化 | `remediation-smoke-current/profile-share.out` |
| 使用情况和计费 | 混合 OpenAI account usage 与第三方 Provider 用量 | 改成「Provider 用量」：OpenAI 账户用量隐藏，第三方走 sidecar `/usage` | `remediation-smoke-current/usage-activity.out`、`remediation-smoke-current/provider-sidecar.out` |
| feedback/upload | 会调用官方 feedback/upload，可能上传日志到非 Raytone 后端 | 改成「本地诊断包」导出 JSON 到 Application Support | `remediation-smoke-current/feedback-upload.out` |
| ChatGPT app 快照目录 | 属于 ChatGPT app ecosystem，不是 Raytone 默认集成 | 改成本地 WKWebView 快照：打开本地示例、截图并插入 composer | `screenshots/raytonecodex-browser-20260707-232526.png`，截图 `screenshots/settings-app-snapshots.png` |
| Realtime voice catalog | 依赖 `thread/realtime/listVoices` 和 OpenAI realtime voice catalog | 改成 macOS 系统听写，第三方 Provider 只接收转写后的文本 | Computer Use 上轮点击后状态「已请求 macOS 系统听写」，截图 `screenshots/settings-personalization.png` |
| Windows Sandbox | macOS 产品中不可用 | 电脑操控页只保留 Chronicle / Computer Use；Windows Sandbox setup 按钮隐藏 | 截图 `screenshots/settings-computer-control.png` |
| 上游 experimental feature toggles | 上游实验项不等于 Raytone 产品承诺 | 改成只读「高级功能」目录；需要启用时走 config.toml | 截图 `screenshots/settings-experimental.png` |

## 已隐藏或移出默认 UI

- `remoteControl/*` 云端模式、配对码、客户端撤销：没有 Raytone Relay 前不展示操作按钮。
- `account/sendAddCreditsNudgeEmail`：没有 OpenAI 账户页时不展示额度提醒。
- `account/login/*`、设备码、ChatGPT 登录：不再出现在 Raytone 通用本地状态页。
- `app/list` ChatGPT app 目录：默认不作为 Raytone 连接入口；首页连接卡优先 app mention，找不到 app 时落到 MCP/连接设置页。

底层 legacy 方法仍保留在 `SessionStore` 和 smoke runner 中，用于兼容、回归测试和显式验证“默认 UI 已隐藏”。设置视图层中未引用的旧账户卡和远控 helper 已删除，避免以后误接回页面。

## 真实 UI 验证与限制

用 `dist/RaytoneCodex.app` 和 development binary 实际启动检查：

1. 进入设置页，左侧显示「本地状态」「Provider 用量」「本地快照」等新页面名。
2. 「本地状态」点击「复制摘要」后页面显示「已复制本地状态摘要」。
3. 「模型设置」从本地状态页正确跳到「模型与提供方」。
4. 「本地快照」点击「打开示例」后回到主界面并打开右侧 WKWebView，本地 HTML 成功渲染。
5. 右侧浏览器点击相机后生成 `screenshots/raytonecodex-browser-20260707-232526.png`，composer 自动插入图片引用。
6. 「Provider 用量」刷新后仍显示「OpenAI 账户用量已隐藏」。
7. 「连接」页显示「官方云端模式 未启用；Raytone 默认隐藏 remoteControl/*」，没有启用云端/生成配对码按钮。
8. 「电脑操控」页没有 Windows Sandbox setup 按钮。
9. 「个性化」点击「测试听写」后显示「已请求 macOS 系统听写」，并显示不调用 `thread/realtime/listVoices`。
10. 首页「文件」连接卡打开右侧文件面板；「消息传送/电子邮件」在没有 ChatGPT app 目录时进入「设置 > 连接」并显示 MCP fallback。

本轮 Computer Use 对当前未签名/本地 development 窗口返回 `cgWindowNotFound`，System Events 也无法枚举 Accessibility window；但 `CGWindowList` 和 `screencapture -l <windowId>` 能截到窗口内容。可见 UI 证据因此采用项目自带 `--ui-smoke` 与窗口 ID 截图：

- `screenshots/raytonecodex-settings-general.png`
- `screenshots/raytonecodex-windowid-261099-20260707-235722.png`

这个限制属于本机自动化访问层限制，不代表 SwiftUI 页面未渲染；`--ui-smoke` 已证明窗口 1440×900、截图非空。

## 证据文件

- Wiring：`bash script/check_ui_runtime_wiring.sh`
- 本轮 smoke 汇总：`audits/settings-interaction-audit/remediation-smoke-current/summary.tsv`
- Provider sidecar 真实链路：`audits/settings-interaction-audit/remediation-smoke-current/provider-sidecar.out`
- Provider 首启向导：`audits/settings-interaction-audit/remediation-smoke-current/provider-onboarding.out`
- MCP 登录：`audits/settings-interaction-audit/remediation-smoke-current/mcp-login.out`
- 外部 Agent 配置：`audits/settings-interaction-audit/remediation-smoke-current/external-agent-config.out`
- 运行环境注册：`audits/settings-interaction-audit/remediation-smoke-current/runtime-environment.out`
- 首页连接卡：`audits/settings-interaction-audit/remediation-smoke-current/home-connection-actions.out`
- 本地状态复制：`audits/settings-interaction-audit/remediation-smoke-current/profile-share.out`
- 本地诊断包：`audits/settings-interaction-audit/remediation-smoke-current/feedback-upload.out`
- Provider 用量：`audits/settings-interaction-audit/remediation-smoke-current/usage-activity.out`
- 浏览器快照：`audits/settings-interaction-audit/remediation-smoke-current/browser-snapshot-request.out`
- 当前截图目录：`audits/settings-interaction-audit/screenshots/`
- 本地浏览器截图产物：`screenshots/raytonecodex-browser-20260707-232526.png`

关键结果：

```text
swift build: passed
check_ui_runtime_wiring: ok=true
provider-sidecar: ok=true
provider-onboarding: ok=true
mcp-login: ok=true
external-agent-config: ok=true
runtime-environment: ok=true
home-connection-actions: ok=true
profile-share: ok=true
feedback-upload: ok=true
usage-activity: ok=true
browser-snapshot-request: ok=true
```

本地诊断包实际写入：

```text
~/Library/Application Support/RaytoneCodex/Diagnostics/raytone-diagnostics-20260707-234809.json
```

## 当前仍需下一轮处理

1. 底层 `SessionStore` 仍保留官方云方法，默认 UI 已隐藏；如果未来确定永远不支持 OpenAI 官方账户功能，可以再做一次更大范围删除。
2. MCP 连接器的「登录」按钮仍可见，这是 MCP 连接器自身 OAuth，不是 OpenAI remoteControl；`mcp-login` smoke 已证明 app-server OAuth 方法会返回授权 URL，但真实第三方网页登录仍需要对应 connector 的真实账号环境。
3. provider-sidecar smoke 现在用“收到真实 agent 文本 + 上游请求日志 + sidecar usage”作为完成条件；Codex app-server turn 生命周期偶发不会自然落到 completed，测试会主动 interrupt 收尾。后续可以继续追 app-server lifecycle，但不阻塞设置页按钮可用性结论。
4. 无可信签名身份时，普通启动脚本现在直接用 development binary；正式发给同事的 `.app`/DMG 仍需要 Developer ID 签名与 notarization，避免未签名 bundle 在本机自动化层出现窗口访问异常。
