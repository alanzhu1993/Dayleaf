# Design Brief - 2026-06-13

## 1. Design Goal

设计目标是让用户能在不打断工作的情况下快速记录。“一日一笺”的 V1 主界面是菜单栏弹窗，不做大而全的仪表盘。

## 2. Product Personality

安静、轻量、克制、工具型。它应该像一个随手可用的工作计时器和日记夹，不像社交产品、游戏化打卡产品或 AI 聊天窗口。

## 3. Primary References

- macOS 菜单栏工具：小窗口、直接操作、状态清楚。
- Apple Reminders / Notes 的输入密度：少装饰、重输入。
- 简单计时器：当前状态一眼可见。

## 4. Anti-references

- 不做营销页式大标题和装饰背景。
- 不做复杂项目管理看板。
- 不做强 AI 感视觉元素。
- 不做游戏化连续打卡。

## 5. Visual Direction

### Theme

跟随系统浅色/深色模式。

### Color

使用系统色，强调色只用于主操作按钮和当前专注状态。

### Typography

使用系统字体。菜单栏弹窗内标题紧凑，正文和表格信息优先可读。

### Density

信息密度中高。用户打开弹窗时应同时看到当前专注、快速记录和今日最近记录。

### Shape and Components

使用 macOS 原生控件。按钮、输入框和列表保持系统风格，避免重阴影和大圆角。

## 6. Layout Principles

- 顶部显示当前日期和导出入口。
- 当前专注状态放在第一屏上方。
- 快速记录输入框始终容易到达。
- 今日时间线显示最近记录，完整历史可滚动。
- 设置入口展示当前导出目录并允许选择文件夹。

## 7. Page / View List

- 菜单栏弹窗：主工作区。
- 设置视图：导出目录选择、当前目录展示。
- 今日时间线：在主工作区内展示。

## 8. Key User Flows

- 开始专注：可输入计划，也可直接开始。
- 结束专注：填写实际完成内容后保存。
- 碎碎念：输入、提交、清空、继续输入。
- 导出：点击后生成 Markdown，并提示导出路径。

## 9. Component Requirements

- 当前专注卡片：显示状态、已用时、暂停/继续、结束。
- 开始专注区：计划输入框和开始按钮。
- 快速记录区：多行输入框和提交按钮。
- 时间线列表：时间、类型、内容、时长。
- 导出设置：目录文本、选择目录按钮。

## 10. Interaction States

- 空状态：今日还没有记录时显示简短提示。
- 专注中：开始按钮不可重复触发。
- 暂停中：显示继续按钮。
- 结束专注：实际内容为空时不保存。
- 导出成功：显示导出文件路径。
- 导出失败：显示可读错误。

## 11. Agent / Automation Status Design

V1 没有内置 AI 或自动化代理。Markdown 中只附中文“给 AI 的提示”，引导 AI 像温和的朋友一样做日常回顾。

## 12. Copywriting Tone

中文界面，短句，直接。日常记录界面保持克制；导出给 AI 的提示要有温度，强调“被看见、被理解、轻量建议”，避免说教。

## 13. Accessibility and Responsiveness

- 支持键盘提交。
- 文本不能挤出按钮或输入框。
- 菜单栏弹窗宽度固定在紧凑范围内，内容通过滚动展示。

## 14. Design Red Lines

- 不隐藏快速记录入口。
- 不要求用户先建项目、分类或标签。
- 不让导出路径写死为个人目录。
- 不在 V1 中加入云同步或 AI Key 设置。

## 15. Open Questions

- 打包为正式 `.app` 后是否加入全局快捷键配置。

## 16. Change Log

- 2026-06-13: Created design brief for V1 SwiftUI menu bar prototype.
- 2026-06-13: Updated visible product name to 一日一笺 and set export prompt tone to warm daily reflection.
