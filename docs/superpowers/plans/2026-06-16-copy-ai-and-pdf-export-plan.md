# Copy AI and PDF Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把普通用户主路径改为“复制给 AI”，并在设置页增加“保存为 PDF”，让 Markdown 退回内部结构化格式。

**Architecture:** 复用现有 `MarkdownExporter.markdown(...)` 生成 AI 友好文本，新增 view model 剪贴板入口。PDF 在 App target 中用轻量 AppKit `NSView.dataWithPDF(inside:)` 渲染，文件命名复用 Core target 中抽出的防覆盖命名工具。现有 `.md` 写文件能力保留在内部，不进入普通用户 UI。

**Tech Stack:** Swift 6、SwiftUI、AppKit、DayleafCore、现有 `DayleafCoreCheck` 可执行校验。

---

## 文件结构

- 修改 `Sources/DayleafCore/MarkdownExporter.swift`
  - 保留 Markdown 字符串生成。
  - 把 `.md` 文件防覆盖逻辑改为复用新的 `ExportFileNamer`。
- 新增 `Sources/DayleafCore/ExportFileNamer.swift`
  - Core 层通用文件命名工具：给定目录、基础文件名、扩展名，返回不会覆盖已有文件的 URL。
  - 同时服务现有 Markdown 文件导出和新的 PDF 导出。
- 修改 `Sources/DayleafCoreCheck/main.swift`
  - 增加防覆盖文件命名检查。
  - 继续检查 Markdown 内容和现有存储逻辑。
- 修改 `Sources/DayleafApp/DayleafViewModel.swift`
  - 新增 `copyTodayForAI()`，写入系统剪贴板。
  - 新增 `saveTodayPDF()`，调用 PDF exporter。
  - 调整导出目录面板文案，不再出现“标记文本”。
- 新增 `Sources/DayleafApp/PDFDailyExporter.swift`
  - App 层 PDF 渲染和保存。
  - 直接基于当天 `DayEntry` 绘制人类可读内容，不输出 Markdown 原文。
- 修改 `Sources/DayleafApp/MenuBarRootView.swift`
  - 顶部按钮从“导出今天”改成“复制给 AI”。
  - 设置 popover 增加“保存为 PDF”按钮。
  - toast 规则识别 PDF 保存失败。
  - 设置文案去掉“标记文本”。
- 修改 `Sources/DayleafApp/SettingsView.swift`
  - macOS Settings 窗口同步增加“保存为 PDF”按钮。
  - 设置文案去掉“标记文本”。

---

### Task 1: 抽出防覆盖文件命名工具并补 Core 校验

**Files:**
- Create: `Sources/DayleafCore/ExportFileNamer.swift`
- Modify: `Sources/DayleafCore/MarkdownExporter.swift`
- Modify: `Sources/DayleafCoreCheck/main.swift`

- [ ] **Step 1: 写失败校验**

在 `Sources/DayleafCoreCheck/main.swift` 的 `main()` 中，把新检查插到 Markdown 检查之后：

```swift
@main
struct DayleafCoreCheck {
    static func main() throws {
        try checkFocusDurationExcludesPausedIntervals()
        try checkEntriesAreFilteredAndSorted()
        try checkMarkdownExportUsesConfiguredDirectory()
        try checkExportFileNamerAvoidsOverwrites()
        try checkJSONStoreRoundTrip()
        print("DayleafCoreCheck passed")
    }
```

在 `checkMarkdownExportUsesConfiguredDirectory()` 后面新增函数：

```swift
    private static func checkExportFileNamerAvoidsOverwrites() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

        let firstURL = ExportFileNamer.availableFileURL(
            in: temporaryDirectory,
            baseName: "2026-06-16-一日一笺",
            fileExtension: "pdf"
        )
        try expect(firstURL.lastPathComponent == "2026-06-16-一日一笺.pdf", "first PDF export should use base name")

        try Data().write(to: firstURL)

        let secondURL = ExportFileNamer.availableFileURL(
            in: temporaryDirectory,
            baseName: "2026-06-16-一日一笺",
            fileExtension: "pdf"
        )
        try expect(secondURL.lastPathComponent == "2026-06-16-一日一笺-2.pdf", "second PDF export should avoid overwriting")
    }
```

- [ ] **Step 2: 运行校验确认失败**

Run:

```bash
swift run DayleafCoreCheck
```

Expected: 编译失败，提示 `cannot find 'ExportFileNamer' in scope`。

- [ ] **Step 3: 新增最小实现**

新增 `Sources/DayleafCore/ExportFileNamer.swift`：

```swift
import Foundation

public enum ExportFileNamer {
    public static func availableFileURL(
        in directoryURL: URL,
        baseName: String,
        fileExtension: String,
        fileManager: FileManager = .default
    ) -> URL {
        var candidate = directoryURL.appendingPathComponent("\(baseName).\(fileExtension)")
        var suffix = 2
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directoryURL.appendingPathComponent("\(baseName)-\(suffix).\(fileExtension)")
            suffix += 1
        }
        return candidate
    }
}
```

修改 `Sources/DayleafCore/MarkdownExporter.swift` 的 `export(...)`，替换文件 URL 生成：

```swift
        let baseName = "\(dateFormatter.string(from: date))-一日一笺"
        let fileURL = ExportFileNamer.availableFileURL(
            in: directoryURL,
            baseName: baseName,
            fileExtension: "md",
            fileManager: fileManager
        )
        let markdown = markdown(for: date, database: database, exportedAt: exportedAt)
```

删除 `MarkdownExporter` 里的私有 `availableFileURL(...)` 方法整段：

```swift
    private func availableFileURL(
        in directoryURL: URL,
        baseName: String,
        extension fileExtension: String,
        fileManager: FileManager
    ) -> URL {
        var candidate = directoryURL.appendingPathComponent("\(baseName).\(fileExtension)")
        var suffix = 2
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directoryURL.appendingPathComponent("\(baseName)-\(suffix).\(fileExtension)")
            suffix += 1
        }
        return candidate
    }
```

- [ ] **Step 4: 运行校验确认通过**

Run:

```bash
swift run DayleafCoreCheck
```

Expected: 输出 `DayleafCoreCheck passed`。

- [ ] **Step 5: 提交**

```bash
git add Sources/DayleafCore/ExportFileNamer.swift Sources/DayleafCore/MarkdownExporter.swift Sources/DayleafCoreCheck/main.swift
git commit -m "Extract export file naming helper"
```

---

### Task 2: 增加“复制给 AI”应用逻辑和主按钮

**Files:**
- Modify: `Sources/DayleafApp/DayleafViewModel.swift`
- Modify: `Sources/DayleafApp/MenuBarRootView.swift`

- [ ] **Step 1: 新增 view model 剪贴板方法**

在 `DayleafViewModel` 中，用下面方法替换或放在现有 `exportToday()` 附近：

```swift
    func copyTodayForAI() {
        let exportDatabase = databaseWithRefreshedActiveDuration()
        let markdown = exporter.markdown(for: now, database: exportDatabase, exportedAt: now)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if pasteboard.setString(markdown, forType: .string) {
            statusMessage = "已复制给 AI"
        } else {
            statusMessage = "复制失败：无法写入剪贴板"
        }
    }
```

保留 `exportToday()`，但后续 UI 不再把它作为普通用户主入口。

- [ ] **Step 2: 改主界面按钮**

在 `Sources/DayleafApp/MenuBarRootView.swift` 的 `header` 中，把按钮 action 和文案改成：

```swift
            Button {
                viewModel.copyTodayForAI()
                presentToast(viewModel.statusMessage)
            } label: {
                Image(systemName: "doc.on.clipboard")
            }
            .buttonStyle(IconButtonStyle())
            .help("复制今天的记录给 AI")
            .accessibilityLabel("复制给 AI")
```

- [ ] **Step 3: 调整 toast 规则**

在 `toastContent(for:)` 中，把错误标记补上“无法”：

```swift
        let errorMarkers = ["失败", "不能", "需要", "先写", "已有", "无法"]
        let isError = errorMarkers.contains { message.contains($0) }
        let text = message.hasPrefix("已导出") ? "已导出" : message
        return (text, isError)
```

- [ ] **Step 4: 编译验证**

Run:

```bash
swift build
```

Expected: build 成功。

- [ ] **Step 5: 手动剪贴板验证**

Run app:

```bash
swift run Dayleaf
```

Manual expected:

- 菜单栏弹窗右上角图标变为剪贴板语义。
- 悬浮提示为“复制今天的记录给 AI”。
- 点击后 toast 显示“已复制给 AI”。
- 在任意文本输入处粘贴，内容包含 `# YYYY-MM-DD 一日一笺`、`## 概览`、`## 时间线`、`## 给人工智能的提示`。

- [ ] **Step 6: 提交**

```bash
git add Sources/DayleafApp/DayleafViewModel.swift Sources/DayleafApp/MenuBarRootView.swift
git commit -m "Add copy to AI action"
```

---

### Task 3: 新增 PDF 导出器

**Files:**
- Create: `Sources/DayleafApp/PDFDailyExporter.swift`
- Modify: `Sources/DayleafApp/DayleafViewModel.swift`

- [ ] **Step 1: 新增 PDF exporter**

创建 `Sources/DayleafApp/PDFDailyExporter.swift`：

```swift
import AppKit
import DayleafCore
import Foundation

struct PDFDailyExportResult: Equatable {
    var fileURL: URL
}

struct PDFDailyExporter {
    private var calendar: Calendar
    private var timeZone: TimeZone

    init(calendar: Calendar = .current, timeZone: TimeZone = .current) {
        var calendar = calendar
        calendar.timeZone = timeZone
        self.calendar = calendar
        self.timeZone = timeZone
    }

    func export(
        date: Date,
        database: DayleafDatabase,
        settings: DayleafSettings,
        exportedAt: Date = Date(),
        fileManager: FileManager = .default
    ) throws -> PDFDailyExportResult {
        let directoryURL = settings.resolvedExportDirectoryURL(fileManager: fileManager)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let baseName = "\(dateFormatter.string(from: date))-一日一笺"
        let fileURL = ExportFileNamer.availableFileURL(
            in: directoryURL,
            baseName: baseName,
            fileExtension: "pdf",
            fileManager: fileManager
        )

        let view = DailyPDFView(
            date: date,
            exportedAt: exportedAt,
            entries: database.entries(on: date, calendar: calendar),
            timeZone: timeZone
        )
        let data = view.dataWithPDF(inside: view.bounds)
        try data.write(to: fileURL, options: .atomic)
        return PDFDailyExportResult(fileURL: fileURL)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}

private final class DailyPDFView: NSView {
    private let date: Date
    private let exportedAt: Date
    private let entries: [DayEntry]
    private let timeZone: TimeZone

    override var isFlipped: Bool { true }

    init(date: Date, exportedAt: Date, entries: [DayEntry], timeZone: TimeZone) {
        self.date = date
        self.exportedAt = exportedAt
        self.entries = entries
        self.timeZone = timeZone
        let height = max(842, 260 + entries.count * 52)
        super.init(frame: CGRect(x: 0, y: 0, width: 595, height: height))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        bounds.fill()

        var y: CGFloat = 44
        draw("一日一笺", at: &y, font: .systemFont(ofSize: 28, weight: .semibold), color: .black, bottomGap: 8)
        draw(dateFormatter.string(from: date), at: &y, font: .systemFont(ofSize: 13), color: .darkGray, bottomGap: 24)

        draw("概览", at: &y, font: .systemFont(ofSize: 17, weight: .semibold), color: .black, bottomGap: 10)
        let focusSessions = entries.compactMap { entry -> FocusSession? in
            if case .focusSession(let session) = entry { return session }
            return nil
        }
        let quickNotes = entries.compactMap { entry -> QuickNote? in
            if case .quickNote(let note) = entry { return note }
            return nil
        }
        let totalFocusSeconds = focusSessions.reduce(0) { partial, session in
            partial + session.activeDuration(until: exportedAt)
        }

        draw("专注记录：\(focusSessions.count)", at: &y, font: .systemFont(ofSize: 12), color: .black, bottomGap: 5)
        draw("快速记录：\(quickNotes.count)", at: &y, font: .systemFont(ofSize: 12), color: .black, bottomGap: 5)
        draw("总专注时长：\(MarkdownExporter.durationText(totalFocusSeconds))", at: &y, font: .systemFont(ofSize: 12), color: .black, bottomGap: 22)

        draw("时间线", at: &y, font: .systemFont(ofSize: 17, weight: .semibold), color: .black, bottomGap: 12)
        if entries.isEmpty {
            draw("今日暂无记录", at: &y, font: .systemFont(ofSize: 12), color: .darkGray, bottomGap: 8)
        } else {
            for entry in entries {
                draw(entryTitle(entry), at: &y, font: .systemFont(ofSize: 12, weight: .semibold), color: .black, bottomGap: 4)
                draw(entryDetail(entry), at: &y, font: .systemFont(ofSize: 11), color: .darkGray, bottomGap: 14)
            }
        }
    }

    private func draw(_ text: String, at y: inout CGFloat, font: NSFont, color: NSColor, bottomGap: CGFloat) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let rect = CGRect(x: 52, y: y, width: bounds.width - 104, height: 1_000)
        let height = ceil((text as NSString).boundingRect(
            with: rect.size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        ).height)
        (text as NSString).draw(with: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes)
        y += height + bottomGap
    }

    private func entryTitle(_ entry: DayEntry) -> String {
        switch entry {
        case .focusSession(let session):
            let actual = session.actualActivity.trimmingCharacters(in: .whitespacesAndNewlines)
            let content = actual.isEmpty ? (session.plannedActivity ?? "未命名专注") : actual
            return "\(timeFormatter.string(from: session.startedAt)) · 专注 · \(MarkdownExporter.durationText(session.activeDuration(until: exportedAt))) · \(content)"
        case .quickNote(let note):
            return "\(timeFormatter.string(from: note.occurredAt)) · 记录"
        }
    }

    private func entryDetail(_ entry: DayEntry) -> String {
        switch entry {
        case .focusSession(let session):
            return timestampFormatter.string(from: session.startedAt)
        case .quickNote(let note):
            return "\(timestampFormatter.string(from: note.occurredAt)) · \(note.content)"
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    private var timestampFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = timeZone
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        return formatter
    }
}
```

- [ ] **Step 2: 接入 view model**

在 `DayleafViewModel` 增加属性：

```swift
    private let pdfExporter: PDFDailyExporter
```

调整 initializer：

```swift
    init(
        store: JSONDayleafStore = .live(),
        exporter: MarkdownExporter = MarkdownExporter(),
        pdfExporter: PDFDailyExporter = PDFDailyExporter()
    ) {
        self.store = store
        self.exporter = exporter
        self.pdfExporter = pdfExporter
        load()
        startTicker()
    }
```

在 `exportToday()` 附近新增：

```swift
    func saveTodayPDF() {
        do {
            let exportDatabase = databaseWithRefreshedActiveDuration()
            _ = try pdfExporter.export(date: now, database: exportDatabase, settings: settings, exportedAt: now)
            statusMessage = "PDF 已保存"
        } catch {
            statusMessage = "PDF 保存失败：\(error.localizedDescription)"
        }
    }
```

- [ ] **Step 3: 编译验证**

Run:

```bash
swift build
```

Expected: build 成功。`DayleafViewModel` 是 `@MainActor`，PDF 保存从主线程触发。

- [ ] **Step 4: 提交**

```bash
git add Sources/DayleafApp/PDFDailyExporter.swift Sources/DayleafApp/DayleafViewModel.swift
git commit -m "Add PDF daily exporter"
```

---

### Task 4: 在设置入口接入 PDF，并去掉普通用户界面的 Markdown 文案

**Files:**
- Modify: `Sources/DayleafApp/MenuBarRootView.swift`
- Modify: `Sources/DayleafApp/SettingsView.swift`
- Modify: `Sources/DayleafApp/DayleafViewModel.swift`

- [ ] **Step 1: 更新目录选择面板文案**

在 `DayleafViewModel.chooseExportDirectory()` 中把 panel message 改成：

```swift
        panel.message = "选择一日一笺 PDF 的保存目录"
```

- [ ] **Step 2: 更新菜单弹窗设置面板**

在 `MenuBarRootView.swift` 的 `SettingsPanel` 中，把导出目录区块改成竖排按钮，避免 300 宽 popover 中中文按钮拥挤：

```swift
            VStack(alignment: .leading, spacing: 7) {
                Text("保存目录")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
                Text(viewModel.exportDirectoryDisplay)
                    .font(.callout)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .tile(radius: DS.controlRadius)
                VStack(spacing: 8) {
                    Button {
                        viewModel.chooseExportDirectory()
                    } label: {
                        Label("选择目录…", systemImage: "folder")
                    }
                    .buttonStyle(NeutralButtonStyle())

                    Button {
                        viewModel.saveTodayPDF()
                    } label: {
                        Label("保存为 PDF", systemImage: "doc.richtext")
                    }
                    .buttonStyle(NeutralButtonStyle())
                }
                Text("需要归档时，可以把今天的记录保存成 PDF。")
                    .font(.caption2)
                    .foregroundStyle(Palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
```

- [ ] **Step 3: 更新系统 Settings 窗口**

在 `Sources/DayleafApp/SettingsView.swift` 的导出 Section 中，把按钮区改成：

```swift
                Button {
                    viewModel.chooseExportDirectory()
                } label: {
                    Label("选择目录", systemImage: "folder")
                }

                Button {
                    viewModel.saveTodayPDF()
                } label: {
                    Label("保存为 PDF", systemImage: "doc.richtext")
                }
```

把 footer 文案改成：

```swift
            } footer: {
                Text("需要归档时，可以把今天的记录保存成 PDF。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
```

- [ ] **Step 4: 更新 toast 错误标记**

在 `MenuBarRootView.toastContent(for:)` 中确认错误标记包含“失败”和“无法”：

```swift
        let errorMarkers = ["失败", "不能", "需要", "先写", "已有", "无法"]
```

- [ ] **Step 5: 搜索普通用户界面禁用词**

Run:

```bash
rg -n "标记文本|导出今天|导出今天为|Markdown|MD" Sources/DayleafApp
```

Expected:

- `Sources/DayleafApp` 中不再有面向普通用户 UI 的“标记文本”“导出今天为”“Markdown”“MD”。
- 如果命中 `PDFDailyExporter.swift` 的技术注释或代码名，不需要改。

- [ ] **Step 6: 编译验证**

Run:

```bash
swift build
```

Expected: build 成功。

- [ ] **Step 7: 提交**

```bash
git add Sources/DayleafApp/MenuBarRootView.swift Sources/DayleafApp/SettingsView.swift Sources/DayleafApp/DayleafViewModel.swift
git commit -m "Add PDF save action to settings"
```

---

### Task 5: 端到端验证与文档收口

**Files:**
- Inspect: `README.md`
- Inspect: `docs/product_spec.md`
- Inspect: `docs/change_log.md`
- Inspect: `Sources/DayleafApp`

- [ ] **Step 1: 跑核心校验**

Run:

```bash
swift run DayleafCoreCheck
```

Expected: 输出 `DayleafCoreCheck passed`。

- [ ] **Step 2: 跑构建**

Run:

```bash
swift build
```

Expected: build 成功。

- [ ] **Step 3: 手动运行应用**

Run:

```bash
swift run Dayleaf
```

Manual expected:

- 主界面右上角是复制给 AI 入口。
- 点击后 toast 显示“已复制给 AI”。
- 粘贴出来的文本仍然是结构化内容，包含概览、时间线和给 AI 的提示。
- 设置 popover 中出现“保存为 PDF”。
- 系统 Settings 窗口中也出现“保存为 PDF”。
- 设置文案不再让普通用户理解 Markdown 或标记文本。

- [ ] **Step 4: 验证 PDF 文件**

Manual expected:

- 点击“保存为 PDF”后 toast 显示“PDF 已保存”。
- 默认目录或已配置目录下生成 `YYYY-MM-DD-一日一笺.pdf`。
- 连续保存第二次生成 `YYYY-MM-DD-一日一笺-2.pdf`。
- PDF 能用 macOS Preview 打开。
- PDF 内容包含标题、日期、概览、时间线、总专注时长。
- PDF 不显示 `## 给人工智能的提示`，也不是 Markdown 原文。

- [ ] **Step 5: 搜索用户文案残留并记录结果**

Run:

```bash
rg -n "标记文本|导出 Markdown|导出今天为标记文本|Markdown 文件|MD 文档" README.md docs Sources/DayleafApp
```

Expected:

- `Sources/DayleafApp` 不再有普通用户会看到的 Markdown / 标记文本文案。
- `README.md`、`docs/product_spec.md`、`docs/change_log.md` 可能仍有历史或规划文字；本任务只把命中结果写入最终汇报，不直接修改这些文件，避免混入用户已有文档改动。

- [ ] **Step 6: 最终状态检查**

Run:

```bash
git status --short
```

Expected:

- 只出现本功能相关文件变更。
- 不要把用户已有的无关文档改动混入提交。

- [ ] **Step 7: 汇总验证结果**

最终汇报包含：

- `swift run DayleafCoreCheck` 的结果。
- `swift build` 的结果。
- 剪贴板手动验证结果。
- PDF 文件生成、打开、防覆盖结果。
- 文案搜索命中结果，以及哪些命中属于文档历史内容。

---

## 自检结果

- 规格覆盖：主入口复制给 AI、设置页保存 PDF、PDF 文件命名、错误提示、Markdown 不进入普通用户 UI、复制/PDF 前刷新专注时长都已映射到任务。
- 范围控制：不接 AI API，不做历史浏览器，不删除内部 Markdown 生成逻辑。
- 类型一致：计划中新增的 `copyTodayForAI()`、`saveTodayPDF()`、`PDFDailyExporter`、`ExportFileNamer.availableFileURL(...)` 在后续任务中保持同名。
- 验证路径：包含 `swift run DayleafCoreCheck`、`swift build`、剪贴板手动验证、PDF 打开和防覆盖验证、UI 文案搜索。
