# AI Journal Window Design - 2026-06-17

## Goal

Add a local-first AI journal workflow for broader personal diary users, especially people who want emotional reflection without turning the app into a therapist, cloud diary, or chatbot.

The feature is centered on a new journal window. The menu bar remains the fast capture surface; the window is where users view, edit, delete, and export polished diary entries.

## Product Positioning

The user records fragments during the day. When they choose `一笺成文`, Dayleaf sends the confirmed daily records directly from the user's Mac to the AI service configured by the user, then saves the returned diary locally.

Dayleaf has no server in this flow. It does not collect, store, forward, or inspect records or AI results. The app must still explain clearly that enabling AI sends selected content to the user's chosen third-party model provider.

## Target User

Primary target: emotional reflection diary users.

They want help turning scattered notes into a warm first-person diary. They care more about feeling understood and having the day gently organized than about productivity analysis.

Because this route requires the user to bring an API key, the first version targets users willing to trade a little setup friction for privacy and data ownership.

## User Experience

- The menu bar remains focused on quick capture.
- A new `日记` window lists generated diaries by date.
- The primary action is named `一笺成文`.
- The generated result is a first-person diary, not a report about the user.
- Users can edit the generated diary body.
- Users can delete a diary after confirmation.
- Users can export a diary to PDF as an optional archival action.
- If a user edits a diary, `重新成文` must not silently overwrite it.

## AI Output Rules

The generated diary must:

- Use first person by default.
- Read like something the user could save as their own diary.
- Be natural, warm, and restrained.
- Avoid psychological diagnosis.
- Avoid personality judgment.
- Avoid long-term conclusions such as "I am the kind of person who...".
- Avoid forced positivity.
- Use only the selected day's records as factual basis.
- Express uncertainty gently when emotion is inferred rather than explicit.

The prompt should prefer concrete details over abstract praise.

## Data Model

Add a local `DailyJournal` model:

- `id`
- `date`
- `title`
- `content`
- `sourceEntryIDs`
- `generatedAt`
- `updatedAt`
- `editedByUser`
- `modelName`

Store journals inside the existing local JSON database so the feature remains simple and local-first.

Add AI settings to local settings:

- `aiBaseURL`
- `aiModel`

Store the API key in Keychain only. Do not write the key into JSON.

## AI Runtime

Support one OpenAI-compatible chat completions endpoint:

- `base_url`
- `api_key`
- `model`

The first version can use non-streaming responses. Streaming can come later.

AI requests are user-triggered only. No background analysis, no push, no automatic uploads.

## Error Handling

- If there are no records for the selected date, disable or reject `一笺成文`.
- If AI settings are incomplete, tell the user to finish AI settings.
- If the API key is missing, tell the user to add it.
- If the network or model call fails, preserve all local data and show a readable error.
- If the AI response is empty, show a readable error and do not create a blank diary.

## Privacy Copy

Use this meaning everywhere:

> 默认情况下，所有记录只保存在本机。启用 AI 后，只有在你主动点击「一笺成文」时，应用才会把你确认的今日记录直接发送给你配置的 AI 服务，用来生成第一人称日记。一日一笺没有自有服务器，不收集、不保存、不转发你的记录与日记结果。

## Acceptance Criteria

- User can open a journal window from the menu bar.
- User can configure AI base URL, model, and API key.
- API key is stored in Keychain, not settings JSON.
- User can generate a first-person diary with `一笺成文`.
- Generated diary is saved locally.
- User can view generated diaries by date.
- User can edit and save diary content.
- User can delete a diary after confirmation.
- User can export a diary to PDF.
- Core record capture still works without AI settings.
- `swift build` passes.
- `swift run DayleafCoreCheck` passes.
