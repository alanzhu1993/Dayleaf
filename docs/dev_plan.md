# Development Plan - 2026-06-14

## 1. Current Project State

项目当前已进入 `v0.4` 早期预览状态，不再只是文档骨架。

已具备：

- Swift Package 形式的 macOS 菜单栏应用。
- 本地 JSON 数据存储。
- 专注记录、快速记录、今日时间线。
- 复制给 AI。
- PDF 保存。
- 内部 Markdown 生成。
- 浅色 / 深色主题、设置面板、关于面板和操作提示。
- 本地临时签名的 `.app` / `.dmg` 打包脚本。

仍需补齐：

- 开发者签名和公证。
- 全局快捷键。
- 更完整的历史查看和导出体验。
- 更稳定的人工智能整理链路。
- 自动化 UI 测试或更系统的手动 QA。

## 2. Technical Assumptions

- 继续保持本地优先。
- 当前主线仍是 macOS SwiftUI + Swift Package。
- 数据继续使用本地 JSON，后续如引入 AI 也不改变本地数据所有权。
- AI 能力采用用户主动触发、用户自己的 API key、OpenAI 兼容接口；不做自动上传。
- 正式对外分发前需要完成开发者签名和公证。

## 3. Stack and Architecture

- `DayleafCore`：数据模型、JSON 存储、Markdown 导出。
- `DayleafApp`：SwiftUI 菜单栏界面和设置。
- `DayleafCoreCheck`：当前无 XCTest 环境下的核心逻辑检查。
- `scripts/package_app.sh`：本地构建、临时签名和 `.dmg` 打包。

## 4. External Dependencies

当前无第三方依赖。

后续 AI 阶段可能增加：

- Keychain 读写，用于保存用户 API key。
- OpenAI 兼容 HTTP / SSE 调用层。

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

- `Sources/DayleafCore`
- `Tests/DayleafCoreTests`

#### Acceptance Criteria

- 快速记录保存时间点和时间戳。
- 专注有效时长排除暂停。
- 导出 Markdown 包含概览、时间线和给 AI 的温暖型中文提示。

#### Test Plan

- `swift build`
- `swift run DayleafCoreCheck`

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

- `Sources/DayleafApp`

#### Acceptance Criteria

- 菜单栏弹窗可打开。
- 当前专注状态可见。
- 记录和导出操作有反馈。

#### Test Plan

- `swift build`
- 手动运行 `swift run Dayleaf`

#### Risks

- Swift Package 原型不是正式 `.app` 包，部分系统行为与正式发布包不同。

#### Notes

全局快捷键留到打包版本。

### Phase 3: v0.4 - Low-friction Day Review Export

#### Goal

让用户不用理解 Markdown，也能把当天记录拿去用。优先做复制给 AI 和保存 PDF，不急着内置 AI。

#### Scope

- 主入口改为复制给 AI。
- 设置中增加保存 PDF。
- PDF 使用人类可读排版，不暴露 Markdown 原文。
- 普通用户界面弱化 Markdown / MD / 标记文本概念。
- 保留内部 Markdown 生成能力，服务复制给 AI 和后续高级导出。

#### Expected User-visible Result

用户可以一键把今天的材料粘贴到自己选择的 AI 工具，也可以保存 PDF 归档和分享。

#### Files / Modules

- `Sources/DayleafApp`
- `Sources/DayleafCore`
- `Sources/DayleafApp`
- `Sources/DayleafCore`
- `Sources/DayleafCoreCheck`
- `scripts/package_app.sh`
- `docs/release_note.md`

#### Acceptance Criteria

- 主界面右上角是“复制给 AI”。
- 复制内容包含概览、时间线和温暖型提示。
- 设置中可以保存当天 PDF。
- PDF 文件名带日期，重复保存不会覆盖。
- 普通用户界面不再要求理解 Markdown。

#### Test Plan

- `swift build`
- `swift run DayleafCoreCheck`
- `./scripts/package_app.sh`
- 手动 QA 清单

#### Risks

- PDF 文本较多时需要避免截断。
- 如果未来进入 sandbox 分发，保存目录可能需要 security-scoped bookmark。

### Phase 4: v0.5 - Better History Review Without Built-in AI

#### Goal

增强历史回看和导出前确认体验，但仍不直接接入 AI API。

#### Scope

- 历史日期查看，不只看今天。
- 导出前预览当天内容。
- 可选导出富文本或图片。
- 更完整的手动 QA 清单，覆盖复制、PDF、历史回看、主题和删除确认。

#### Expected User-visible Result

用户可以在应用内回看某一天，并在导出或复制前确认材料。

#### Acceptance Criteria

- 用户可以切换日期查看历史记录。
- 导出前可以确认当天内容。
- 历史回看不破坏今天记录的轻量入口。

#### Risks

- 历史查看容易把菜单栏弹窗变复杂，需要保持轻量，不做大而全仪表盘。
- 富文本 / 图片导出是加分项，不应阻塞 v0.5 核心能力。

### Phase 5: v0.6 - User-triggered AI Daily Summary

#### Goal

在记录链路稳定后，接入用户主动触发的 AI 日记整理。先做“整理日记”，不做长期画像和完整朋友式对话。

#### Scope

- OpenAI 兼容接口配置：`base_url`、`api_key`、`model`。
- API key 存入 Keychain，不写入明文配置。
- 测试连接。
- 用户主动点击生成 AI 日记整理。
- 输出时引用当天具体记录，避免编造用户经历。
- 保存 AI 整理结果，作为后续长期画像的干净语料。

#### Expected User-visible Result

用户点击一次，就能得到基于当天记录的温暖型日记整理。

#### Acceptance Criteria

- 没有 API key 时，应用仍能完整记录和导出。
- AI 只在用户主动触发时调用。
- 结果能指出引用了哪些当天记录。
- 调用失败有可读错误，不影响本地记录数据。

#### Risks

- AI 输出容易泛化成“正能量复读机”，必须依赖具体记录约束。
- API key、网络错误、模型兼容性和隐私说明需要做扎实。

### Phase 6: v0.7+ - Long-term Profile and Friend-like Response

#### Goal

在用户有连续记录、AI 整理质量稳定后，再探索长期画像和朋友式回应。

#### Scope

- 长期画像：压力源、情绪模式、重要人物、长期目标。
- 画像更新策略：增量更新或定期重算。
- 基于当天记录 + 长期画像的朋友式回应。
- 未命中记录时的诚实话术，不编造。
- 情绪风险兜底。

#### Expected User-visible Result

AI 不只是总结今天，而是能基于长期上下文做更贴近用户的回应。

#### Go / No-go Gate

只有在以下条件满足后才进入：

- 用户已经连续使用并积累足够记录。
- v0.6 的日记整理质量稳定。
- 已有明确的隐私说明和情绪边界策略。
- 长期画像能解释“从哪些记录得出”，不能是不可追溯的黑箱结论。

#### Risks

- 数据稀疏时，长期画像会放大幻觉风险。
- 情绪陪伴不能冒充心理咨询。
- 功能过重会破坏“安静、轻量、克制”的产品人格。

## 6. Parallelizable Work

- Core 测试和 UI 细节可分开做。
- 文档更新可与代码开发并行。
- 签名/公证、全局快捷键、历史查看可以拆开推进。
- AI 调用层和 AI 日记结果渲染可以在 v0.6 内拆开推进。

## 7. Review Gates

- dependency check: Swift toolchain exists.
- typecheck/build: `swift build`
- automated checks: `swift run DayleafCoreCheck`
- unit tests: `swift test` 当前 Command Line Tools 环境没有可用 XCTest，暂不可用。
- lint: 当前无 SwiftLint，记录为 unavailable。
- manual smoke test: `swift run Dayleaf`。
- independent review: 更新 `docs/review_report.md`。
- packaged app smoke test: 打包后从 `dist/` 安装并运行。
- release readiness: 更新 `docs/release_audit.md`。

## 8. Rollback Strategy

Swift Package 新增文件相对独立。如原型不可用，可保留 `DayleafCore` 和测试，移除或替换 `DayleafApp`。

AI 阶段必须可关闭。即使 AI 配置损坏、网络不可用或模型调用失败，本地记录、时间线、复制给 AI 和 PDF 保存也必须继续可用。

## 9. Open Questions

- 是否继续用 Swift Package 手工打包，还是迁移为标准 macOS App 工程。
- 全局快捷键默认行为：打开弹窗、聚焦快速记录，还是直接弹出独立记录框。
- 历史查看是在菜单栏弹窗内完成，还是增加独立窗口。
- AI 日记整理结果保存为本地结构化数据、富文本文件，还是两者都保留。
- 长期画像采用增量更新还是定期重算。

## 10. Change Log

- 2026-06-13: Created V1 development plan.
- 2026-06-13: Updated verification gates to use `DayleafCoreCheck` because XCTest is unavailable in the current Command Line Tools environment.
- 2026-06-13: Removed prototype notification scope after UI smoke feedback showed the Swift Package app can crash when ending a focus session.
- 2026-06-13: Updated export requirements for 一日一笺 Chinese Markdown and warm friend-style AI prompt.
- 2026-06-14: Integrated post-v0.3 roadmap. Prioritized reliable daily capture before AI, then staged AI daily summary before long-term profile.
- 2026-06-17: Adjusted v0.4 scope to match release: copy to AI and PDF save shipped before built-in AI.
