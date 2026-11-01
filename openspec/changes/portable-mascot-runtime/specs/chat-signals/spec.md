## ADDED Requirements

### Requirement: Role-aware live detector inputs
DetectorRuntime SHALL receive canonical live event metadata and only the bounded input needed by each detector. Existing durable word facts SHALL NOT become a transcript store. Full-turn context SHALL be ephemeral and scoped by role, thread, count, size, and age.

#### Scenario: Assistant quotes user profanity
- **WHEN** the assistant repeats an offensive word
- **THEN** a user-profanity detector excludes that quote
- **AND** a separate permitted conversational detector can still use the canonical turn in its bounded context

### Requirement: Typed admitted signals
Detectors SHALL emit versioned candidates with evidence or an unknown result. DetectorRuntime SHALL own admission, deduplication, confidence policy, live/replay gating, and stale-result rejection. Accepted profanity payloads SHALL preserve exact counts.

#### Scenario: Delayed superseded inference
- **WHEN** a model result arrives after its input window was superseded or expired
- **THEN** it does not trigger an old mascot action

#### Scenario: Replay and detector update
- **WHEN** the index is rebuilt, messages replay, or a detector version changes
- **THEN** existing historical input does not become a new live trigger

### Requirement: Bindings target behavior inputs
Profiles SHALL bind accepted signal kinds to app-known behavior input commands. Detectors and visual packages SHALL NOT directly mutate behavior state or select sprite frames.

#### Scenario: One signal, different characters
- **WHEN** two compatible behavior instances subscribe to the same accepted signal
- **THEN** each owns its resulting state and counters
- **AND** selecting another skin changes artwork without changing signal admission

### Requirement: Deterministic and model-backed detectors share an interface
The runtime SHALL support exact rules and optional model adapters behind the same bounded input/output contract. Structured failure patterns SHALL use actual structured outcomes rather than arbitrary text guesses. An unknown model result SHALL cause no action.

#### Scenario: Model unavailable
- **WHEN** a contextual model is absent, unsupported, or fails inference
- **THEN** exact detectors and the rest of the app continue functioning

### Requirement: Model execution is separately enabled and evaluated
Installing a skin SHALL NOT download or invoke a model. Local model execution SHALL obey explicit resource limits. Remote processing SHALL remain disabled until a user selects its provider and enables the detector with its data scope. Each detector SHALL have role, language, false-positive, duplicate, latency, unknown, and replay fixtures before becoming a default.

#### Scenario: Skin requests a remote model
- **WHEN** a package attempts to require a provider or transmit chat context
- **THEN** that request is not executed as part of package installation
- **AND** existing provider settings and credentials remain unchanged
