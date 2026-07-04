# RaytoneCodex

RaytoneCodex 是一个原生 SwiftUI macOS 客户端，界面参考 Codex 桌面端，后端通过内置的 openai/codex CLI `app-server` 长连接工作。

## 本地运行

```bash
swift build
bash script/build_and_run.sh
```

## 打包测试版

```bash
bash script/build_and_run.sh --package
```

产物会生成在 `dist/`：

- `RaytoneCodex.app`
- `RaytoneCodex-0.1.0-macos-arm64.zip`
- `RaytoneCodex-0.1.0-macos-arm64.dmg`

本机如果没有 Developer ID 签名身份，脚本会使用 ad-hoc 签名，适合内部测试。

## Codex 后端

脚本会按固定 commit 从 `openai/codex` 构建并打包 CLI：

```bash
bash script/build_codex_from_source.sh
```

生成的 schema 提交在 `Schemas/`，Swift 客户端通过这些协议类型对接 `codex app-server`。

## 运行验证

常用 smoke：

```bash
bash script/build_and_run.sh --tools-smoke
bash script/build_and_run.sh --catalog-smoke
bash script/build_and_run.sh --runtime-pages-smoke
bash script/build_and_run.sh --integration-pages-smoke
```

这些 smoke 会实际启动内置 Codex app-server，并验证文件读取、命令执行、插件/技能/设置页等运行时链路。
