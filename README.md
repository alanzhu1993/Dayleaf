# Dayleaf / 一日一笺

Dayleaf（中文名：一日一笺）是一款本地优先的 macOS 菜单栏记录工具。

它用于快速记录一天中的两类内容：

- 专注记录：开始、暂停、继续、结束一段专注，并记录实际做了什么。
- 快速记录：随手记下灵感、碎碎念和临时想法。

一天结束后，Dayleaf 可以导出中文 Markdown 文件，包含时间线、专注时长和一段温暖型 AI 回顾提示。你可以把这份 Markdown 交给任意 AI 工具，让它像朋友一样帮你回看这一天。

## Current Status

This repository is currently a **Swift Package prototype**.

It is not a packaged macOS `.app` yet. You cannot download a ready-to-use app from GitHub Releases at this stage.

For now, Dayleaf is intended for developers or early testers who can run it from source.

## Features

- macOS menu bar interface.
- Start, pause, resume, and finish focus sessions.
- Quick note capture with Return/Enter submission.
- Today timeline preview, newest entries first.
- Local JSON persistence.
- Configurable Markdown export directory.
- Chinese Markdown export:
  - `概览`
  - `时间线`
  - `给 AI 的提示`
- No cloud sync.
- No AI API key.
- No automatic upload.

## Requirements

- macOS
- Swift 6.0+ toolchain

The current prototype has been verified locally with:

```bash
swift-driver version: 1.148.6 Apple Swift version 6.3.1
```

## Run From Source

```bash
git clone https://github.com/alanzhu1993/Dayleaf.git
cd Dayleaf
swift run DayLog
```

After launch, look for `一日一笺` in the macOS menu bar.

To stop the prototype, return to the terminal and press:

```bash
Control + C
```

## Verify

```bash
swift build
swift run DayLogCoreCheck
```

`DayLogCoreCheck` validates the core logic, including:

- focus duration excluding pause time;
- day filtering and timeline ordering;
- configurable export directory;
- Chinese Markdown export;
- JSON persistence round trip.

## Exported Markdown

The default export directory is:

```text
~/Documents/一日一笺/
```

Exported files use this format:

```text
YYYY-MM-DD-一日一笺.md
```

Example sections:

```markdown
# 2026-06-13 一日一笺

## 概览

## 时间线

## 给 AI 的提示
```

The AI prompt is intentionally warm and reflective. It asks AI to respond like a sincere friend, not like a hard productivity dashboard.

## Data and Privacy

Dayleaf is local-first.

- Records are stored locally as JSON.
- Markdown files are exported only to the directory you choose.
- The app does not upload records.
- The app does not call AI services.
- The app does not collect screen, keyboard, browser, or app usage history.

## Known Limitations

- Not packaged as a `.app` yet.
- No GitHub Release binary yet.
- No global shortcut yet.
- No system notification yet.
- No edit/delete UI for historical entries yet.
- Current UI smoke tests are manual.
- `swift test` is not used because this local Command Line Tools environment does not expose XCTest; `DayLogCoreCheck` is used instead.

## Roadmap

- Package as a standard macOS `.app`.
- Add app icon and bundle metadata.
- Add global shortcut configuration.
- Add edit/delete actions for saved entries.
- Add GitHub Release artifact such as `Dayleaf.app.zip` or `.dmg`.

## License

MIT License. See [LICENSE](LICENSE).
