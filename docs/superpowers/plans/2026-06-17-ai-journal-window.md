# AI Journal Window Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the local-first `一笺成文` workflow: AI settings, first-person diary generation, local journal storage, and a journal window for viewing, editing, deleting, and exporting diaries.

**Architecture:** Extend `DayleafCore` with a `DailyJournal` model, AI settings, prompt builder, and local storage. Add app-side Keychain storage, OpenAI-compatible client, view-model actions, and a new SwiftUI `WindowGroup` journal surface.

**Tech Stack:** Swift 6, SwiftUI, Foundation `URLSession`, Security Keychain, local JSON storage, existing PDF exporter patterns.

---

### Task 1: Core Models and Store

**Files:**
- Modify: `Sources/DayleafCore/Models.swift`
- Modify: `Sources/DayleafCore/Settings.swift`
- Modify: `Sources/DayleafCoreCheck/main.swift`

- [x] Add `DailyJournal` with first-person diary metadata.
- [x] Add `[DailyJournal]` to `DayleafDatabase`.
- [x] Add `journal(on:)` and `journalsNewestFirst` helpers.
- [x] Add `aiBaseURL` and `aiModel` to `DayleafSettings`.
- [x] Update core check to verify JSON round-trip preserves journals and AI settings.

### Task 2: AI Prompt and Request Types

**Files:**
- Create: `Sources/DayleafCore/JournalPromptBuilder.swift`
- Create: `Sources/DayleafApp/OpenAICompatibleClient.swift`

- [x] Build a prompt from one date's entries.
- [x] Require first-person, warm, restrained diary output.
- [x] Add OpenAI-compatible request/response Codable types.
- [x] Return the first non-empty assistant message.

### Task 3: Keychain and View Model Actions

**Files:**
- Create: `Sources/DayleafApp/APIKeyStore.swift`
- Modify: `Sources/DayleafApp/DayleafViewModel.swift`

- [x] Store API key in Keychain.
- [x] Add AI settings drafts and save methods.
- [x] Add `generateJournalForToday()`.
- [x] Add journal edit, delete, and PDF export methods.
- [x] Preserve existing record and export behavior when AI is not configured.

### Task 4: Journal Window UI

**Files:**
- Modify: `Sources/DayleafApp/DayleafApplication.swift`
- Create: `Sources/DayleafApp/JournalWindowView.swift`
- Modify: `Sources/DayleafApp/MenuBarRootView.swift`
- Modify: `Sources/DayleafApp/SettingsView.swift`

- [x] Add a `WindowGroup("日记")`.
- [x] Add menu bar buttons for `日记` and `一笺成文`.
- [x] Build a two-pane journal window with date list and editable diary body.
- [x] Add delete confirmation and PDF export.
- [x] Add AI settings controls in settings views.

### Task 5: Verification

**Files:**
- Modify docs only if user-facing behavior changed.

- [x] Run `swift build`.
- [x] Run `swift run DayleafCoreCheck`.
- [x] Fix compile or check failures.
- [x] Review privacy copy for the new AI behavior.
