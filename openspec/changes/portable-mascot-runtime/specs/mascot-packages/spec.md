## ADDED Requirements

### Requirement: Versioned data-only appearance packages
A mascot package SHALL declare identity, version, attribution/license, behavior compatibility, asset hashes, clips with authored cadence, anchors, and interaction bounds. Packages SHALL contain data assets only and SHALL NOT execute code or choose network/model providers.

#### Scenario: Install a compatible web package
- **GIVEN** an HTTPS URL or local package file
- **WHEN** its manifest and complete asset set validate against a supported behavior contract
- **THEN** the app can install an immutable version and activate its appearance
- **AND** existing behavior counters and detector configuration remain unchanged

### Requirement: Required actions are validated before activation
Behavior contracts SHALL distinguish required actions from optional actions with explicit fallbacks. Missing required clips, unsupported required features, invalid references, or incompatible versions SHALL reject activation.

#### Scenario: Ordinary pet sheet lacks a drinking action
- **WHEN** a package without required bottle-bro clips is selected for that behavior
- **THEN** activation fails clearly and the current compatible skin remains active
- **AND** unrelated gestures are not silently substituted

### Requirement: Atomic bounded installation
Installation SHALL stage and validate bounded archives and decoded assets before changing the active catalog reference. Asset paths SHALL remain inside the package; executable payloads, symlinks, and package-defined network requests SHALL be rejected.

#### Scenario: Interrupted download or invalid archive
- **WHEN** download, integrity, path, dimension, or compatibility validation fails
- **THEN** the previous package and current behavior scene remain usable

### Requirement: Playback cadence and behavior pacing remain separate
A skin SHALL define its clips' natural frame cadence. Behavior SHALL own action order, interruptions, and resting pauses; increasing a pause SHALL NOT slow the action's individual frames.

#### Scenario: More time to notice a gesture
- **WHEN** a profile increases the pause after a throw
- **THEN** the throw plays at its authored speed and its final pose holds longer
