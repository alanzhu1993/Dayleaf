# Release Audit

## 1. Release Scope

This release prepares Dayleaf / 一日一笺 for an early app-preview release on GitHub.

Release type:

- Packaged macOS `.app`, distributed as `Dayleaf.dmg`.
- **Unsigned and not notarized.** This is NOT a formal, notarized App Store / Developer ID release.
- macOS Gatekeeper will warn on first open; users may need to right-click → Open, or allow it in Privacy & Security.

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

Implemented in this release:

- Edit text / delete actions for saved timeline entries (with delete confirmation).
- Quit action inside the menu bar popover (⌘Q).

Not included in this release:

- Global shortcut.
- System notification.
- Editing start/end time or duration of a focus session (text-only editing for now).
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

- The `.app` / `.dmg` is unsigned and not notarized; Gatekeeper warns on first open.
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

Packaging is done by `scripts/package_app.sh` on a local macOS machine with Xcode / Command Line Tools:

- `swift build -c release` produces the release binary;
- `sips` + `iconutil` generate `AppIcon.icns` from `Assets/AppIconSource.png`;
- a hand-assembled `dist/Dayleaf.app` bundle is created with `Info.plist` (`com.alanzhu.dayleaf`, `Dayleaf`, `DayLog`, `AppIcon`, `LSUIElement=true`);
- `hdiutil` produces `dist/Dayleaf.dmg` (with an `/Applications` symlink for drag-install).

Current stage is **unsigned, not notarized**. A later phase still requires:

- Apple Developer ID signing (`codesign`);
- notarization (`notarytool`) and stapling;
- this would remove the Gatekeeper "unverified developer" warning.

`dist/` is gitignored; artifacts are produced locally and uploaded to GitHub Releases.

## 9. Go / No-go Recommendation

Go for an early unsigned `.dmg` preview release (e.g. tag `v0.1.0-app-preview`), provided the release notes clearly state it is unsigned/unnotarized and explain the right-click → Open workaround.

No-go for a "verified developer" release until signing and notarization are completed.
