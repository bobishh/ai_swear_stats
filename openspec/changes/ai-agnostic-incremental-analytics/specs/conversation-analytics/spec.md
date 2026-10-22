## ADDED Requirements

### Requirement: Overall and filtered analytics
The dashboard SHALL offer overall, provider/model, and thread views, with word-family rankings, lexical category counts, profanity per thousand words, and profane-message share. Filters SHALL query indexed records without rescanning logs.

#### Scenario: Model selection
- **GIVEN** messages from two providers/models and one unknown model
- **WHEN** a model is selected
- **THEN** counts, threads, ranking, and chart use only that model and overall view restores all records

#### Scenario: Scoped source diagnostics
- **WHEN** a thread, model, or period filter is selected
- **THEN** source counts and diagnostics include only files contributing messages to that selection
- **AND** returning to the overall view restores all attached-source diagnostics

### Requirement: Thread heat
Thread rows SHALL display the percentage of messages containing profanity, counting each message once, and a native blue-to-red heat scale. Color intensity SHALL multiply that share by `messageCount / (messageCount + 20)` to temper small samples. The displayed percentage SHALL remain unadjusted. Selection SHALL remain distinguishable independently of heat color.

#### Scenario: Small sample
- **GIVEN** two conversations with the same profanity percentage and different message counts
- **WHEN** their thread rows are shown
- **THEN** the shorter conversation has a cooler color
- **AND** both show their actual percentage

#### Scenario: Temperature ordering
- **WHEN** Hottest first is selected
- **THEN** threads within the current filters sort by descending weighted heat, then recent activity and identity
- **AND** Recent activity restores chronological ordering without changing the selected thread or analytics filters
- **AND** switching the sort mode shows the beginning of the newly ordered list
- **AND** the selected ordering persists across launches

### Requirement: Temporal intensity
The dashboard SHALL plot profanities per second using fixed minute buckets, including quiet buckets in the displayed interval. Missing timestamps SHALL remain in totals and SHALL be disclosed as excluded from the chart. The graph SHALL be labeled as lexical intensity.

#### Scenario: Sparse events
- **WHEN** offensive messages are separated by a quiet minute
- **THEN** the chart includes a zero-valued quiet bucket and displays each populated bucket as its hit count divided by sixty

### Requirement: Accessible native dashboard
The dashboard SHALL open on launch, reopen from the Dock, permit adding/removing log folders, and show pending, empty, and failure states in English.

#### Scenario: Refresh fails
- **GIVEN** cached statistics
- **WHEN** refresh fails
- **THEN** cached statistics remain visible with a retry action and readable error
