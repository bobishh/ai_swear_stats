## ADDED Requirements

### Requirement: Portable engine semantics
The engine SHALL expose parsing, classification, persistent indexing, accepted signals, and behavior scenes without importing a platform UI framework. macOS, Windows, and Linux SHALL run the same semantic acceptance fixtures before being declared supported.

#### Scenario: Same synthetic logs on three platforms
- **GIVEN** identical supported log records and dictionary resources
- **WHEN** the engine imports, appends, and reopens them on each target
- **THEN** facts, counts, model attribution, and replay suppression match

### Requirement: Host-owned operating-system integration
Hosts SHALL own windowing, file selection/change notifications, application storage locations, audio, notifications, and screen interaction. Each host SHALL report supported presentation capabilities explicitly.

#### Scenario: Compositor cannot provide a desktop overlay
- **WHEN** the host cannot satisfy transparent overlay or pointer-passthrough requirements
- **THEN** the same behavior instance continues on a supported dashboard surface
- **AND** the app does not claim unsupported desktop behavior or reset the cycle

### Requirement: Stable engine and scene interface
The engine SHALL expose one versioned command/event contract. A cross-language host MAY use a supervised JSONL process transport; an in-process host SHALL NOT require a child process only for architectural symmetry. Scene order and action deadlines SHALL have one authoritative engine owner.

#### Scenario: Reconnect after engine restart
- **WHEN** a process host reconnects
- **THEN** it restores a current snapshot and ordered event sequence
- **AND** it does not replay historical mascot actions

#### Scenario: Renderer and pointer geometry
- **WHEN** a host renders an interpolated scene and evaluates pointer passthrough
- **THEN** both use the same normalized scene projection and screen transform
