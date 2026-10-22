## Why

Every refresh rereads the entire archive and discards thread, timestamp, and model context. Users need persistent analytics across folders of AI conversation logs, with reliable lexical classification and useful live feedback.

## What Changes

- Bind one or more log folders, persist the selection, and import Codex, Claude Code, and a documented generic JSONL format through adapters.
- Persist normalized message word counts, thread metadata, model attribution, and per-file byte cursors in an application-owned SQLite index.
- Read only appended complete lines; retain indexed results across restarts and rebuild only replaced/truncated sources.
- Replace regular-expression profanity matching with a versioned dictionary and deterministic morphology classifier, including English and Russian vocabulary and explicit exclusions.
- Show overall and per-model metrics, thread filtering, a time chart, and lexical categories in an English native macOS dashboard.
- Offer opt-in English joke notifications for bursts in newly observed messages, suppressing archive imports and repeated alerts.
- **BREAKING**: Legacy profanity regex configuration is superseded by the classifier. Existing configured log folders are preserved.

## Capabilities

### New Capabilities

- `log-index`: Folder binding, source adapters, durable incremental ingestion, and source health.
- `word-classifier`: Deterministic lexical classification and index-only reclassification.
- `conversation-analytics`: Overall, thread, model, and time-based analytics.
- `burst-notifications`: Live-only rate-limited English notifications.

### Modified Capabilities

None; the repository has no existing OpenSpec capabilities.

## Impact

Replaces the stateless core scanner and dashboard. Uses the system SQLite library, Swift Charts, and UserNotifications; no network service or LLM is required. Source files remain read-only. Local index and configuration stay outside version control.
