import Foundation
import RaytoneCodexCore

/// Pre-baked, Chinese-localized content so the UI mirrors the Codex Mac app
/// without requiring a backend on first launch. Keep this data generic: it is
/// product scaffolding, not a dump of local user projects.
enum SampleData {
    private static func ctx(_ text: String, _ old: Int, _ new: Int) -> DiffLine {
        DiffLine(kind: .context, text: text, oldLine: old, newLine: new)
    }

    private static func add(_ text: String, _ new: Int) -> DiffLine {
        DiffLine(kind: .added, text: text, newLine: new)
    }

    private static func del(_ text: String, _ old: Int) -> DiffLine {
        DiffLine(kind: .removed, text: text, oldLine: old)
    }

    private static func ago(_ minutes: Double) -> Date {
        Date().addingTimeInterval(-minutes * 60)
    }

    static func demoThread(projectID: UUID) -> ChatThread {
        let activeGoal = ActiveGoal(
            title: "完成 Codex 风格运行中对话验收",
            startedAt: Date().addingTimeInterval(-(25 * 60 * 60 + 44 * 60 + 56))
        )
        let progressSteps = [
            ProgressStep(title: "重新校准生产访问、token 和现有审计报告状态", state: .done),
            ProgressStep(title: "验证上传 UI 候选并清理测试数据", state: .running),
            ProgressStep(title: "继续审计 Composer、Inspector、Settings/错误态等高风险工作流", state: .pending),
            ProgressStep(title: "把确认的 P0/P1 与排除项写入报告", state: .pending)
        ]
        let changes: [TranscriptItem] = [
            TranscriptItem(timestamp: ago(40), kind: .fileChange(FileChange(
                path: "Sources/RaytoneCodex/Views/ComposerView.swift",
                type: .modified,
                additions: 36,
                deletions: 4,
                hunks: [
                    DiffHunk(header: "@@ -42,7 +42,12 @@ private var controlRow", lines: [
                        ctx("        HStack(spacing: 8) {", 42, 42),
                        del("            modelField", 43),
                        add("            modelMenu", 43),
                        add("            micButton", 44),
                        add("            sendButton", 45),
                        ctx("        }", 46, 46)
                    ])
                ]
            ))),
            TranscriptItem(timestamp: ago(40), kind: .fileChange(FileChange(
                path: "Sources/RaytoneCodex/Views/ThreadView.swift",
                type: .modified,
                additions: 28,
                deletions: 2
            ))),
            TranscriptItem(timestamp: ago(40), kind: .fileChange(FileChange(
                path: "script/build_and_run.sh",
                type: .modified,
                additions: 42,
                deletions: 0
            ))),
            TranscriptItem(timestamp: ago(40), kind: .fileChange(FileChange(
                path: "docs/evidence-2026-06-09.md",
                type: .added,
                additions: 54,
                deletions: 0
            )))
        ]

        let transcript: [TranscriptItem] = [
            TranscriptItem(timestamp: ago(41), kind: .userMessage(
                "把 Mac 客户端调成 Codex 风格，补一个 UI smoke，截图要能证明窗口和内置 CLI 都是真实跑过的。"
            )),
            TranscriptItem(timestamp: ago(39), kind: .command(CommandRun(
                command: "swift build && ./script/test.sh",
                directory: "~/Projects/RaytoneCodex",
                output: "Build complete!\nRaytoneCodexCoreChecks: all checks passed",
                exitCode: 0,
                status: .succeeded
            ))),
            TranscriptItem(timestamp: ago(38), kind: .agentMessage(
                "已把左侧栏、项目列表、中央 transcript、底部 composer 和右侧工具面板收敛成一套 Codex-like 桌面壳。下一步把窗口截图验证固化到脚本。"
            )),
            TranscriptItem(timestamp: ago(36), kind: .command(CommandRun(
                command: "bash ./script/build_and_run.sh --ui-smoke",
                directory: "~/Projects/RaytoneCodex",
                output: """
                {
                  "ok": true,
                  "windowWidth": 1440,
                  "windowHeight": 900,
                  "runtimeVersion": "codex-cli 0.137.0-alpha.4"
                }
                """,
                exitCode: 0,
                status: .succeeded
            ))),
            TranscriptItem(timestamp: ago(35), kind: .agentMessage(
                "UI smoke 已经生成截图，并且 runtime 版本来自 staged Codex CLI。当前机器没有签名身份，所以 release 安装包还需要 Developer ID + notarization 才能最终证明。"
            )),
            TranscriptItem(timestamp: ago(34.8), kind: .approval(ApprovalRequest(
                kind: .command,
                title: "请求执行命令",
                detail: "node audits/upload-ui-current-probe.mjs | tee /private/tmp/dsx-upload-ui-probe.out",
                rationale: "需要用 Playwright 对生产页面执行真实附件上传交互，Browser runtime 不支持 file chooser 操作。",
                command: "node audits/upload-ui-current-probe.mjs | tee /private/tmp/dsx-upload-ui-probe.out",
                commandPrefix: "node audits/upload-ui-current-probe.mjs",
                decision: .pending
            )))
        ]

        return ChatThread(
            title: "验证 Mac 客户端 UI smoke",
            projectID: projectID,
            items: changes + transcript,
            model: "gpt-5.1-codex",
            sandbox: .dangerFullAccess,
            approval: .never,
            activeGoal: activeGoal,
            progressSteps: progressSteps,
            updatedAt: ago(35)
        )
    }

    static func debugThread(projectID: UUID) -> ChatThread {
        ChatThread(
            title: "运行核心检查",
            projectID: projectID,
            items: [
                TranscriptItem(timestamp: ago(70), kind: .userMessage("跑一下核心检查。")),
                TranscriptItem(timestamp: ago(69.6), kind: .command(CommandRun(
                    command: "swift run RaytoneCodexCoreChecks",
                    directory: "~/Projects/RaytoneCodex",
                    output: "RaytoneCodexCoreChecks: all checks passed",
                    exitCode: 0,
                    status: .succeeded
                ))),
                TranscriptItem(timestamp: ago(69.4), kind: .notice(Notice(
                    level: .info,
                    text: "核心检查通过。继续跑 CLI smoke 和 UI smoke。"
                )))
            ],
            model: "gpt-5.1-codex",
            sandbox: .readOnly,
            approval: .never,
            updatedAt: ago(69.4)
        )
    }

    static func secondaryBundle(workspacePath: String) -> (project: Project, threads: [ChatThread]) {
        let project = Project(name: "Raytone Demo", path: workspacePath, branch: "main")
        let browser = ChatThread(
            title: "检查登录回调页面",
            projectID: project.id,
            items: [
                TranscriptItem(timestamp: ago(60 * 24), kind: .userMessage("用内置浏览器打开 staging 站点，确认登录回调没有 404。")),
                TranscriptItem(timestamp: ago(60 * 24 - 1), kind: .agentMessage("回调返回 302 并跳转到首页。网络面板里没有 404，cookie 写入正常。"))
            ],
            model: "gpt-5.1-codex",
            sandbox: .workspaceWrite,
            approval: .onRequest,
            updatedAt: ago(60 * 24)
        )
        let migrate = ChatThread(
            title: "迁移到 pnpm",
            projectID: project.id,
            items: [
                TranscriptItem(timestamp: ago(60 * 5), kind: .userMessage("把示例仓库从 npm 迁到 pnpm。")),
                TranscriptItem(timestamp: ago(60 * 5 - 1), kind: .approval(ApprovalRequest(
                    kind: .command,
                    title: "请求执行网络命令",
                    detail: "corepack enable && pnpm import",
                    decision: .pending
                )))
            ],
            model: "gpt-5.1-codex",
            sandbox: .workspaceWrite,
            approval: .untrusted,
            updatedAt: ago(60 * 5)
        )
        return (project, [browser, migrate])
    }

    static func extraWorkspace() -> [(project: Project, threads: [ChatThread])] {
        func empty(_ name: String, _ branch: String?) -> (Project, [ChatThread]) {
            (Project(name: name, path: "~/Projects/\(name)", branch: branch), [])
        }

        let design = Project(name: "Raytone Design", path: "~/Projects/Raytone-Design", branch: "ui/codex-shell")
        let designThreads = [
            chatStub("整理 composer 交互状态", design.id, days: 2),
            chatStub("对齐右侧工具面板", design.id, days: 4),
            chatStub("补充窗口截图验收", design.id, days: 7)
        ]

        let agents = Project(name: "Raytone Agents", path: "~/Projects/Raytone-Agents", branch: "main")
        let agentThreads = [
            chatStub("定义长运行任务状态", agents.id, days: 14),
            chatStub("审阅工具调用生命周期", agents.id, days: 21),
            chatStub("规划月度汇报", agents.id, days: 28)
        ]

        return [
            empty("Raytone Web", "main"),
            (design, designThreads),
            empty("Raytone Sandbox", nil),
            (agents, agentThreads)
        ]
    }

    private static func chatStub(_ title: String, _ projectID: UUID, days: Double) -> ChatThread {
        ChatThread(
            title: title,
            projectID: projectID,
            items: [TranscriptItem(timestamp: ago(60 * 24 * days), kind: .userMessage(title))],
            model: "gpt-5.1-codex",
            sandbox: .workspaceWrite,
            approval: .never,
            updatedAt: ago(60 * 24 * days)
        )
    }
}
