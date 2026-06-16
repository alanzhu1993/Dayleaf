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
