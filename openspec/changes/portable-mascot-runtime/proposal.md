## Why

Swear Stats currently binds a reusable conversation engine and one hard-coded mascot to a macOS host. Supporting Windows and Linux, downloadable character styling, and reactions to events beyond profanity requires explicit boundaries before adding more platform code or detectors.

## What Changes

- Preserve the Swift analytics engine and prove its behavior on macOS, Windows, and Linux before choosing or replacing UI hosts.
- Define a platform-neutral scene contract and host capabilities for dashboard and desktop presentation.
- Define versioned, data-only mascot packages that can be installed from a file or an HTTPS URL.
- Separate visual packages, behavior profiles, and signal detectors so changing a character does not change detection or counting.
- Define bounded live-chat input, exact and contextual detectors, deduplicated signals, and optional local or explicitly enabled remote model providers.

This proposal defines the next architecture. It does not claim that non-macOS builds, package installation, or contextual models are already implemented.

## Capabilities

### New Capabilities

- `platform-runtime`: Portable engine semantics, scene protocol, and platform host capabilities.
- `mascot-packages`: Downloadable character assets with strict behavior compatibility and atomic activation.
- `chat-signals`: Live event admission, extensible detectors, model-backed candidates, and behavior bindings.

### Modified Capabilities

None in this proposal. The existing mascot-cycle contract remains authoritative until its behavior is extracted without semantic changes.

## Impact

The macOS app remains the working reference. Core parsing, classification, SQLite indexing, and acceptance fixtures are reused. Pure mascot behavior and geometry move behind the same engine boundary incrementally; AppKit window handling stays in the macOS host. No Rust rewrite, marketplace service, downloaded executable plugins, or default transmission of chats is introduced by this design.
