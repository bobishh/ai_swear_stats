## ADDED Requirements

### Requirement: Every fresh profanity supplies a bottle
The app SHALL feed Bro only profanity counts from newly delivered user messages. Each positive hit SHALL supply exactly one bottle. Awake hits SHALL be consumed immediately, including coalesced batches. Sound and reminder switches SHALL NOT gate the mascot.

#### Scenario: Fresh batch while awake
- **GIVEN** Bro is awake and Sound and burst reminders are off
- **WHEN** a fresh user batch contains three profanities
- **THEN** three bottles are consumed promptly and a gulp followed by an empty-bottle throw is shown
- **AND** no bottle is lost or queued behind a long animation

#### Scenario: Historical refresh
- **WHEN** offensive historical messages are imported, replayed, rebuilt, or filtered
- **THEN** they do not supply bottles or advance the mascot

### Requirement: Escalation follows frequency
Heat SHALL rise only from consumed fresh bottles and decay with time. Elevated heat SHALL enable custom rowdy bottle behavior and commit a readable buildup before sleep. Reduced input frequency SHALL slow or reverse escalation. Quiet input SHALL NOT cause autonomous pacing, generic pet gestures, or newly created bottles.

#### Scenario: Slow input and quiet recovery
- **WHEN** input stops or hits arrive farther apart than their heat persists
- **THEN** Bro gradually sobers and settles without repeated autonomous partying or sleep loops

#### Scenario: Sustained input
- **WHEN** fresh hits build heat through the rowdy and sleep thresholds
- **THEN** Bro drinks, throws empties, becomes rowdy, and falls asleep after a short visible buildup

### Requirement: Sleep accumulates a wake-up stash
While Bro sleeps the app SHALL retain every supplied bottle in a full-bottle stash. Waking with a stash SHALL consume it and show a short drinking scene. The cycle SHALL then choose further sleep or gradual recovery from its remaining heat.

#### Scenario: Wake, drink, and sleep again
- **GIVEN** Bro is sleeping
- **WHEN** enough fresh bottles accumulate and sleep ends
- **THEN** the whole stash is consumed and a drinking scene is shown
- **AND** high remaining heat leads to another sleep rather than resetting cold

#### Scenario: Empty wake and eventual rest
- **GIVEN** input has stopped and no bottles wait
- **WHEN** sleep and cooling finish
- **THEN** Bro eventually sobers and settles without manufacturing a new stash

#### Scenario: Exact counts and pure projection
- **WHEN** batches arrive across sleep and drinking boundaries and snapshots are queried repeatedly
- **THEN** total supplied bottles equal drunk bottles plus the full-bottle stash
- **AND** querying snapshots does not mutate the retained model
- **AND** new awake bottles during the wake-up scene are consumed promptly

### Requirement: Stable and accessible stage
The routine SHALL remain inside a fixed reserved stage. Loading, refresh, filters, and phases SHALL NOT shift surrounding controls or chart content. Piles and bottle arcs SHALL stay within the stage. The stage SHALL NOT intercept chart selection. Reduce Motion SHALL retain timed phase progression using stationary representative poses.

#### Scenario: Refresh and active routine
- **WHEN** the dashboard refreshes or Bro changes between drinking, throwing, rowdy, sleeping, and sobering
- **THEN** stage height stays constant and chart filtering remains available

#### Scenario: Reduced motion and narrow window
- **GIVEN** Reduce Motion is enabled or the stage is narrow
- **WHEN** fresh events and time advance the cycle
- **THEN** accounting and phases remain correct, animated movement is suppressed, and artwork stays within the reserved bounds
