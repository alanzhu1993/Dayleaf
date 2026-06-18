# 发布说明

## 版本

v1.1

## 概要

一日一笺 1.1 增加全局快速记录入口，并修复日记窗口切换日记时正文不同步的问题。用户可以用快捷键直接弹出快速记录小窗口，也可以继续在日记窗口里查看、编辑、删除和导出 AI 整理后的日记。

这仍然是早期预览版。应用已做本地临时签名，但还没有开发者签名和公证。系统首次打开时可能提示无法验证开发者；如无法直接打开，请右键点击应用并选择“打开”。

## 打包说明

- `scripts/package_app.sh` 会构建发布版本，生成 `AppIcon.icns`，组装 `dist/一日一笺.app`，并生成 `dist/一日一笺.dmg`。
- 应用包信息包含：`CFBundleIdentifier=com.alanzhu.dayleaf`、`CFBundleDisplayName=一日一笺`、`CFBundleExecutable=Dayleaf`、`CFBundleIconFile=AppIcon`、`LSUIElement=true`。
- 本地打包时会做临时签名，避免苹果芯片电脑上出现“应用已损坏”的错误。
- 当前没有开发者签名，也没有公证。
- 发布附件只上传 `一日一笺.dmg`。

## 新增

- 新增全局快速记录快捷键。
- 新增独立快速记录浮窗：按快捷键后直接输入，`Return` 保存并关闭，`Shift + Return` 换行，`Esc` 取消。
- 设置中支持修改快速记录快捷键。

## 改进

- 快速记录保存失败时不再误提示成功，也不会丢失草稿。
- 时间线编辑保存失败时保留编辑态和未保存草稿。
- 日记窗口切换不同日记时，正文编辑器会跟随左侧选中项正确刷新。
- 快捷键注册失败时会在设置里显示提示，方便用户换一个组合。
- 应用版本默认值更新为 `1.1`。

## 已知限制

- 当前构建需要苹果电脑系统 26.0 或更高版本。
- `.app` 和 `.dmg` 已做本地临时签名，但没有开发者签名和公证；系统首次打开时仍会提示无法验证开发者。
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
- 增加历史日期查看和导出前预览。
