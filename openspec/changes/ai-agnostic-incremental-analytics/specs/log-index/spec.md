## ADDED Requirements

### Requirement: Bind provider-neutral log folders
The application SHALL persist user-selected log folders and normalize Codex, Claude Code, and generic JSONL into a provider-neutral thread/message index. It SHALL expose unavailable sources and malformed/unsupported records without inventing model names.

#### Scenario: Mixed providers
- **GIVEN** an attached directory containing Codex, Claude Code, and generic JSONL fixtures
- **WHEN** indexing completes
- **THEN** user messages from all three formats appear under their provider and model and assistant/tool/instruction records do not count

#### Scenario: Folder cannot be read
- **WHEN** an attached folder becomes unavailable
- **THEN** cached results remain visible with an unavailable-folder warning

### Requirement: Durable incremental ingestion
The index SHALL atomically persist complete messages, parser state, and byte cursors. Unchanged files SHALL read zero content bytes. Partial final lines SHALL wait for completion. Restart SHALL expose cached results before ingestion.

#### Scenario: Append and restart
- **GIVEN** an indexed source
- **WHEN** refresh runs unchanged, a line is appended, and the app restarts
- **THEN** the unchanged refresh reads zero bytes, append reads only new bytes, and restart preserves counts without duplication

#### Scenario: Interrupted write or source replacement
- **WHEN** an incomplete JSON line is completed or a source is replaced/truncated
- **THEN** the completed line counts exactly once and only the affected source is rebuilt

#### Scenario: Index transaction fails
- **WHEN** ingestion fails before transaction commit
- **THEN** source cursor and message rows roll back together and retry yields exactly one copy

### Requirement: Canonical records
The adapters SHALL avoid counting mirrored completed events, metadata indexes, and generated instruction messages. Repeated distinct messages SHALL count separately. Per-turn model context SHALL survive refresh boundaries.

#### Scenario: Automated user-role input
- **WHEN** Codex identifies a subagent session or Claude marks a record as a sidechain
- **THEN** its generated prompts do not contribute to human conversation statistics or burst alerts

#### Scenario: Model follows user prompt
- **WHEN** a user record is followed by its model context in a later appended batch
- **THEN** the existing message gains that responding model without a second message
