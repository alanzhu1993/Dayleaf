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

    @MainActor
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

    @MainActor
    func export(
        journal: DailyJournal,
        settings: DayleafSettings,
        fileManager: FileManager = .default
    ) throws -> PDFDailyExportResult {
        let directoryURL = settings.resolvedExportDirectoryURL(fileManager: fileManager)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let baseName = "\(dateFormatter.string(from: journal.date))-今日一笺"
        let fileURL = ExportFileNamer.availableFileURL(
            in: directoryURL,
            baseName: baseName,
            fileExtension: "pdf",
            fileManager: fileManager
        )

        let view = JournalPDFView(journal: journal, timeZone: timeZone)
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

private final class JournalPDFView: NSView {
    private struct PDFLine {
        var text: String
        var font: NSFont
        var color: NSColor
        var bottomGap: CGFloat
    }

    private static let pageWidth: CGFloat = 595
    private static let minimumPageHeight: CGFloat = 842
    private static let horizontalInset: CGFloat = 52
    private static let topInset: CGFloat = 44
    private static let bottomInset: CGFloat = 44

    private let journal: DailyJournal
    private let timeZone: TimeZone

    override var isFlipped: Bool { true }

    init(journal: DailyJournal, timeZone: TimeZone) {
        self.journal = journal
        self.timeZone = timeZone
        super.init(frame: CGRect(x: 0, y: 0, width: Self.pageWidth, height: Self.minimumPageHeight))
        setFrameSize(CGSize(width: Self.pageWidth, height: measuredContentHeight()))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        bounds.fill()

        var y = Self.topInset
        for line in pdfLines() {
            draw(line, at: &y)
        }
    }

    private func pdfLines() -> [PDFLine] {
        [
            PDFLine(text: journal.title, font: .systemFont(ofSize: 28, weight: .semibold), color: .black, bottomGap: 8),
            PDFLine(text: dateFormatter.string(from: journal.date), font: .systemFont(ofSize: 13), color: .darkGray, bottomGap: 24),
            PDFLine(text: journal.content, font: .systemFont(ofSize: 13), color: .black, bottomGap: 22),
            PDFLine(text: "由 \(journal.modelName) 于 \(timestampFormatter.string(from: journal.generatedAt)) 生成", font: .systemFont(ofSize: 10), color: .darkGray, bottomGap: 4)
        ]
    }

    private func measuredContentHeight() -> CGFloat {
        let contentHeight = pdfLines().reduce(Self.topInset + Self.bottomInset) { partial, line in
            partial + measuredTextHeight(for: line) + line.bottomGap
        }
        return max(Self.minimumPageHeight, ceil(contentHeight))
    }

    private func draw(_ line: PDFLine, at y: inout CGFloat) {
        let height = measuredTextHeight(for: line)
        let rect = CGRect(x: Self.horizontalInset, y: y, width: textWidth, height: height)
        (line.text as NSString).draw(
            with: rect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes(for: line)
        )
        y += height + line.bottomGap
    }

    private func measuredTextHeight(for line: PDFLine) -> CGFloat {
        let rect = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        return ceil((line.text as NSString).boundingRect(
            with: rect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes(for: line)
        ).height)
    }

    private func attributes(for line: PDFLine) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 4
        return [
            .font: line.font,
            .foregroundColor: line.color,
            .paragraphStyle: paragraph
        ]
    }

    private var textWidth: CGFloat {
        bounds.width - Self.horizontalInset * 2
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private var timestampFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = timeZone
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        return formatter
    }
}

private final class DailyPDFView: NSView {
    private struct PDFLine {
        var text: String
        var font: NSFont
        var color: NSColor
        var bottomGap: CGFloat
    }

    private static let pageWidth: CGFloat = 595
    private static let minimumPageHeight: CGFloat = 842
    private static let horizontalInset: CGFloat = 52
    private static let topInset: CGFloat = 44
    private static let bottomInset: CGFloat = 44

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
        super.init(frame: CGRect(x: 0, y: 0, width: Self.pageWidth, height: Self.minimumPageHeight))
        setFrameSize(CGSize(width: Self.pageWidth, height: measuredContentHeight()))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        bounds.fill()

        var y = Self.topInset
        for line in pdfLines() {
            draw(line, at: &y)
        }
    }

    private func pdfLines() -> [PDFLine] {
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

        var lines: [PDFLine] = [
            PDFLine(text: "一日一笺", font: .systemFont(ofSize: 28, weight: .semibold), color: .black, bottomGap: 8),
            PDFLine(text: dateFormatter.string(from: date), font: .systemFont(ofSize: 13), color: .darkGray, bottomGap: 24),
            PDFLine(text: "概览", font: .systemFont(ofSize: 17, weight: .semibold), color: .black, bottomGap: 10),
            PDFLine(text: "专注记录：\(focusSessions.count)", font: .systemFont(ofSize: 12), color: .black, bottomGap: 5),
            PDFLine(text: "快速记录：\(quickNotes.count)", font: .systemFont(ofSize: 12), color: .black, bottomGap: 5),
            PDFLine(text: "总专注时长：\(MarkdownExporter.durationText(totalFocusSeconds))", font: .systemFont(ofSize: 12), color: .black, bottomGap: 22),
            PDFLine(text: "时间线", font: .systemFont(ofSize: 17, weight: .semibold), color: .black, bottomGap: 12)
        ]

        if entries.isEmpty {
            lines.append(PDFLine(text: "今日暂无记录", font: .systemFont(ofSize: 12), color: .darkGray, bottomGap: 8))
        } else {
            for entry in entries {
                lines.append(PDFLine(text: entryTitle(entry), font: .systemFont(ofSize: 12, weight: .semibold), color: .black, bottomGap: 4))
                lines.append(PDFLine(text: entryDetail(entry), font: .systemFont(ofSize: 11), color: .darkGray, bottomGap: 14))
            }
        }

        return lines
    }

    private func measuredContentHeight() -> CGFloat {
        let contentHeight = pdfLines().reduce(Self.topInset + Self.bottomInset) { partial, line in
            partial + measuredTextHeight(for: line) + line.bottomGap
        }
        return max(Self.minimumPageHeight, ceil(contentHeight))
    }

    private func draw(_ line: PDFLine, at y: inout CGFloat) {
        let height = measuredTextHeight(for: line)
        let rect = CGRect(x: Self.horizontalInset, y: y, width: textWidth, height: height)
        (line.text as NSString).draw(
            with: rect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes(for: line)
        )
        y += height + line.bottomGap
    }

    private func measuredTextHeight(for line: PDFLine) -> CGFloat {
        let rect = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        return ceil((line.text as NSString).boundingRect(
            with: rect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes(for: line)
        ).height)
    }

    private func attributes(for line: PDFLine) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        return [
            .font: line.font,
            .foregroundColor: line.color,
            .paragraphStyle: paragraph
        ]
    }

    private var textWidth: CGFloat {
        bounds.width - Self.horizontalInset * 2
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
