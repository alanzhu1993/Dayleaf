# Global Quick Capture Design - 2026-06-18

## Goal

Add a global quick-capture path for Dayleaf so users can record a thought without opening the full menu bar surface.

The intended path is:

```text
Global shortcut -> quick capture window opens -> input is focused -> user types -> Return saves -> window closes
```

This feature exists to support fast recording. It is not a second main window and must not include focus sessions, timeline, AI generation, export, or settings.

## User Experience

The user presses the configured global shortcut from anywhere on macOS. Dayleaf shows a small floating quick-capture window with the text cursor already inside the input field.

The window contains only the capture input and minimal state feedback. The user types a note and presses `Return`. Dayleaf saves the note as a normal quick note for the current day, then closes the window immediately.

Keyboard behavior:

- `Return`: save non-empty text and close the window.
- `Shift + Return`: insert a newline.
- `Escape`: close the window without saving.
- Empty `Return`: do not save and keep the window open with a readable hint.
- Save failure: keep the window open and show the error.

After a successful save, the user should return to the previous working context with no extra confirmation step.

## Scope

In scope:

- A global shortcut for quick capture.
- A small quick-capture window separate from the menu bar popover.
- Automatic input focus when the window opens.
- Immediate close after successful save.
- User-editable shortcut configuration in settings.
- Local persistence through the existing quick-note data path.

Out of scope:

- Focus-session controls in the quick-capture window.
- Timeline or history in the quick-capture window.
- AI actions in the quick-capture window.
- Tags, projects, categories, or customer fields.
- Multiple global shortcuts.
- Automatic screen, app, browser, keyboard, or clipboard monitoring.

## Default Shortcut

The app should ship with a default quick-capture shortcut. The recommended default is:

```text
Control + Option + Space
```

The default is only a starting point. Users must be able to change it from settings because global shortcuts can conflict with macOS, input methods, launchers, or other productivity tools.

If the default shortcut cannot be registered, the app should keep running and show a clear warning in settings.

## Architecture

### `GlobalShortcutManager`

Add an app-side manager responsible for registering, unregistering, and re-registering the configured global shortcut.

Responsibilities:

- Load the configured shortcut from `DayleafSettings`.
- Register the shortcut at app startup.
- Trigger a callback when the shortcut is pressed.
- Re-register when the user changes the shortcut.
- Report registration failure so the UI can explain that the shortcut may be occupied.

The manager should register only the chosen key combination. It must not use broad keyboard event monitoring or record arbitrary keystrokes.

### `ShortcutRecorder`

Add a small settings control for recording a replacement shortcut.

Responsibilities:

- Enter a recording state when the user clicks the shortcut row.
- Capture a complete key combination.
- Reject plain character keys without meaningful modifiers.
- Persist the accepted shortcut to local settings.
- Ask `GlobalShortcutManager` to re-register it.

The settings copy should be direct and user-facing, for example:

```text
快速记录快捷键
```

### `QuickCaptureWindowPresenter`

Add an app-side presenter for the quick-capture window.

Responsibilities:

- Create the window on first use.
- Reuse the existing window while it is open.
- Bring the window to the front when the global shortcut is pressed.
- Place the window centered on the screen that currently contains the cursor.
- Ensure the text input becomes first responder after the window appears.
- Close the window after a successful save or `Escape`.

The window should be lightweight and visually consistent with the existing app: native macOS feel, compact size, no decorative layout.

### `QuickCaptureWindowView`

Add a SwiftUI view for the capture surface.

Responsibilities:

- Render only the input field and minimal status text.
- Reuse `QuickNoteEditor` for input editing so `Return`, `Shift + Return`, text binding, and IME behavior stay consistent with the menu bar quick-note field.
- Save by calling a view-model method that accepts explicit text.
- Clear draft text after successful save.
- Keep the window open on empty input or save errors.

### `DayleafViewModel`

Add a lower-level quick-note save method that takes explicit content:

```swift
func addQuickNote(content: String) -> Bool
```

The existing menu bar quick-note path can continue using `quickNoteDraft`, but both the menu bar and quick-capture window should share the same validation and persistence behavior.

### `DayleafSettings`

Add a setting for the quick-capture shortcut. It should be Codable and safe for existing users with older settings files.

Add this setting shape:

```swift
public var quickCaptureShortcut: KeyboardShortcutSpec?
```

If the setting is missing, the app uses the default shortcut.

## Data Flow

1. App starts and loads settings.
2. `GlobalShortcutManager` registers the configured shortcut.
3. User presses the shortcut.
4. Manager calls the app callback.
5. `QuickCaptureWindowPresenter` shows the quick-capture window and focuses input.
6. User types text.
7. User presses `Return`.
8. `QuickCaptureWindowView` calls `DayleafViewModel.addQuickNote(content:)`.
9. View model saves a normal quick-note record to the existing local JSON store.
10. On success, the presenter closes the window.

No network request is involved. No data leaves the device.

## Error Handling

- Shortcut registration failure: keep the app usable, show a settings warning, and let the user choose another shortcut.
- Empty note: do not save; keep focus in the input field.
- Save failure: keep the typed text, show the error, and keep the window open.
- Shortcut changed to an invalid combination: reject it before saving.
- Shortcut pressed while the quick-capture window is already open: bring the existing window forward and keep the current draft.

## Testing

Automated checks:

- `swift build` passes.
- `swift run DayleafCoreCheck` passes.
- Core shortcut spec parsing or Codable behavior is covered by `DayleafCoreCheck` if implemented in `DayleafCore`.
- `DayleafViewModel.addQuickNote(content:)` shares validation with the existing quick-note flow.

Manual macOS checks:

- Launch the app and confirm the configured global shortcut opens the quick-capture window.
- Confirm the input is focused immediately.
- Type text and press `Return`; confirm the note is saved and the window closes.
- Press `Shift + Return`; confirm a newline is inserted.
- Press `Escape`; confirm the window closes without saving.
- Press `Return` on empty input; confirm nothing is saved and the window remains open.
- Change the shortcut in settings; confirm the old shortcut stops working and the new shortcut works.
- Try an occupied shortcut; confirm the app shows a clear warning instead of failing silently.
- Confirm the menu bar quick-note path still works.

## Acceptance Criteria

- A global shortcut opens a quick-capture-only window.
- The quick-capture input is focused as soon as the window opens.
- `Return` saves a non-empty quick note and immediately closes the window.
- `Shift + Return` creates a newline.
- `Escape` cancels without saving.
- The quick-capture note appears in the normal Dayleaf timeline.
- Users can change the quick-capture shortcut in settings.
- Shortcut registration conflicts are visible to the user.
- The feature does not add cloud sync, monitoring, AI behavior, focus controls, or timeline controls to the quick-capture window.
