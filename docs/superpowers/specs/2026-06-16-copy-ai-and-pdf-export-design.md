# 2026-06-16 Copy to AI and PDF Export Design

## Background

The current app exposes "export Markdown" as the primary end-of-day action. This is technically useful, but it asks regular users to understand a file format they may not recognize or know how to open.

The product should instead expose actions by user intent:

- Copy today's material into an AI tool.
- Save a human-readable record for archive, sharing, or printing.

Markdown can remain an internal structure for machine-readable content, but it should not be the main user-facing concept.

## Goals

- Replace the primary "export today" action with "copy to AI".
- Add a PDF save action for human-readable archive and sharing.
- Keep generated content consistent across copy and export paths.
- Avoid making regular users think about Markdown or `.md` files.
- Preserve the ability to evolve advanced file export later without blocking this change.

## Non-Goals

- Do not integrate with any AI API.
- Do not automatically send user records to third-party services.
- Do not build a full history browser in this change.
- Do not make PDF the source format for AI analysis.
- Do not remove existing Markdown generation internals unless implementation proves it unnecessary.

## User Experience

### Primary Action: Copy to AI

The main header action changes from "export today" to "copy to AI".

Behavior:

1. The user clicks the header button.
2. The app generates today's structured journal material.
3. The app writes that text to the system clipboard.
4. The app shows a short success toast: "已复制给 AI".

The copied text can remain Markdown because AI tools parse it well. The interface should describe the result by purpose, not by format.

Suggested labels:

- Tooltip: "复制今天的记录给 AI"
- Accessibility label: "复制给 AI"
- Success toast: "已复制给 AI"
- Failure toast: "复制失败：..."

### Secondary Action: Save as PDF

PDF export should live in Settings, next to the export directory controls.

Behavior:

1. The user chooses "保存为 PDF".
2. The app renders today's record into a readable PDF layout.
3. The app saves the PDF to the configured export directory.
4. The app shows a short success toast: "PDF 已保存".

The PDF is for people, not machines. It should look like a simple daily review: title, date, overview, timeline, and total focus duration. It should not include the AI prompt by default, and it should not look like raw Markdown source.

Suggested labels:

- Button: "保存为 PDF"
- Directory text: "需要归档时，可以把今天的记录保存成 PDF。"
- Success toast: "PDF 已保存"
- Failure toast: "PDF 保存失败：..."

### Markdown Role

Markdown remains an internal intermediate or advanced-compatible format.

User-facing UI should avoid:

- "MD"
- "Markdown"
- "标记文本"

Exception: developer docs, tests, or future advanced settings may still mention Markdown.

## Architecture

### Existing Components

- `MarkdownExporter.markdown(...)` already generates a complete text representation for one day.
- `MarkdownExporter.export(...)` writes that Markdown to a `.md` file.
- `DayleafViewModel.exportToday()` currently drives the header action.
- `MenuBarRootView.header` currently shows the export button.
- Settings already contains export directory controls.

### Proposed Components

#### Clipboard Copy

Add a view-model method such as `copyTodayForAI()`.

Responsibilities:

- Refresh any active focus duration before generating content.
- Generate today's structured text with the existing exporter.
- Write the string to `NSPasteboard.general`.
- Update `statusMessage`.

The method should not save files and should not require an export directory.

#### PDF Export

Add a PDF export path that produces a readable document.

Possible implementation options:

- Use AppKit print/PDF rendering from a lightweight native view.
- Generate an attributed text document and write it as PDF.
- Convert the structured daily data into a simple PDF renderer independent of SwiftUI.

The implementation plan should choose the smallest reliable macOS-native approach. The PDF renderer should share data with the copy path, but it does not need to share Markdown formatting.

#### Existing Markdown File Export

The old `.md` export should no longer be the primary action.

Keep the method available internally if it remains useful for copy generation, tests, or future advanced export. Do not expose Markdown file export in the regular user interface in this change.

## Data Flow

Copy to AI:

1. UI calls `copyTodayForAI()`.
2. View model refreshes active focus duration.
3. Markdown exporter generates structured AI-ready text.
4. View model writes to clipboard.
5. UI shows toast from `statusMessage`.

Save as PDF:

1. Settings UI calls a new PDF save method.
2. View model refreshes active focus duration.
3. PDF exporter receives today's entries and summary data.
4. PDF exporter writes a dated `.pdf` file.
5. View model updates `statusMessage`.
6. UI shows toast from `statusMessage`.

## File Naming

Generated user files must include the date.

PDF filename:

```text
YYYY-MM-DD-一日一笺.pdf
```

If the file already exists, append a numeric suffix:

```text
YYYY-MM-DD-一日一笺-2.pdf
```

This mirrors the current Markdown export behavior.

## Error Handling

Clipboard copy:

- If the app cannot write to the pasteboard, show "复制失败：...".
- Do not change local records.
- Do not require an export directory.

PDF export:

- If the target directory cannot be created or written, show "PDF 保存失败：...".
- If rendering fails, show "PDF 保存失败：...".
- Do not change local records.

## Testing And Verification

Automated checks should cover:

- AI copy content includes the same overview, timeline, timestamps, durations, and prompt currently generated for Markdown.
- Active focus duration is refreshed before copy and PDF export.
- PDF file names include the date and avoid overwriting existing files.
- Existing local data persistence remains unchanged.

Manual QA should cover:

- Header button copies content that can be pasted into an AI chat.
- Success toast reads "已复制给 AI".
- Settings or secondary action can save a PDF.
- Saved PDF opens in macOS Preview.
- PDF is readable and not raw Markdown source.
- Existing records, editing, deletion, and focus timing still work.

## Implementation Notes

- Use the Settings view for "保存为 PDF".
- Choose the smallest reliable macOS-native PDF renderer after checking SwiftUI/AppKit constraints in the codebase.
- Keep Markdown file export out of regular user-facing UI.
