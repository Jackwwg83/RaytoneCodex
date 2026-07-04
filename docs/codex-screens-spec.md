# RaytoneCodex 子页面实现规格（对照本机 Codex 截图，1:1）

日期：2026-06-09
目标：把主对话页之外的所有子页面/菜单按本机 Codex.app 还原。全中文 chrome，浅/深跟随系统，复用现有 `Theme` tokens（surfaces/fill/border/text/accent、Radius、Layout）、`SessionStore`、侧栏与现有 composer 组件。

约定：
- 左侧栏（`SidebarView`）在所有路由下保持不变（新对话/搜索/插件/自动化 → 项目分组 → 设置）。
- 主区是一个"路由"：默认是对话页；点 插件/自动化/设置 切换到对应全宽页面;选中某对话切回对话页。
- 建议在 `SessionStore` 增加 `enum Route { case thread, plugins, automation, settings }` 与 `@Published var route: Route = .thread`；侧栏点击切 route，选中对话时 `route = .thread`。`ContentView` 按 `store.route` 切换中间区域（侧栏始终在）。设置不是独立的 macOS Settings 面板，而是占满主区的全窗口页（带"← 返回应用"）。

---

## 1. 新对话首屏（空线程 hero）

用途：线程 `items` 为空时的首屏（替换现有 `EmptyThreadView`）。
布局（主区，居中列，最大宽 ~720）：
- 顶部右上角与对话页一致：模型 chip（如 `5.5 超高 ⌄`）+ 窗口控制（展开、面板切换）。
- 垂直居中：
  1. 大标题（22–24pt，semibold，居中）：`我们应该在 {项目名} 中构建什么？`（如"我们应该在 RaytoneCodex 中构建什么？"）。
  2. **居中大输入框**（不是底部 composer，而是放中间）：圆角 18、白底、细边 + 轻阴影。
     - 占位：`随心输入`。
     - 底部控制行：左 `+`、`⚠ 完全访问 ⌄`（沙箱，full access 用 warning 橙）；右 `5.5 超高 ⌄`（模型）、麦克风、圆形发送键。
  3. 输入框**下方一行 pill 选择器**（居中、可点下拉）：`📁 RaytoneCodex ⌄`（项目/工作区）、`💻 本地模式 ⌄`（运行模式）、`⎇ master ⌄`（git 分支）。图标用 SF Symbols：folder / desktopcomputer / arrow.triangle.branch。
  4. 下方**连接卡片**（3 列等宽，间距 12）：
     - `连接消息传送` — 副标题`从近期团队讨论中获取背景信息`，右上角已连接显示绿色 ✓。
     - `连接电子邮件` — 副标题`总结电子邮件中利益相关方的请求`，图标 Gmail 风格（用占位多色或 envelope）。
     - `连接文件` — 副标题`审查结果、研究资料和计划`，图标 Drive 风格（用 folder/doc 占位）。
     - 卡片：白底、0.5 边、radius-lg、padding ~16；图标在左上，标题 13–14 semibold，副标题 11–12 secondary，两行。
交互：输入并发送后进入对话页（沿用 `runPrompt`）。pill 下拉先做 UI（项目下拉可切 `selectThread`/工作区；模式/分支先占位）。

---

## 2. 插件 / 技能（Plugins）

用途：`route == .plugins`。
布局（主区全宽，内容列最大宽 ~860 居中）：
- 顶部栏：左侧 tab `插件` | `技能`（选中加粗 + 底部下划线或填充）；右侧 `⚙ 管理`、`创建 ⌄`、`···`。
- 大标题（居中，22pt）：`让 Codex 按你的方式工作`。
- 搜索行：搜索框 `搜索插件`（带放大镜，flex 占宽）+ 右侧两个下拉 `Built by OpenAI ⌄`、`全部 ⌄`。
- **特色横幅**：一张大圆角卡（紫色渐变背景——深浅模式都要可读；可用 `Theme.fill` + 轻微 accent 叠加，避免硬编码），中间一张白色小卡 `🧩 Computer Use 播放一个播放列表，帮我进入专注状态 →`，下方黑色按钮 `在对话中试用`；右侧竖排 carousel 圆点（5 个，首个实心）。
- `Featured` 区（小写 section 标题，左对齐）：**2 列网格**插件行。每行：左 app 图标（圆角方），中 名称（13 semibold）+ 描述（11 secondary，单行省略），右 状态：已安装显示灰色 ✓、未安装显示 `＋` 圆钮。
  - 列表数据（名称 — 描述 — 状态）：
    - Computer Use — Control Mac apps from Codex — ✓
    - Chrome — Control Chrome with Codex — ✓
    - Spreadsheets — Create and edit spreadsheet files — ✓
    - Presentations — Create and edit presentations — ✓
    - GitHub — Triage PRs, issues, CI, and publish flows — ✓
    - Slack — Read and manage Slack — ✓
    - Data Analytics — Turn data into clear decisions — ✓
    - Product Design — Explore and prototype ideas — ✓
    - Creative Production — Create marketing visuals from a brief… — ✓
    - Sales — Prepare sales work faster — ＋
    - Investment Banking — M&A, capital markets, LevFin, valuatio… — ＋
    - Public Equity Investing — Public equity PM research, long/short,… — ＋
    - Notion — Notion workflows for specs, research,… — ＋
    - Linear — Find and reference issues and projects. — ✓
- 数据模型建议：`struct Plugin { id; name; subtitle; symbol; installed: Bool }`，`Plugin.featured: [Plugin]`（图标先用 SF Symbols 近似：Computer Use=sparkles/rectangle.on.rectangle、Chrome=globe、Spreadsheets=tablecells、Presentations=rectangle.on.rectangle.angled、GitHub=chevron.left.forwardslash.chevron.right、Slack=number.square、Data Analytics=chart.bar、Product Design=square.on.circle、Creative Production=paintpalette、Sales=cart、Investment Banking=building.columns、Public Equity=chart.line.uptrend.xyaxis、Notion=note.text、Linear=line.diagonal）。
- `技能` tab：先占位（同款 2 列网格或"敬请期待"空态）。

---

## 3. 自动化（Automation）

用途：`route == .automation`，空态。
布局（主区全宽，内容居中）：
- 顶部右上：`查看模板`（次按钮）、`通过聊天创建 ⌄`（主按钮，深色）。
- 左上标题区：`自动化`（22pt），副标题 `按计划或按需运行聊天。` + 链接 `了解更多`（蓝）。
- 垂直居中空态：
  - 线描图标（云朵里一个 `>_` 终端，约 80pt，可用 SF Symbol `terminal` 叠 `cloud` 或自绘；先用 `terminal` 圆角方块占位）。
  - 文案 `创建首个自动化`（15–16 medium）。
  - 一行 3 个胶囊按钮（带图标）：`🔔 每日简报`、`📅 每周回顾`、`🔍 项目监控`（bell / calendar / sparkle.magnifyingglass）。
交互：按钮先占位（点了 toast/no-op）。

---

## 4. 设置窗口（全窗口路由，`route == .settings`）

整体：占满主区右侧（左侧 app 侧栏仍在）。设置自己再分**左设置导航 + 右内容**两栏。
左设置导航（宽 ~230，浅灰）：
- 顶部：`← 返回应用`（点回 `.thread`）。
- 搜索框：`搜索设置...`。
- 分组（section 标题灰色小字）+ 项（图标 + 文字，选中高亮圆角）：
  - **个人**：常规(gearshape)、个人资料(person.circle)、外观(sun.max)、配置(slider.horizontal.3 或 circle.grid.2x2)、个性化(face.smiling)、键盘快捷键(keyboard)、使用情况和计费(chart.pie)
  - **集成**：应用快照(rectangle.dashed)、MCP 服务器(point.3.connected.trianglepath.dotted)、浏览器(macwindow)、电脑操控(cursorarrow.rays)
  - **编码**：钩子(link)、连接(globe)、Git(arrow.triangle.branch)、环境(square.stack)、工作树(arrow.branch / rectangle.split.3x1)
  - **已归档**：已归档对话(archivebox)
右内容：可滚动，标题 + 若干"卡片分组"。控件统一：toggle、下拉 `值 ⌄`、分段 `A|B`、单选大卡、文本域。卡片：白底/0.5 边/radius-lg；多行设置时每行含 标题(13 medium) + 描述(11–12 secondary) + 右侧控件。

### 4a. 常规
- `工作模式`（section）+ 描述 `选择 Codex 显示多少技术细节`。两张**大单选卡**并排：
  - `适用于编程` / `更具技术性的回复和控制`（左侧 `>_` 图标，选中：accent 边 + 右上实心 radio）。
  - `适用于日常工作` / `同样强大，技术细节更少`（未选）。
- `权限`（section）卡，三行 toggle：
  - `默认权限`（on）— `默认情况下，Codex 可以读取并编辑其工作区中的文件。必要时，它可以请求额外的访问权限`。
  - `自动审核`（on）— `…会自动审核额外访问权限请求。自动审核可能会出错。了解更多有关高风险的信息。`（"了解更多"蓝链）。
  - `完全访问权限`（on）— `当 Codex 以完全访问权限运行时，无需你批准…这会显著增加数据丢失、泄露或意外行为的风险。了解更多…`。
- `常规`（section）卡，多行：
  - `默认打开目标` → 下拉 `iTerm2 ⌄`（描述 `默认打开文件和文件夹的位置`）。
  - `语言` → 下拉 `自动检测 ⌄`（描述 `应用 UI 语言`）。
  - `在菜单栏中显示`（toggle on）— `关闭主窗口后，仍在 macOS 菜单栏中保留 Codex`。
  - `底部面板`（toggle on）— `在应用标题栏中显示底部面板控件`。
  - `默认终端位置` → 分段 `底部 | 右侧`（描述 `选择终端快捷方式和环境操作在何处打开终端标签页`）。
  - `运行时防止系统休眠`（toggle on）— `在 Codex 运行对话时，让电脑保持唤醒状态`。
  - `速度` → 下拉 `标准 ⌄`。

### 4b. 个人资料
- 右上角：`⬆ Share`、`🔒 私有`、`✎ 编辑`。
- 居中：大头像圆（首字母 `HW`，橙底白字）、姓名 `Hongqian Wu`（20pt）、`@hqwu810 · Pro`（Pro 为小徽章）。
- **统计卡**（一行 5 格，等宽，数值大 + 标签小）：`135.8亿 / 累计 Token 数`、`10亿 / 峰值 Token 数`、`23 小时 49 分 / 最长任务时长`、`1 天 / 当前连续天数`、`39 天 / 最长连续天数`。
- `Token 活动`：右上 `每日 每周 累计` 切换；GitHub 风格贡献热力图（约 7 行 × 53 列小方块，蓝色深浅，用 `Theme.accent` 透明度分级），下方月份 `7月…6月`。
- 两列：
  - `Activity insights`：Fast Mode 2% / Most used reasoning 超高·47% / Skills explored 47 / Total skills used 1,012 / Total threads 3,652（左标签右值）。
  - `Most used plugins`：@superpowers 353 runs / @linear 184 / @slack 75 / @chrome 63 / @computer-use 47（图标 + 名 + 右侧 runs）。

### 4c. 配置
- 标题 `配置` + 副标题 `配置审批策略和沙盒设置 了解更多`。
- `自定义 config.toml 设置`：项目下拉 `RaytoneCodex ⌄` + 右侧链接 `打开 config.toml ↗`。
- 卡（两行下拉）：`批准策略`→`按需 ⌄`（描述 `选择 Codex 何时请求批准`）；`沙盒设置`→`只读 ⌄`（描述 `选择 Codex 的命令执行权限`）。← 这两项直接绑 `store.approval`/`store.sandbox`（中文用 ComposerView.sandboxName + 审批中文映射）。
- `工作空间依赖项` 卡：`当前版本` 右值 `26.601.10930`；`Codex 依赖项`(toggle on) — `允许 Codex 安装并提供随附的 Node.js 和 Python 工具`；`诊断 Codex 工作空间中的问题`（描述 `检查当前捆绑包并记录诊断日志`）右 `🔍 诊断` 按钮；`重置并安装工作空间`（描述 `删除本地捆绑包，重新下载后再重新加载工具`）右 `↓ 重新安装`（红色文字按钮）。

### 4d. 个性化
- 标题 `个性化`。
- `个性` → 下拉 `亲和 ⌄`（描述 `选择 Codex 回复的默认语气`）。
- `自定义指令`（描述 `为你的项目向 Codex 提供额外说明和上下文。了解更多`）：多行文本域（等宽体显示英文示例文本），右下 `保存` 按钮。
- `记忆（实验性）`（描述 `设置 Codex 如何收集、保留和整合记忆。了解更多`）卡：
  - `启用记忆`（on）— `从聊天中生成新记忆，并将其带入新聊天`。
  - `Chronicle 研究预览`（on）— `通过屏幕上下文增强记忆…了解更多`，下一行 `状态：运行中`（运行中为绿色）。
  - `跳过工具辅助对话`（off）— `请勿从使用了 MCP 工具或网页搜索的对话中生成记忆`。
  - `重置记忆`（描述 `删除所有 Codex 记忆`）右 `重置`（红色文字按钮）。

### 4e. 仍无截图的 pane（外观 / 使用情况和计费 / 应用快照 / 已归档对话）
- 统一占位页：标题 + 一句副标题 + 浅色"敬请完善"卡/空态。
- 例外：`外观` 顺手做实功能——分段或三张小卡 `浅色 | 深色 | 跟随系统`（绑 `@AppStorage` + `.preferredColorScheme`）+ 一行强调色色板，方便验收深色。

### 4f. 已截图 pane 的精确内容（务必 1:1）

**键盘快捷键**（settingsPane=.shortcuts）
- 标题 `键盘快捷键`；下方搜索框 `搜索快捷键`（右侧一个 keyboard 图标按钮）。
- 一张表，表头 `命令` | `按键绑定`；每行：左 命令中文名(13) + 英文副标题(11 secondary)；右 一个或多个按键 chip（灰底圆角等宽，如 `⇧⌘A`）+ 每个绑定右侧一个垃圾桶删除图标；行间 hairline。
- 行（命令 / 英文 / 绑定）：
  - 归档聊天 / Archive the current chat / `⇧⌘A`
  - 新对话 / Start a new chat / `⌘N`、`⇧⌘O`（两条）
  - 打开侧边聊天 / Open the current chat in a side chat / `未指定`
  - 在新窗口中打开 / Open the current chat in a new window / `未指定`
  - 新建快速对话 / Start a lightweight chat in the quick compo… / `⌥⌘N`
  - 切换置顶状态 / Pin or unpin the current chat / `⌥⌘P`
  - 查找 / Search the current chat / `⌘F`
  - 聚焦浏览器地址栏 / Focus the in-app browser address bar / `⌘L`
  - 返回 / Go back in navigation history / `⌘[`、`Mouse Back`
  - 前进 / Go forward in navigation history / `⌘]`、`Mouse Forward`
  - 下一个最近查看的聊天 / Cycle to the next recently viewed chat or t… / `⌃Tab`
  - 下一个聊天或标签页 / Switch to the next chat or tab / `⇧⌘]`、`⌥⌘Right`
  - 上一个最近查看的聊天 / Cycle to the previous recently viewed chat… / `⌃⇧Tab`
- `未指定` 为灰字、无 chip 无删除。

**MCP 服务器**（settingsPane=.mcp）
- 标题 `MCP 服务器` + 副标题 `连接外部工具和数据源。了解更多。`
- `服务器` section（右侧 `＋ 添加服务器` 次按钮）→ 卡：`node_repl`（右 齿轮图标 + toggle on）、`vibengine-sandbox`（齿轮 + toggle on）。
- `来自插件` section → 卡，纯列表行（无控件）：`cloudflare-api`、`codex_apps`、`computer-use`、`creative_production_mcp`、`datascienceWidgets`、`openai-api-key-local-confirmation`、`xcodebuildmcp`。

**浏览器**（settingsPane=.browser）
- 标题 `浏览器` + 副标题 `管理 Codex 的浏览器。可在 计算机使用设置 中设置 Google Chrome`（"计算机使用设置"蓝链）。
- 卡：`浏览器`(图标 macwindow.and.cursorarrow) `允许 Codex 控制内置浏览器` toggle on。
- `数据` section 卡：`浏览数据` / `清除应用内浏览器中的网站数据和缓存` → 下拉 `清除所有浏览数据`；`批注截图` / `截图可帮助 Codex 更好地理解并处理评论，但会增加套餐用量` → 下拉 `始终包含`。
- `权限` section 卡：`审批` / `选择是否让 Codex 在打开网站前先请求批准。了解更多` → 下拉 `始终询问`。
- `已屏蔽的域名` section（右 `＋ 添加`，副标题 `Codex 绝不会打开这些网站`）→ 空卡居中 `没有已屏蔽的域名`。
- `允许的域名` section（右 `＋ 添加`，副标题 `无需询问即可打开的域名`）→ 空卡居中 `没有允许的域名`。

**电脑操控**（settingsPane=.computerControl）
- 标题 `电脑操控` + 副标题 `管理 Codex 如何使用您电脑上的其他应用程序`。
- `控制` section 卡：`任意应用`(多彩图标) `允许 Codex 控制您电脑上的应用` toggle on；`Google Chrome`(Chrome 图标) `● 已连接到浏览器扩展程序，可进行更多控制`（● 绿点）右 `管理` 小按钮 + toggle on；`锁屏操作`(笔记本锁图标) `允许 Codex 在 Mac 锁定时使用此 Mac。了解更多` toggle on。
- `始终允许的应用` section 卡：`Google Chrome` 行 + 右垃圾桶。

**钩子**（settingsPane=.hooks）
- 标题 `钩子` + 副标题 `通过配置和已启用的插件管理生命周期钩子。了解更多` + 右上 刷新图标。
- 空卡：粗体 `未找到钩子` + 次行 `已配置的钩子将显示在此处`。

**连接**（settingsPane=.connections）
- 标题 `连接`；下方三 tab：`控制这台 Mac`（选中）| `控制其他设备` | `SSH`（选中项底部下划线）。
- `可控制这台 Mac 的设备` section（右 `添加`）→ 卡，三行：`Macintosh Intel Mac OS X`(laptop) `上次连接时间：5 天` 右 `撤销访问权限`；`Android 16 V2436A`(phone) `上次连接时间：3 周` 右 撤销；`iOS 18.5 iPhone`(phone) `上次连接时间：3 周` 右 撤销。
- `其他设置` section 卡：`允许发现并控制此设备` / `您 ChatGPT 账户下的已授权设备可以发现并控制此设备` toggle on；`让这台 Mac 保持唤醒状态` / `当电脑接通电源且启用远程访问时，防止其进入睡眠状态` toggle on。

**Git**（settingsPane=.git）
- 标题 `Git`。卡（多行）：
  - `分支前缀` / `在 Codex 中创建新分支时使用的前缀` → 文本框 `codex/`。
  - `拉取请求合并方法` / `选择 Codex 合并拉取请求的方法` → 分段 `合并 | 压缩`。
  - `在侧边栏显示 PR 图标` / `在侧边栏的对话行中显示 PR 状态图标` → toggle off。
  - `始终强制推送` / `从 Codex 推送时使用 --force-with-lease 参数` → toggle off。
  - `创建草稿拉取请求` / `从 Codex 创建 PR 时默认使用草稿拉取请求` → toggle on。
  - `自动删除旧工作树` / `推荐大多数用户启用。仅当你需要手动管理旧工作树和磁盘使用空间时，再关闭此功能。` → toggle on。
  - `自动删除限制` / `自动清理较旧工作树前保留的 Codex 工作树数量。Codex 会在删除前为工作树创建快照，因此被清理的工作树应始终可恢复。` → 数字框 `15`。
- `提交指令`（右 `保存`，副标题 `已添加到提交信息生成提示中`）→ 文本域占位 `添加提交消息指引...`。
- `拉取请求指令`（右 `保存`，副标题 `已添加到 PR 标题/描述生成提示中`）→ 文本域占位 `添加拉取请求指引...`。

**环境**（settingsPane=.environment）
- 标题 `环境` + 副标题 `本地环境用于指示 Codex 如何为项目设置工作树。了解更多。`
- `选择项目` section（右 `添加项目`）→ 项目行列表（folder 图标 + 名 + 右 `＋`）：openclaw、RaytoneCodex、token-platform、Raytone、MInigames、ds-tui-console-design、AINative-DevOps、sub2（名后带浅色标签 `Wei-Shaw`）。
- 选中/展开 RaytoneCodex 时其下出现子行：`RaytoneCodex` / `environment.toml`（次行灰）右 `查看`。

**工作树**（settingsPane=.worktree）
- 标题 `工作树`；`尚无工作树` + 右上刷新图标；空卡 `Codex 创建的工作树将显示在此处。`

> settingsPane 枚举建议补齐：general, profile, appearance, configuration, personalization, shortcuts, usageBilling, snapshots, mcp, browser, computerControl, hooks, connections, git, environment, worktree, archived。导航顺序照截图：个人(常规/个人资料/外观/配置/个性化/键盘快捷键/使用情况和计费) → 集成(应用快照/MCP 服务器/浏览器/电脑操控) → 编码(钩子/连接/Git/环境/工作树) → 已归档(已归档对话)。

---

## 5. 侧栏微调（可选，对照截图 1）
- 首屏时，项目下前 9 条对话右侧显示 `⌘1…⌘9` 快捷跳转提示（等宽小字、tertiary）；其余显示相对时间/云图标。可在 `SidebarThreadRow` 加一个可选 `shortcutHint: String?`，并在 `AppCommands` 里把 ⌘1…⌘9 绑到前 9 条 `selectThread`。

---

## 6. 「完全访问」下拉 = 批准模式选择器（composer / hero 都用）

点底部 composer（和 hero composer）里的 `完全访问` 胶囊 → 弹出**自定义 popover**（不是普通 Menu，因为每项有两行）：
- 顶部一行：标题 `应该如何批准 Codex 操作？`(13 medium) + 右侧 `了解更多`(蓝链)。
- 三个可选行，每行：左 图标（圆角方浅底）+ 中 标题(13 medium) + 描述(11–12 secondary) + 右 选中显示 ✓：
  1. `请求批准` / `编辑外部文件和使用互联网时始终询问`（icon `hand.raised`）
  2. `替我审批` / `仅对检测到的风险操作请求批准`（icon `checkmark.shield`）
  3. `完全访问权限` / `可不受限制地访问互联网和您电脑上的任何文件`（icon `globe`，截图中为选中态 ✓）
- 选中行轻微高亮（Theme.fillSelected）；点击即选中并关闭。popover 宽 ~330，白底圆角卡 + 细边。
- 胶囊外显短名：`请求批准 / 替我审批 / 完全访问`；为 `完全访问` 时图标用 `exclamationmark.triangle` + warning 橙，其它用 secondary。
- 模型建议：`enum AccessMode: CaseIterable { case ask, autoReview, full }`，各带 `title/desc/symbol/shortTitle`；`@Published var accessMode = .full` 于 store。胶囊读 `accessMode.shortTitle`。（底层可顺带把 .ask→approval=.onRequest、.full→sandbox=.dangerFullAccess 映射，但 UI 以 accessMode 为准。）
- 实现：`.popover(isPresented: $showAccessMenu, arrowEdge: .bottom)` 挂在胶囊上；内容是一个 VStack（header + 3 行 Button(.plain)）。

## 7. 右侧面板：内置浏览器工具

右侧面板有**两种模式**：默认「工具启动器」(文件/侧边聊天/浏览器/终端 + 推荐，已实现)；点某个工具卡后切到该工具视图。本次实现 `浏览器`：
- 顶部**标签栏**：一个标签 `🌐 {页面标题}`（globe 图标 + 标题，单行省略，右侧小 ✕ 关闭）+ `＋`(新标签)；最右窗口控件沿用现有（展开/收起/面板切换）。
- **工具栏**（一行）：`←` `→` `⟳`(chevron.left / chevron.right / arrow.clockwise，禁用态变灰) + **地址栏**（圆角灰底，flex，显示 URL 或本地路径，如 `/Users/.../raytone-growth-optimization-500.html`，等宽小字省略）+ 右侧图标 `截图`(camera)、`在浏览器打开`(arrow.up.forward.app)、`更多`(ellipsis)。
- **内容区**：用 `NSViewRepresentable` 包 `WKWebView` 真实渲染（给 file URL 或 https 就能显示；后端接真实导航/加载状态）。无 URL 时显示占位空态：居中 globe 图标 + `在地址栏输入网址或打开一个本地文件`。
- 面板状态建议：`enum ToolPanel { case launcher, browser, files, terminal, sideChat }` + `@Published var toolPanel = .launcher`；工具卡点击切换；标签 ✕ / 返回回 `.launcher`。`文件/终端/侧边聊天` 可先占位视图（标题 + 空态），仅 `浏览器` 做成真 WKWebView。
- 截图验收：给浏览器加载一个本地示例 HTML（可用仓库里现成的 artifact，或临时写一个），出一张 `--screen browser` 截图。

> 注：以上是 UI 外壳 + 真实 WKWebView 渲染；地址栏导航/标签管理/加载进度等交互逻辑可后端阶段再补。

---

## 8. 运行中的对话（环境信息面板 + 进行中目标 + 内联命令审批）

右侧面板按线程状态切换内容：**空/新线程** → §7 工具启动器；**活动线程**(有 items) → 「环境信息」；**浏览器工具开启** → §7 浏览器。

### 8a. 右侧「环境信息」面板（活动线程）
- 顶部：标题 `环境信息`(13 medium) + 右侧齿轮按钮。
- 一组行（图标 + 文案，部分可点/下拉）：
  - `变更`（icon `plus.forwardslash.minus`）→ 点开右侧/弹层看 diff（可复用 pendingChanges）。
  - `本地 ⌄`（icon `desktopcomputer`，运行模式下拉）。
  - `{分支} ⌄`（icon `arrow.triangle.branch`，如 `main`）。
  - `提交或推送`（icon `arrow.up.circle` / `square.and.arrow.up`）。
  - PR 状态（icon GitHub）：正常显示状态，无则灰字 `无法获取拉取请求状态`。
- `进度` section：竖向 checklist，每项前一个状态图标 + 文案(13)：
  - 已完成：`checkmark.circle.fill`（绿）。
  - 进行中：小 spinner（ProgressView .small）。
  - 待办：`circle`（空心、tertiary）。
  - 示例项：①重新校准生产访问、token 和现有审计报告状态(done) ②验证上传 UI 候选并清理测试数据(进行中) ③继续审计 Composer、Inspector、Settings/错误态等高风险工作流(待办) ④把确认的 P0/P1 与排除项写入报告(待办)。
  - 数据建议：`struct ProgressStep { title; state: .done/.running/.pending }`，给活动 demo 线程塞一组。
- `来源` section：一行小图标（`command`、`globe` 等，代表本轮引用来源），可先占位。
- 整个面板 padding 16、行高 ~30、section 标题用 SectionLabel；浅灰底（Theme.panel）。

### 8b. 顶部「进行中的目标」条（活动线程，transcript 底部、composer 之上）
- 一张圆角浅底卡，单行：左 `⟳`/目标图标 + `进行中的目标` + 目标标题（省略），中 elapsed 计时 `1d 1h 44m 56s`（等宽、secondary），右 一组小图标按钮：编辑(pencil)、暂停(pause)、删除(trash)、展开(chevron.right)。
- 数据：`struct ActiveGoal { title; startedAt }`，计时用 `TimelineView(.periodic)` 或简单 1s 定时刷新；demo 给一个固定 startedAt。
- 仅活动/运行中线程显示；点展开可显示目标详情（先占位）。

### 8c. 内联命令审批（替换/扩展现有 ApprovalCard 的 .command 形态）
本机 Codex 的命令审批不是「批准/拒绝」两钮，而是 transcript 内一张卡：
- 顶部可选 一行说明（rationale，如 `需要用 Playwright 对生产页面执行真实附件上传交互，Browser runtime 不支持 file chooser 操作。`）。
- 命令块：等宽、浅灰底圆角，整条命令（如 `node audits/upload-ui-current-probe.mjs | tee /private/tmp/dsx-upload-ui-probe.out`）。
- 三个选项行（可上下键选择，选中行高亮 + 右侧 `↑↓` 提示）：
  1. `是`
  2. `是，且对于以 {命令前缀} 开头的命令不再询问`（前缀用等宽 inline code，如 `node audits/upload-ui-current-probe.mjs`）
  3. `否，请告知 Codex 如何调整`
- 第 3 行右侧放两个按钮：`跳过`（次按钮）、`提交 ↵`（主按钮，深色）。
- 数据：扩展 `ApprovalRequest`——加 `rationale: String?`、`command: String?`、`commandPrefix: String?`；`.command` 类型用本卡渲染，`.patch/.network` 仍可用旧卡或同款。`decideApproval` 增加 `.approved / .approvedAlways / .denied(note)` 三态（或复用现有 + 一个 always 标记）。先做 UI + 本地选中态即可，真实执行后端接。

---

## 通用还原要点
- 全部用 `Theme` 语义色（`windowBackgroundColor`/`textBackgroundColor`/`separatorColor` + primary/secondary 透明度），不要硬编码 hex；深浅自动适配。
- 圆角：行/控件 8–9，卡片 12，大输入框 18，胶囊用 Capsule。
- 字号 ≥11；两种字重（regular/medium/semibold）。中文句式照抄截图。
- 顶部 36pt 预留红绿灯；全窗口子页面顶部同样让出标题栏拖拽区。
- 下拉用 `Menu` + `.menuStyle(.borderlessButton)` + `.menuIndicator(.hidden)`；分段用自绘双按钮或 `Picker(.segmented)`；toggle 用 `Toggle(...).toggleStyle(.switch)`，去掉默认 label 用 `.labelsHidden()` 配合自定义行。
