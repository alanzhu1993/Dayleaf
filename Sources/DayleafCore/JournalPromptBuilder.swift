import Foundation

public struct JournalPrompt: Equatable, Sendable {
    public var system: String
    public var user: String
    public var sourceEntryIDs: [UUID]

    public init(system: String, user: String, sourceEntryIDs: [UUID]) {
        self.system = system
        self.user = user
        self.sourceEntryIDs = sourceEntryIDs
    }
}

public struct JournalPromptBuilder: Sendable {
    private var calendar: Calendar
    private var timeZone: TimeZone

    public init(calendar: Calendar = .current, timeZone: TimeZone = .current) {
        var calendar = calendar
        calendar.timeZone = timeZone
        self.calendar = calendar
        self.timeZone = timeZone
    }

    public func prompt(for date: Date, database: DayleafDatabase, generatedAt: Date = Date()) -> JournalPrompt? {
        let entries = database.entries(on: date, calendar: calendar)
        guard entries.isEmpty == false else {
            return nil
        }

        return JournalPrompt(
            system: systemPrompt,
            user: userPrompt(for: date, entries: entries, generatedAt: generatedAt),
            sourceEntryIDs: entries.map(\.id)
        )
    }

    private var systemPrompt: String {
        """
        你是一位克制、温暖、诚实的日记整理助手。你的任务不是评价用户，而是把用户当天的碎片记录整理成一篇用户可以直接保存的第一人称中文日记。

        必须遵守：
        - 默认使用第一人称“我”。
        - 写成自然日记正文，不要写成分析报告。
        - 只根据用户提供的当天记录写事实。
        - 不要扩写记录里没有出现的动作、人物、地点、对话、原因或心理活动。
        - 记录很少时就写短，不要为了凑字数而发挥。
        - 可以把零散句子连接顺畅，但不要添加新的情节。
        - 可以温和描述情绪，但不能做心理诊断。
        - 不能做性格判断、人格画像或长期结论。
        - 不要强行正能量，不要说教。
        - 只有记录中明确出现情绪词时才写情绪；如果只是推测，最多用一句“我可能有点...”。
        - 不要编造记录里没有的人、地点、事件或原因。
        - 直接输出日记正文，不要输出标题、列表、Markdown 标记或解释。
        """
    }

    private func userPrompt(for date: Date, entries: [DayEntry], generatedAt: Date) -> String {
        var lines: [String] = [
            "请把下面这些记录整理成一篇第一人称日记。",
            "",
            "日期：\(dateFormatter.string(from: date))",
            "整理时间：\(timestampFormatter.string(from: generatedAt))",
            "",
            "写作要求：",
            "- 开头像真实日记，不要像报告。",
            "- 尽量使用原记录里的词，不要替换成更戏剧化的表达。",
            "- 保留具体事件和细节，但不要添加新细节。",
            "- 不要补充记录里没有的背景、动机、人物关系或心理活动。",
            "- 情绪表达要轻；没有明确依据时，不要写情绪。",
            "- 结尾最多一句轻量的自我提醒，仍然使用第一人称。",
            "- 长度按记录多少决定：1-2 条记录写 80-180 字；3-6 条记录写 180-350 字；更多记录最多 500 字。",
            "",
            "当天记录："
        ]

        for entry in entries {
            lines.append(recordLine(for: entry, generatedAt: generatedAt))
        }

        return lines.joined(separator: "\n")
    }

    private func recordLine(for entry: DayEntry, generatedAt: Date) -> String {
        switch entry {
        case .focusSession(let session):
            let start = timeFormatter.string(from: session.startedAt)
            let end = timeFormatter.string(from: session.endedAt ?? generatedAt)
            let content = session.actualActivity.nilIfBlank
                ?? session.plannedActivity
                ?? "未命名专注"
            let planned = session.plannedActivity?.nilIfBlank.map { "，计划：\($0)" } ?? ""
            return "- [专注] \(start)-\(end)，有效 \(MarkdownExporter.durationText(session.activeDuration(until: generatedAt)))\(planned)，实际：\(content)"
        case .quickNote(let note):
            return "- [记录] \(timeFormatter.string(from: note.occurredAt))，\(note.content)"
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
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
}
