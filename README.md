# Swear Stats

A native macOS dashboard for profanity in your AI conversations. Attach log folders, explore threads and models, and find the conversations that run hottest. Analysis happens locally, using a dictionary and morphology rules—no LLM calls or uploaded chats.

## Run

Requires **macOS 13+** and a **Swift 6.3+ toolchain** with the macOS SDK.

```sh
git clone https://github.com/bobishh/codex_stats.git
cd codex_stats
./run-app.sh
```

The launcher builds an optimized `.build/Swear Stats.app`, packages its resources, signs the bundle locally, and opens the dashboard. The app appears in the Dock; clicking its icon reopens the window. Use **Command-R** to refresh and **Command-Q** to quit. `./run-app.sh --build-only` builds without opening it.

Open **Log folders… → Add log folder…** to attach directories. Subfolders are included. Removing a folder detaches it from analytics without deleting its logs or cached records.

New installations look in `~/.codex`, `~/.codex-work`, and `~/.claude/projects`. Existing configured folders are preserved. Missing folders appear as source warnings.

## Explore

- **All threads, model, and period filters** narrow the totals, rankings, chart, and source diagnostics. Select a thread for its statistics.
- **Words / Families** switches between individual forms and combined lexical families.
- **Thread heat** runs from blue through purple and orange to red. Each row shows the actual percentage of messages containing profanity.
- **Sort → Hottest first** uses the same temperature as the row color. **Recent activity** orders by latest message. The chosen mode survives restarts.
- **Sources** reports malformed records, unsupported formats, and unavailable files. Inside a filtered view, it includes only files contributing messages to that selection.

Temperature accounts for conversation size:

```text
heat = (messages containing profanity / total messages) × total messages / (total messages + 20)
```

Short threads stay cooler, so a couple of spicy replies do not dominate the list. The percentage badge remains unadjusted. Equal temperatures sort by recent activity, then thread identity; the selected thread has a separate outline.

The dashboard reports profanity hits, messages, hits per 1,000 words, and the share of messages containing profanity. **Insults**, **vulgarity**, and **profanity** are separate lexical categories; only profanity contributes to heat and reminders.

The intensity chart shows hits per second in one-minute buckets, including quiet minutes, over the most recent 24 hours of the selected data. Period totals can cover a longer interval. Messages without timestamps remain in totals but are excluded from the chart. This measures language, not psychological stress.

## Supported logs

Files must be newline-delimited JSON with a `.jsonl` extension.

| Format | What counts |
| --- | --- |
| Codex | Canonical user messages, user voice transcript segments, and per-turn model context. Event mirrors, tool/assistant output, subagent sessions, and recognized generated instruction blocks are excluded. |
| Claude Code | User text with session/message identity and model attribution from the responding assistant. Tool results, metadata, and sidechain subagent prompts are excluded. |
| Generic JSONL | Records with `role: "user"` and `content` as a string or text-block array. |

A minimal generic record:

```json
{"id":"m1","thread_id":"chat-1","provider":"custom","model":"my-model","role":"user","content":"fix this fucking bug","timestamp":"2026-10-21T12:00:00Z"}
```

Generic records may also include `title` and `project_path`. Timestamps accept ISO 8601, Unix seconds, or Unix milliseconds. Unknown models remain **Unknown**; model attribution can update when later log records supply context.

Other export schemas need an adapter or conversion to generic JSONL. Fork ancestry is not inferred. Stable message IDs prevent replay duplicates; identical text alone does not merge distinct messages.

## Indexing and classification

The first import reads the archive. Subsequent refreshes check file metadata and read only appended complete lines. Partial final lines wait for completion; replacing or truncating a file rebuilds that source. Parser revisions may require reimporting affected sources.

A local SQLite index stores word frequencies, short thread labels, timestamps, provider/model/project metadata, source health, and byte offsets. Restarting uses cached records. Updating the classifier reuses stored word frequencies without rereading logs. Source logs remain read-only.

The bundled English/Russian lexicon uses explicit word forms, morphology, masked forms, and exceptions. It uses neither regular expressions nor an LLM. Coverage is finite: extend [lexicon.json](Sources/CodexStatsCore/Resources/lexicon.json) with positive and innocent-lookalike regression cases.

## Burst reminders

Enable **Burst reminders**, then allow notifications in the macOS prompt. English joke notifications trigger after **five profanities across at least two new messages within two minutes**. A **15-minute cooldown** and quiet-window rearm limit repeated alerts.

Initial imports, rebuilt sources, restart backlog, and replayed records cannot trigger reminders. Notifications use fixed templates, never chat excerpts. If permission is blocked, **Notification Settings…** opens system settings; allow Swear Stats and return to the app. Delivery also depends on macOS notification settings and Focus modes.

## Local settings

| Location | Contents |
| --- | --- |
| `~/Library/Application Support/codex_stats/config.json` | Attached folders, refresh interval, reminder preference |
| `~/Library/Application Support/codex_stats/analytics.sqlite` | Cached analytics and burst-policy state |
| macOS application preferences | Thread sort order |

Folder reconciliation runs every five seconds by default. UI changes save automatically; restart after editing the configuration file manually. Legacy package names and the `codex_stats` data directory remain for compatibility. Build outputs, databases, and local configuration do not belong in Git.

## Development

```sh
brew install swiftlint
npm install --global @fission-ai/openspec@1.4.1
swift format format --in-place --recursive Sources Tests Package.swift
./scripts/check.sh
```

The check script runs Swift tests with warnings treated as errors, strict swift-format and SwiftLint checks, launcher syntax validation, and OpenSpec validation. GitHub Actions runs the same script with Xcode 26.6 on macOS 26.

`CodexStatsCore` contains the log adapters, deterministic classifier, SQLite index actor, analytics aggregation, and burst policy. `CodexStatsApp` contains the AppKit lifecycle, SwiftUI dashboard, sorting, and notification permission flow.

See [Swift guidelines](docs/swift-guidelines.md) and the [analytics design](openspec/changes/ai-agnostic-incremental-analytics/design.md).
