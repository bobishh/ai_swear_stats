## Context

The Swift 6.3 macOS app imports JSONL conversation logs from attached directories. Existing configured roots must migrate. UI and notification copy use English.

## Goals / Non-Goals

**Goals:** durable incremental ingestion, provider-neutral records, deterministic word classification, overall/per-model/per-thread analytics, burst notifications, strict Swift checks.

**Non-Goals:** universal inference of undocumented formats, cloud synchronization, psychological diagnosis, editing provider databases.

## Decisions

1. A single `AnalyticsIndex` actor owns an application SQLite database. Source cursor, parser context, word-count records, and model corrections commit together per file. UI reads cached records at launch. SQL parameters are bound. No unchecked Sendable conformance is used for the database.
2. Enumerate attached folders for JSONL sources, then compare identity, size, and modification time. Unchanged sources read zero bytes. Append processing uses bounded chunks and newline cursors, retaining incomplete tails. Replaced/truncated/rewritten files rebuild only their own rows. Metadata reconciliation every few seconds discovers new files without rereading unchanged content.
3. Adapters normalize Codex response-item/realtime records, Claude Code messages, and documented generic JSONL. Codex completed-item mirrors and history/index metadata are excluded. Provider/model are explicit dimensions; missing models remain Unknown. Model context following a prompt attributes that prompt to its responding model. Stable message IDs merge replayed records within a thread; text equality alone never deduplicates distinct messages.
4. Store word-frequency dictionaries rather than full message/tool text. Store event time, provider, model, effort, thread ID/title, project path, and source provenance. Reclassifying a new lexicon version reads this index, not archives. Legacy regex settings are ignored after migration.
5. Versioned bundled JSON describes lexical families, validated inflections, derivational prefixes, full-word exceptions, and explicit masked forms. Matching uses sets and deterministic morphology, with no regex or inference API. Categories are profanity, insult, and vulgarity. Generated instruction blocks are excluded before tokenization.
6. SwiftUI renders overall/model/thread filters, density, share of profane messages, a full-history rate chart with adaptive minute/hour/day buckets, and top families/words. Unknown times are counted but excluded from time charts. Lexical intensity is a descriptive rate, not a medical stress score.
7. A pure burst policy runs on live newly ingested records only. Default threshold: five profanities in two minutes across at least two messages; cooldown: fifteen minutes; rearm after a quiet window. Initial import/replacement/replay cannot alert. Policy state persists. Notification authorization is requested only when enabled through the UI. English templates are bundled separately and rotate without consecutive repeats.
8. Follow official Swift API Design Guidelines and actor isolation guidance. `swift format lint --strict` plus SwiftLint safety/complexity rules and tests run through one check script and GitHub Actions. Keep modules small; fail on compiler warnings.

## Risks / Trade-offs

- Undocumented provider layouts change → explicit adapters, fixtures, visible unsupported/malformed counts.
- Same-size in-place edits → modification time triggers source rebuild; ordinary appends assume existing prefix is immutable.
- Source disappears → retain indexed records with unavailable status; removing its bound folder excludes those records from analytics.
- Fork ancestry and alternative event representations vary → canonical adapter choice; no heuristic global text deduplication.
- Lexicon coverage is finite → conservative matches, explicit exceptions and corpus tests; unknown words remain unclassified.
- SQLite growth → retain token frequencies and metadata only; never copy tool payloads or complete chats.

## Migration Plan

Keep the existing Application Support configuration location and `rootPaths`. Decode missing new fields with defaults. Create a separate analytics database; import once. The first launch keeps UI responsive and displays growing indexed statistics. Keep source logs untouched.

## Open Questions

Additional formats can be added once representative fixtures are available. The first release supports Codex, Claude Code, and normalized generic JSONL explicitly.
