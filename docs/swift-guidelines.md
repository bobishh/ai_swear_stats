# Swift quality baseline

## Sources

- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/): clarity at call sites, meaningful names, value-oriented APIs, and documentation for non-obvious contracts.
- [Swift concurrency guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html): isolate UI state to MainActor and serialize mutable index state with an actor. Prefer retained structured tasks, cancellation propagation, and immutable Sendable records.
- [Swift 6 data race safety](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/dataracesafety/): resolve isolation diagnostics rather than suppressing checks.
- [Official swift-format](https://github.com/swiftlang/swift-format): one canonical formatter; strict lint fails on warnings.
- [SwiftLint](https://github.com/realm/SwiftLint): additional safety and complexity checks. Tooling baseline: 0.65.1.

## Project rules

Use four-space indentation and the checked-in formatter configuration. SwiftLint handles safety and complexity; formatting rules are owned by swift-format to avoid contradictory corrections. Compiler warnings fail checks. Treat SQLite errors as user-visible failures while retaining the last successful snapshot. Commit message rows and source positions together. Avoid retaining full source chats and tool output in the application index.

Separate source adapters, lexical classification, aggregation, notification policy, persistence, and presentation. Test these boundaries with synthetic fixtures. A word classifier change requires positive cases and innocent lookalikes; ingestion changes require append/restart/partial-tail and rollback evidence.

## Commands

```sh
brew install swiftlint
swift format format --in-place --recursive Sources Tests Package.swift
./scripts/check.sh
```

The check script requires the OpenSpec CLI already used by this project. Install it with `npm install --global @fission-ai/openspec` when needed. CI runs the same script on macOS.
