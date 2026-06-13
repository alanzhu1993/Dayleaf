# Product Spec - 2026-06-13

## 1. Product Summary

“一日一笺”是一款本地优先的 macOS 菜单栏记录工具，用于记录一天中的专注时间段和临时想法。

V1 包含两类记录：

- 专注记录：开始、暂停、继续、结束，形成一段带开始时间、结束时间和有效时长的记录。
- 碎碎念记录：通过快速入口连续记录灵感、想法或临时备注，自动带时间点和精确时间戳。

数据先保存在本地，用户点击导出时生成当天 Markdown。Markdown 用于后续交给 AI 做温暖型日常回顾，让用户感觉这一天被认真看见，并获得轻量、可执行的明日建议。

## 2. Target Users

第一目标用户是 Alan 本人：销售与业务拓展负责人，需要记录客户沟通、内部协作、深度工作、临时想法和日常状态。

扩展用户是需要轻量复盘的知识工作者：他们不想维护复杂项目管理系统，但希望低成本保留一天的时间线。

## 3. Core Problem

用户一天中上下文切换多，事后很难准确回忆做了什么、哪些时间用于专注、哪些想法被临时打断。传统时间追踪工具配置重，番茄钟又通常只记录计时，不记录真实工作内容。

V1 要解决的问题是：让用户用最低阻力捕捉专注时间段和临时想法，并在一天结束时得到一份适合 AI 分析的 Markdown 日记。

## 4. Product Positioning

产品定位是“菜单栏里的本地时间日记”，不是完整项目管理工具、团队工时系统、自动监控软件或内置 AI 助理。

核心价值：

- 菜单栏常驻，快速打开。
- 支持专注正计时和暂停。
- 支持连续碎碎念记录。
- 本地保存，不上传。
- 导出目录可配置，避免写死个人路径。
- 生成结构化 Markdown，方便 AI 总结。

## 5. V1 Scope

### In Scope

- macOS SwiftUI 原型应用。
- 菜单栏常驻入口。
- 专注记录：开始、暂停、继续、结束。
- 专注结束后记录实际完成内容。
- 碎碎念记录：快速输入、连续提交、自动记录时间点和时间戳。
- 今日时间线：专注记录和碎碎念按发生时间混合排序展示。
- 本地 JSON 持久化，关闭应用后记录不丢失。
- 设置导出目录，并把路径保存在本地设置。
- 未设置导出目录时使用通用默认路径 `~/Documents/一日一笺/`。
- 导出当天中文 Markdown，包含概览、时间线和给 AI 的温暖型提示。

### Out of Scope

- V1 不内置 AI API，不自动总结。
- V1 不上传数据，不做云同步。
- V1 不做自动屏幕、键盘、浏览器或应用使用监控。
- V1 不做团队协作。
- V1 不做复杂标签、客户、项目体系。
- V1 不做 25/5 番茄倒计时循环。
- V1 不写死 Alan 的个人目录。

## 6. Main User Flow

### 专注记录

1. 用户点击菜单栏图标。
2. 用户可先输入计划做什么，也可以直接开始。
3. 用户点击开始专注。
4. 应用开始正计时。
5. 用户可暂停和继续。
6. 用户结束专注后填写实际做了什么。
7. 应用保存一条专注记录，包含开始时间、结束时间、暂停区间和有效时长。

### 碎碎念记录

1. 用户点击菜单栏图标。
2. 用户在快速记录框里输入临时想法。
3. 用户提交后，输入框清空并保持可输入。
4. 每条碎碎念独立保存为时间点记录。

### 导出

1. 用户在设置中选择导出目录，或使用默认目录。
2. 用户点击导出今日 Markdown。
3. 应用生成当天 Markdown 文件。
4. 用户把 Markdown 文件交给 AI 工具做总结。

## 7. Functional Requirements

### 7.1 Menu Bar Entry

- 应用启动后在 macOS 菜单栏显示入口。
- 菜单栏弹窗是 V1 主界面。
- 主界面必须优先展示当前专注状态、快速记录输入框和今日时间线。

### 7.2 Focus Session

- 支持输入可选的计划内容后开始专注。
- 支持不填写计划内容直接开始。
- 专注计时为正计时。
- 支持暂停和继续。
- 结束时要求填写实际完成内容。
- 有效时长必须排除暂停时间。
- 专注记录保存开始时间、结束时间、暂停区间、有效时长、计划内容和实际内容。

### 7.3 Quick Notes

- 支持快速输入碎碎念。
- 支持连续提交多条记录。
- 每条记录保存内容、发生时间和创建时间戳。
- 碎碎念是独立时间点记录，不挂靠到当前专注段。

### 7.4 Daily Timeline

- 默认展示当天记录。
- 专注记录和碎碎念按发生时间排序。
- 时间线至少显示时间、类型、内容和专注记录持续时长。

### 7.5 Local Persistence

- 所有记录保存在本地 JSON 文件。
- 用户设置保存在本地 JSON 文件。
- 关闭并重新打开应用后，当天记录仍然存在。
- 不需要网络。

### 7.6 Markdown Export

导出文件命名：

```text
YYYY-MM-DD-一日一笺.md
```

默认导出目录：

```text
~/Documents/一日一笺/
```

Markdown 文件结构：

```markdown
# 2026-06-13 一日一笺

## 概览

- 日期：
- 导出时间：
- 专注记录：
- 快速记录：
- 总专注时长：

## 时间线

| 时间 | 时间戳 | 类型 | 内容 | 时长 |
|---|---|---|---|---|
| 09:10 | 2026-06-13T09:10:00+08:00 | 专注 | 写客户方案 | 42分钟 |
| 10:03 | 2026-06-13T10:03:12+08:00 | 记录 | 想到一个销售复盘角度 | - |

## 给 AI 的提示

请像一位真诚、温和的朋友一样阅读这份一天记录。先用几句话概括我今天经历了什么，不要只做冷冰冰的数据分析。看到我完成的事、投入的注意力、可能的疲惫或被打断，也请温柔地指出来。请给我一段有温度的回应，让我感觉这一天被认真看见。最后给出 2-3 条明天可以尝试的小建议，要求具体、轻量、可执行，不要说教。
```

### 7.7 Settings

- 支持选择导出目录。
- 支持显示当前导出目录。
- 不设置导出目录时使用默认通用路径。
- V1 不设置固定全局快捷键；快捷键配置可作为后续打包版本能力。

## 8. AI / Agent Behavior

V1 中应用本身不调用 AI、不配置 API Key、不上传数据、不自动总结。

应用只生成适合 AI 做温暖型日常回顾的 Markdown，并在文件末尾附“给 AI 的提示”。用户自行把 Markdown 提供给任意 AI 工具。

## 9. Data, Storage, Runtime, and Integrations

- 运行环境：macOS。
- 技术路线：SwiftUI + Swift Package 原型。
- 数据保存：本地 JSON。
- 网络要求：无。
- 外部服务：无。
- 导出格式：Markdown。
- 时间处理：使用本机时区。
- 导出路径：用户设置目录；未设置时使用 `~/Documents/一日一笺/`。

核心数据结构：

```swift
enum DayEntry {
    case focusSession(FocusSession)
    case quickNote(QuickNote)
}

struct QuickNote {
    let id: UUID
    var content: String
    var occurredAt: Date
    var createdAt: Date
    var updatedAt: Date
}

struct FocusSession {
    let id: UUID
    var plannedActivity: String?
    var actualActivity: String
    var startedAt: Date
    var endedAt: Date?
    var pauseIntervals: [PauseInterval]
    var activeDurationSeconds: Int
    var createdAt: Date
    var updatedAt: Date
}
```

## 10. Permissions and Safety Boundaries

- 应用只写入本地数据目录和用户选择的导出目录。
- 应用不得写死个人路径。
- 应用不得自动上传记录。
- 应用不得自动发送邮件或消息。
- 应用不得采集屏幕、键盘、浏览器历史或其他应用使用记录。
- 导出同名文件时默认追加编号，避免覆盖用户文件。

## 11. Acceptance Criteria

V1 完成必须满足：

- 用户可以通过菜单栏打开记录界面。
- 用户可以开始、暂停、继续、结束一段专注。
- 专注有效时长排除暂停时间。
- 用户可以连续提交多条碎碎念。
- 每条碎碎念包含时间点和时间戳。
- 今日时间线混合展示专注记录和碎碎念。
- 关闭并重新打开应用后记录仍然存在。
- 用户可以配置导出目录。
- 未配置导出目录时，应用使用通用默认目录。
- 导出的 Markdown 包含概览、时间线和给 AI 的温暖型中文提示。
- 代码和默认配置中不包含 Alan 的个人固定路径。
- 无网络状态下可以完整记录和导出。

## 12. Open Questions

- 完整 `.app` 打包需要安装 Xcode 后推进。
- 全局快捷键配置在 Swift Package 原型中暂不作为验收核心，建议进入打包版本。

## 13. Assumptions

- V1 不实时追加写入 Markdown，而是本地保存、导出时生成。
- 碎碎念是独立时间点记录。
- V1 不内置 AI。
- V1 用正计时专注，不做倒计时番茄循环。
- Swift Package 原型优先，正式发布包后续处理。
- 产品对外中文名为“一日一笺”，但内部 Swift Package 和 target 名称暂时保留 Dayleaf。

## 14. Change Log

- 2026-06-13: Created initial product spec from rough product idea.
- 2026-06-13: Revised V1 scope for menu bar focus sessions, quick notes, configurable export directory, and AI-ready Markdown export.
- 2026-06-13: Set product name to 一日一笺 and revised Markdown export to Chinese with a warm friend-style AI prompt.
