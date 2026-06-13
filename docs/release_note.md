# Release Note

## Version

v0.3

## Summary

Dayleaf / 一日一笺 0.3 focuses on a more polished, daily-use menu bar experience: a redesigned popover, light/dark themes, inline settings, privacy-forward About copy, toast feedback, and a better multiline quick note editor.

This is still an **early preview**. The app is ad-hoc signed but **not notarized** — macOS may report that the developer cannot be verified. If it will not open, right-click the app and choose **Open**.

## Packaging

- `scripts/package_app.sh` builds a release binary, generates `AppIcon.icns` from `Assets/AppIconSource.png`, assembles `dist/Dayleaf.app`, and produces `dist/Dayleaf.dmg`.
- Bundle metadata: `CFBundleIdentifier=com.alanzhu.dayleaf`, `CFBundleDisplayName=Dayleaf`, `CFBundleExecutable=Dayleaf`, `CFBundleIconFile=AppIcon`, `LSUIElement=true` (menu bar tool, no Dock icon).
- Ad-hoc signing is applied locally to avoid the "damaged app" path on Apple Silicon.
- No Apple Developer ID signing and no notarization in this stage.
- Release attaches `Dayleaf.dmg` only (no zip).

## New Features

- Shared design system for the menu bar app: palette, layout tokens, tiles, fields, and button styles.
- Light/dark theme selection.
- In-popover settings for theme and export directory.
- About panel with version and local-first privacy messaging.
- Toast feedback for common actions.
- Multiline quick note editor: Return saves, Shift+Return inserts a new line.
- Future AI feature plan and data-chain diagram in `docs/`.

## Improvements

- Refined the popover visual hierarchy, spacing, timeline rows, empty state, and footer.
- Moved export directory controls into settings.
- README now states: “隐私为先，你的每一天都值得被看见。”
- App/package version defaults now use `0.3`.

## Fixes

- Reduced long export-path noise in action feedback by showing concise toast text.

## Known Limitations

- Requires macOS 26.0+ in this build.
- `.app` / `.dmg` is ad-hoc signed but not notarized; Gatekeeper warns on first open.
- No global shortcut.
- No system notification.
- Timeline editing changes entry text only; start/end time and duration are not editable yet.
- `swift test` is not used in the current local environment; use `DayleafCoreCheck`.

## How to Run

```bash
git clone https://github.com/alanzhu1993/Dayleaf.git
cd Dayleaf
swift run Dayleaf
```

## How to Verify

```bash
swift build
swift run DayleafCoreCheck
```

## Next Steps

- Sign and notarize the app with an Apple Developer account.
- Add global shortcut configuration.
- Continue the AI diary/long-term memory direction documented in `docs/ai_feature_plan.md`.
