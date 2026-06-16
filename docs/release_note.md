# 发布说明

## 版本

v0.4

## 概要

一日一笺 0.4 把日终整理入口从“导出 Markdown 文件”改成更贴近普通用户的两条路径：复制给 AI，以及保存为 PDF。

这仍然是早期预览版。应用已做本地临时签名，但还没有开发者签名和公证。系统首次打开时可能提示无法验证开发者；如无法直接打开，请右键点击应用并选择“打开”。

## 打包说明

- `scripts/package_app.sh` 会构建发布版本，生成 `AppIcon.icns`，组装 `dist/一日一笺.app`，并生成 `dist/一日一笺.dmg`。
- 应用包信息包含：`CFBundleIdentifier=com.alanzhu.dayleaf`、`CFBundleDisplayName=一日一笺`、`CFBundleExecutable=Dayleaf`、`CFBundleIconFile=AppIcon`、`LSUIElement=true`。
- 本地打包时会做临时签名，避免苹果芯片电脑上出现“应用已损坏”的错误。
- 当前没有开发者签名，也没有公证。
- 发布附件只上传 `一日一笺.dmg`。

## 新增

- 主界面右上角新增“复制给 AI”入口。
- 设置中新增“保存为 PDF”，用于查看、归档和分享。
- PDF 文件名使用 `YYYY-MM-DD-一日一笺.pdf`，重复保存时自动追加 `-2` 后缀，避免覆盖旧文件。
- 系统设置窗口显示保存/失败状态。

## 改进

- 普通用户界面不再强调 Markdown、MD 或标记文本。
- 设置文案从“导出目录”调整为“保存目录”。
- PDF 使用人类可读排版，不包含给 AI 的提示，也不是 Markdown 原文。
- 复制给 AI 的文本继续保留概览、时间线和温暖型提示，适合粘贴到用户自己选择的 AI 工具。
- 应用版本默认值更新为 `0.4`。

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
