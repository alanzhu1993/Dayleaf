# Release Note

## Version

v0.1.0-app-preview

## Summary

Dayleaf / 一日一笺 can now be packaged into a double-clickable macOS `.app` and distributed as `Dayleaf.dmg` for early download testing.

This is an **early preview**. The app is **unsigned and not notarized** — macOS may report that the developer cannot be verified. If it will not open, right-click the app and choose **Open**.

## Packaging

- `scripts/package_app.sh` builds a release binary, generates `AppIcon.icns` from `Assets/AppIconSource.png`, assembles `dist/Dayleaf.app`, and produces `dist/Dayleaf.dmg`.
- Bundle metadata: `CFBundleIdentifier=com.alanzhu.dayleaf`, `CFBundleDisplayName=Dayleaf`, `CFBundleExecutable=DayLog`, `CFBundleIconFile=AppIcon`, `LSUIElement=true` (menu bar tool, no Dock icon).
- No code signing and no notarization in this stage.
- Release attaches `Dayleaf.dmg` only (no zip).

## New Features

- Menu bar prototype for macOS.
- Focus sessions with start, pause, resume, and finish.
- Quick note capture.
- Keyboard-first submission using Return/Enter.
- Today timeline preview, newest entries first.
- Edit text or delete any saved timeline entry, with delete confirmation.
- Quit action inside the menu bar popover (⌘Q).
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

- `.app` / `.dmg` is unsigned and not notarized; Gatekeeper warns on first open.
- No global shortcut.
- No system notification.
- Timeline editing changes entry text only; start/end time and duration are not editable yet.
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

- Sign and notarize the app with an Apple Developer account.
- Add global shortcut configuration.
- Add edit/delete UI.
- Publish `Dayleaf.dmg` in GitHub Releases (e.g. tag `v0.1.0-app-preview`).
