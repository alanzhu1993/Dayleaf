# 发布说明

## 版本

v1.0

## 概要

一日一笺 1.0 加入本地优先的 AI 日记窗口。用户可以绑定自己的 OpenAI 兼容模型服务，用「一笺成文」把当天碎片记录整理成第一人称日记，并在本地查看、编辑、删除和导出。

这仍然是早期预览版。应用已做本地临时签名，但还没有开发者签名和公证。系统首次打开时可能提示无法验证开发者；如无法直接打开，请右键点击应用并选择“打开”。

## 打包说明

- `scripts/package_app.sh` 会构建发布版本，生成 `AppIcon.icns`，组装 `dist/一日一笺.app`，并生成 `dist/一日一笺.dmg`。
- 应用包信息包含：`CFBundleIdentifier=com.alanzhu.dayleaf`、`CFBundleDisplayName=一日一笺`、`CFBundleExecutable=Dayleaf`、`CFBundleIconFile=AppIcon`、`LSUIElement=true`。
- 本地打包时会做临时签名，避免苹果芯片电脑上出现“应用已损坏”的错误。
- 当前没有开发者签名，也没有公证。
- 发布附件只上传 `一日一笺.dmg`。

## 新增

- 新增独立日记窗口，用于查看、编辑、删除整理好的日记。
- 新增「一笺成文」，把当天记录整理成第一人称日记。
- 支持 OpenAI 兼容接口配置：`base_url`、`model` 和 API Key。
- API Key 保存到 Keychain，不写入本地 JSON。
- 支持将整理好的日记导出为 PDF。

## 改进

- 菜单栏面板继续保持轻量，只负责快速记录、专注和打开日记。
- AI 不在后台自动分析，只在用户主动点击「一笺成文」时调用。
- AI 输出 prompt 收紧为第一人称、克制整理，不做心理诊断、性格判断或长期画像。
- 隐私文案更新为：默认本地保存；启用 AI 后内容会直接发送给用户配置的第三方模型服务。
- 应用版本默认值更新为 `1.0`。

## 已知限制

- 当前构建需要苹果电脑系统 26.0 或更高版本。
- `.app` 和 `.dmg` 已做本地临时签名，但没有开发者签名和公证；系统首次打开时仍会提示无法验证开发者。
- 暂无全局快捷键。
- 暂无系统通知。
- 时间线编辑目前只能修改文字，不能修改开始时间、结束时间和时长。
- 当前本地环境不使用 `swift test`，核心检查使用 `DayleafCoreCheck`。

## 运行源码

```bash
git clone https://github.com/alanzhu1993/Dayleaf.git
cd Dayleaf
swift run Dayleaf
```

## 本地验证

```bash
swift build
swift run DayleafCoreCheck
```

## 下一步

- 做开发者签名和公证。
- 增加全局快捷键配置。
- 增加历史日期查看和导出前预览。
