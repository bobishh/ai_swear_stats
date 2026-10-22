# Swift working agreements

Read README.md and docs/swift-guidelines.md before edits. Follow the user's instructions and keep changes scoped.

- Author concrete Given/When/Then acceptance tests before changing behavior; verify an intended failure before implementing core logic.
- Use Swift 6 data-race checking. Keep AppKit/SwiftUI state on MainActor and SQLite access on AnalyticsIndex. Never suppress isolation with unchecked Sendable or unsafe nonisolated declarations.
- Use structured, retained tasks, cancellation checks, value types, explicit error states, and parameterized SQL. Keep methods and responsibilities small.
- No force casts, force unwraps, or force try. Do not disable linters to hide new violations.
- Source logs remain read-only. Never commit local databases, logs, configuration, screenshots containing chat data, or credentials.
- Run ./scripts/check.sh before completion. Verify UI changes through native app flows after implementation, including pending/error state.
- Do not stage, commit, or push unless explicitly requested.
