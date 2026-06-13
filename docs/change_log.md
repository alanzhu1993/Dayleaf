# Change Log

## 2026-06-13

### Added

- Created a Swift Package foundation for the 一日一笺 macOS prototype.
- Added `DayleafCore` with local data models for focus sessions, pause intervals, quick notes, settings, and mixed day entries.
- Added JSON persistence for records and settings.
- Added Markdown export with summary, timeline, timestamps, durations, and AI prompt support.
- Added configurable export directory behavior with a default Documents folder.
- Added `DayleafApp` SwiftUI menu bar prototype.
- Added focus controls: start, pause, resume, finish.
- Added quick note input for continuous "碎碎念" capture.
- Added export directory picker using the macOS folder panel.
- Added `DayleafCoreCheck`, a no-dependency executable verification suite for the current non-XCTest environment.
- Added `.gitignore` for SwiftPM build output and macOS metadata.

### Changed

- Revised `docs/product_spec.md` for focus sessions, quick notes, configurable export directory, and AI-ready Markdown.
- Added `docs/design_brief.md`.
- Added `docs/dev_plan.md`.

### Verification

- `swift build`: passed.
- `swift run DayleafCoreCheck`: passed.
- `swift test`: unavailable because the current Command Line Tools environment has no XCTest test target support; replaced by `DayleafCoreCheck`.

### Known Issues

- The current prototype is a Swift Package executable, not a packaged `.app`.
- Global shortcut configuration is documented as a later packaged-app feature.
- System notification is disabled in the Swift Package prototype because it can be unstable without a packaged macOS app bundle.

## 2026-06-13 Fix

### Fixed

- Fixed timeline refresh after adding focus sessions or quick notes by replacing the whole published database value after each mutation.
- Fixed a crash path when ending focus by removing the prototype system notification call.
- Improved the daily timeline preview so users can see focus sessions, quick notes, time ranges, timestamps, and duration without exporting Markdown.
- Improved export directory selection by activating the app, foregrounding the folder panel, and opening from an existing directory.
- Added Return/Enter submission for quick notes, starting focus, and finishing focus.
- Changed the primary capture fields to single-line quick-submit inputs for V1.
- Changed the daily timeline preview to show newest entries first while keeping export/core ordering unchanged.
- Renamed the visible product surface to `一日一笺` while keeping Swift Package and executable names unchanged.
- Changed Markdown export to Chinese headings, table labels, type labels, duration text, and file names.
- Replaced the engineering-style AI prompt with a warm friend-style Chinese reflection prompt.
- Changed the default export folder to `~/Documents/一日一笺/`.

### Verification

- `swift build`: passed.
- `swift run DayleafCoreCheck`: passed.
- `swift run Dayleaf`: launched successfully for smoke testing and was then stopped manually.

## 2026-06-13 App Preview

### Added

- Added `scripts/package_app.sh` to build an unsigned `dist/Dayleaf.app` and `dist/Dayleaf.dmg` locally (swift build + sips/iconutil for the icon + hdiutil for the dmg). No code signing or notarization at this stage.
- Added `Assets/AppIconSource.png` as the app icon source, generated into `AppIcon.icns` during packaging.
- Added bundle metadata: `CFBundleIdentifier=com.alanzhu.dayleaf`, `CFBundleDisplayName=Dayleaf`, `LSUIElement=true` (menu bar tool, no Dock icon).
- Added a Quit action at the bottom of the menu bar popover (⌘Q), since the app has no Dock icon to quit from.
- Added edit-text and delete actions for saved timeline entries via a per-row "⋯" menu, with inline editing and a delete confirmation. In-progress focus sessions are not editable or deletable.

### Changed

- Renamed all internal `DayLog` naming to `Dayleaf`: Swift package name, products (`Dayleaf`, `DayleafCore`, `DayleafCoreCheck`), targets (`DayleafApp`, `DayleafCore`, `DayleafCoreCheck`), source folders, and type names (`DayleafApplication`, `DayleafViewModel`, `DayleafDatabase`, `DayleafSettings`, `JSONDayleafStore`). Run commands are now `swift run Dayleaf` / `swift run DayleafCoreCheck`. The user-facing Chinese name `一日一笺` is unchanged.
- Updated README, `docs/release_note.md`, `docs/release_audit.md`, and CI workflow to reflect the unsigned `.dmg` preview, the rename, and the new edit/delete and quit features.
- Added `dist/` to `.gitignore`.

### Verification

- `swift build`: passed.
- `swift run DayleafCoreCheck`: passed.
- `swift run Dayleaf`: launched, smoke-tested (quit button, timeline edit/delete), then stopped.
- `./scripts/package_app.sh`: produced `dist/Dayleaf.app` and `dist/Dayleaf.dmg`.

### Known Issues

- The `.app` / `.dmg` is unsigned and not notarized; macOS Gatekeeper warns on first open (right-click → Open to bypass).
- Timeline editing changes entry text only; start/end time and duration are not editable yet.
