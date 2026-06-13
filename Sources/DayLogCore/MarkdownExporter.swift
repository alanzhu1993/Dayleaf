import Foundation

public struct MarkdownExportResult: Equatable, Sendable {
    public var fileURL: URL
    public var markdown: String
}

public struct MarkdownExporter: Sendable {
    private var calendar: Calendar
    private var timeZone: TimeZone

    public init(calendar: Calendar = .current, timeZone: TimeZone = .current) {
        var calendar = calendar
        calendar.timeZone = timeZone
        self.calendar = calendar
        self.timeZone = timeZone
    }

    public func markdown(for date: Date, database: DayLogDatabase, exportedAt: Date = Date()) -> String {
        let entries = database.entries(on: date, calendar: calendar)
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

        var lines: [String] = [
            "# \(dayFormatter.string(from: date)) 一日一笺",
            "",
            "## 概览",
            "",
            "- 日期：\(dateFormatter.string(from: date))",
            "- 导出时间：\(timestampFormatter.string(from: exportedAt))",
            "- 专注记录：\(focusSessions.count)",
            "- 快速记录：\(quickNotes.count)",
            "- 总专注时长：\(Self.durationText(totalFocusSeconds))",
            "",
            "## 时间线",
            "",
            "| 时间 | 时间戳 | 类型 | 内容 | 时长 |",
            "|---|---|---|---|---|"
        ]

        if entries.isEmpty {
            lines.append("| - | - | - | 今日暂无记录 | - |")
        } else {
            for entry in entries {
                lines.append(markdownRow(for: entry, exportedAt: exportedAt))
            }
        }

        lines.append(contentsOf: [
            "",
            "## 给 AI 的提示",
            "",
            "请像一位真诚、温和的朋友一样阅读这份一天记录。先用几句话概括我今天经历了什么，不要只做冷冰冰的数据分析。看到我完成的事、投入的注意力、可能的疲惫或被打断，也请温柔地指出来。请给我一段有温度的回应，让我感觉这一天被认真看见。最后给出 2-3 条明天可以尝试的小建议，要求具体、轻量、可执行，不要说教。",
            ""
        ])

        return lines.joined(separator: "\n")
    }

    public func export(
        date: Date,
        database: DayLogDatabase,
        settings: DayLogSettings,
        exportedAt: Date = Date(),
        fileManager: FileManager = .default
    ) throws -> MarkdownExportResult {
        let directoryURL = settings.resolvedExportDirectoryURL(fileManager: fileManager)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let baseName = "\(dateFormatter.string(from: date))-一日一笺"
        let fileURL = availableFileURL(in: directoryURL, baseName: baseName, extension: "md", fileManager: fileManager)
        let markdown = markdown(for: date, database: database, exportedAt: exportedAt)
        try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
        return MarkdownExportResult(fileURL: fileURL, markdown: markdown)
    }

    private func markdownRow(for entry: DayEntry, exportedAt: Date) -> String {
        switch entry {
        case .focusSession(let session):
            let content = session.actualActivity.nilIfBlank
                ?? session.plannedActivity
                ?? "未命名专注"
            return "| \(timeFormatter.string(from: session.startedAt)) | \(timestampFormatter.string(from: session.startedAt)) | 专注 | \(Self.escapeTable(content)) | \(Self.durationText(session.activeDuration(until: exportedAt))) |"
        case .quickNote(let note):
            return "| \(timeFormatter.string(from: note.occurredAt)) | \(timestampFormatter.string(from: note.occurredAt)) | 记录 | \(Self.escapeTable(note.content)) | - |"
        }
    }

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

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private var dayFormatter: DateFormatter {
        dateFormatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
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

    public static func durationText(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let remainingSeconds = clamped % 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)小时\(minutes)分钟" : "\(hours)小时"
        }
        if minutes > 0 {
            return "\(minutes)分钟"
        }
        return "\(remainingSeconds)秒"
    }

    public static func escapeTable(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "|", with: "\\|")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
