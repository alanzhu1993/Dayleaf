# Release Note

## Version

v0.1.0-source-prototype

## Summary

Dayleaf / 一日一笺 is ready for an initial source prototype release on GitHub.

This version is intended for developers and early testers. It is not a packaged macOS `.app` yet.

## New Features

- Menu bar prototype for macOS.
- Focus sessions with start, pause, resume, and finish.
- Quick note capture.
- Keyboard-first submission using Return/Enter.
- Today timeline preview, newest entries first.
- Local JSON persistence.
- Configurable Markdown export directory.
- Chinese Markdown export with warm friend-style AI prompt.

## Improvements

- Visible product name updated to `一日一笺`.
- English product name chosen as `Dayleaf`.
- Export file name changed to `YYYY-MM-DD-一日一笺.md`.
- Default export folder changed to `~/Documents/一日一笺/`.

## Fixes

- Fixed timeline refresh after adding records.
- Fixed crash path when ending focus by removing prototype system notification.
- Improved folder picker behavior in the menu bar prototype.
- Changed timeline preview to newest-first order.

## Known Limitations

- Not packaged as a `.app`.
- No GitHub Release binary.
- No global shortcut.
- No system notification.
- No edit/delete UI for saved entries.
- `swift test` is not used in the current local environment; use `DayLogCoreCheck`.

## How to Run

```bash
git clone https://github.com/alanzhu1993/Dayleaf.git
cd Dayleaf
swift run DayLog
```

## How to Verify

```bash
swift build
swift run DayLogCoreCheck
```

## Next Steps

- Package as a standard macOS `.app`.
- Add app icon and bundle metadata.
- Add global shortcut configuration.
- Add edit/delete UI.
- Publish `Dayleaf.app.zip` or `.dmg` in GitHub Releases.
