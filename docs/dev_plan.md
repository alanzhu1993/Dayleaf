# Development Plan - 2026-06-13

## 1. Current Project State

项目当前是文档骨架，没有应用代码。当前机器有 Swift 6.3.1 和 Command Line Tools，但没有完整 Xcode，`xcodebuild` 不可用。

## 2. Technical Assumptions

- V1 先用 Swift Package 实现 SwiftUI 原型。
- 正式 `.app` 打包等安装完整 Xcode 后处理。
- 不接网络，不接 AI API。
- 数据使用本地 JSON。

## 3. Stack and Architecture

- `DayLogCore`：数据模型、JSON 存储、Markdown 导出。
- `DayLogApp`：SwiftUI 菜单栏界面和设置。
- `DayLogCoreTests`：核心逻辑测试。

## 4. External Dependencies

无第三方依赖。

## 5. Development Phases

### Phase 1: Core Model and Export

#### Goal

实现专注记录、碎碎念记录、本地设置、中文 Markdown 生成。

#### Scope

- 数据模型。
- JSON 编解码。
- Markdown 导出。
- 默认导出目录。

#### Expected User-visible Result

应用可以保存记录并导出当天 Markdown。

#### Files / Modules

- `Sources/DayLogCore`
- `Tests/DayLogCoreTests`

#### Acceptance Criteria

- 快速记录保存时间点和时间戳。
- 专注有效时长排除暂停。
- 导出 Markdown 包含概览、时间线和给 AI 的温暖型中文提示。

#### Test Plan

- `swift build`
- `swift run DayLogCoreCheck`

#### Risks

- 时间和时区格式需要稳定。

#### Notes

避免写死个人路径。

### Phase 2: Menu Bar Prototype

#### Goal

实现 SwiftUI 菜单栏主界面。

#### Scope

- 菜单栏入口。
- 开始、暂停、继续、结束专注。
- 快速记录连续输入。
- 今日时间线。
- 导出目录选择。

#### Expected User-visible Result

用户能通过菜单栏完成 V1 主流程。

#### Files / Modules

- `Sources/DayLogApp`

#### Acceptance Criteria

- 菜单栏弹窗可打开。
- 当前专注状态可见。
- 记录和导出操作有反馈。

#### Test Plan

- `swift build`
- 手动运行 `swift run DayLog`

#### Risks

- Swift Package 原型不是正式 `.app` 包，部分系统行为与正式发布包不同。

#### Notes

全局快捷键留到打包版本。

## 6. Parallelizable Work

- Core 测试和 UI 细节可分开做。
- 文档更新可与代码开发并行。

## 7. Review Gates

- dependency check: Swift toolchain exists.
- typecheck/build: `swift build`
- automated checks: `swift run DayLogCoreCheck`
- unit tests: `swift test` 当前 Command Line Tools 环境没有可用 XCTest，暂不可用。
- lint: 当前无 SwiftLint，记录为 unavailable。
- manual smoke test: `swift run DayLog`。
- independent review: 更新 `docs/review_report.md`。

## 8. Rollback Strategy

Swift Package 新增文件相对独立。如原型不可用，可保留 `DayLogCore` 和测试，移除或替换 `DayLogApp`。

## 9. Open Questions

- 正式发布前是否安装 Xcode 并迁移为标准 macOS App 工程。
- 全局快捷键是否在正式 `.app` 版本实现。

## 10. Change Log

- 2026-06-13: Created V1 development plan.
- 2026-06-13: Updated verification gates to use `DayLogCoreCheck` because XCTest is unavailable in the current Command Line Tools environment.
- 2026-06-13: Removed prototype notification scope after UI smoke feedback showed the Swift Package app can crash when ending a focus session.
- 2026-06-13: Updated export requirements for 一日一笺 Chinese Markdown and warm friend-style AI prompt.
