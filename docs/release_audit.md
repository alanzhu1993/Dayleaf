# Release Audit

## 1. Release Scope

This release prepares Dayleaf / 一日一笺 for an initial GitHub source prototype release.

Release type:

- Source prototype.
- Not a packaged macOS `.app`.
- Not a downloadable GitHub Release binary.

## 2. Requirement Match

Pass with documented limitations.

Implemented:

- macOS menu bar prototype.
- Focus sessions with start, pause, resume, and finish.
- Quick notes.
- Keyboard-first capture with Return/Enter.
- Today timeline preview with newest entries first.
- Local JSON persistence.
- Configurable Markdown export directory.
- Chinese Markdown export.
- Warm friend-style AI prompt.

Not included in this release:

- Packaged `.app`.
- Global shortcut.
- System notification.
- Edit/delete actions for historical entries.
- Built-in AI analysis.

## 3. Design Match

Pass.

The prototype follows the compact menu bar direction described in `docs/design_brief.md`. The interface stays focused on capture, current focus state, today timeline, and export.

## 4. Verification Results

Latest local verification:

```bash
swift build
swift run DayLogCoreCheck
```

Results:

- `swift build`: passed.
- `swift run DayLogCoreCheck`: passed.

`swift test` is not used in the current local Command Line Tools environment because XCTest is unavailable. `DayLogCoreCheck` is used as the executable verification suite.

## 5. Manual Acceptance Path

Run:

```bash
swift run DayLog
```

Manual checks:

1. Confirm `一日一笺` appears in the macOS menu bar.
2. Add multiple quick notes with Return/Enter.
3. Start a focus session.
4. Pause and resume the focus session.
5. Finish the focus session with actual activity text.
6. Confirm today timeline shows newest entries first.
7. Select an export directory.
8. Export Markdown.
9. Confirm the exported file is named `YYYY-MM-DD-一日一笺.md`.
10. Confirm exported Markdown uses Chinese sections and a warm AI prompt.

## 6. Known Issues

- This is not a packaged `.app`.
- Users must run from source with Swift.
- No global shortcut.
- No system notification.
- No edit/delete UI yet.
- Native folder picker behavior still needs manual verification in packaged `.app` form.

## 7. Risks

- Non-developer users may not be able to run the source prototype.
- Swift Package runtime behavior is not identical to a packaged macOS app.
- Future sandboxed packaging may require security-scoped bookmarks for export directories.
- CI may differ from the local Swift 6.3.1 environment.

## 8. Deployment / Packaging Notes

GitHub source release is acceptable after README, LICENSE, release docs, and CI are present.

Packaged app release requires a later phase:

- install full Xcode;
- create or migrate to a standard macOS app project;
- configure bundle ID, app name, app icon, and permissions;
- decide signed, notarized, or unsigned distribution;
- produce `Dayleaf.app.zip` or `.dmg`;
- attach artifact to GitHub Releases.

## 9. Go / No-go Recommendation

Go for initial GitHub source prototype release.

No-go for downloadable macOS app release until packaging is completed.
