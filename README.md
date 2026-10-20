# Codex Stats

Native macOS profanity counter for user messages in local Codex JSONL logs.

## Run

```sh
./run-app.sh
```

Requires macOS 13+ and Swift 6.3+. Builds an optimized application at
`.build/Codex Stats.app` and opens its dashboard. The app appears in the Dock;
click its Dock icon to reopen a closed window. The menu bar icon also offers
**Show Codex Stats**. Use Command-Q to quit.

The dashboard displays scan progress, totals, and the most frequent matching
words. Counts cover user messages, not assistant responses. Each scan reads
the configured files in full; unchanged files are not cached. Large archives
can take time on the first and subsequent scans.

Default roots: `~/.codex` and `~/.codex-work`. Configuration lives at
`~/Library/Application Support/codex_stats/config.json`; use **Настройки…** to
open it. After editing configuration, use **Reload Config** in the menu bar.

## Verify

```sh
swift test
```

Tests cover counting, Unicode JSONL with CRLF and malformed lines, progress
reporting, configuration fallback, window reopening, and scan error state.
