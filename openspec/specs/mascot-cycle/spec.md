# mascot-cycle Specification

## Purpose
Give fresh profanity a repeatable comic bottle routine whose intensity follows live input frequency, while preserving exact counts and a stable native dashboard.

## Requirements
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
Heat SHALL rise only from consumed fresh bottles and decay with time. Awake heat SHALL cool at 0.04 units per second and sleeping heat at 0.1 units per second. Rowdy behavior SHALL start at heat four and remain active until heat drops below two. The buildup before sleep SHALL last ten seconds, sleep forty seconds, and the wake-up drinking scene eight seconds. Elevated heat SHALL enable custom rowdy bottle behavior and commit a readable buildup before sleep. Reduced input frequency SHALL slow or reverse escalation. Quiet input SHALL NOT create heat or bottles.

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

#### Scenario: Readable coalesced drinks
- **GIVEN** a fresh batch contains multiple profanities
- **WHEN** the drinking scene starts and further hits arrive during its 4.8-second window
- **THEN** the scene keeps its original start and its full duration, using normal-speed clips separated by deliberate resting pauses
- **AND** additional hits count immediately without accelerating or restarting the artwork

### Requirement: Stable and accessible stage
The dashboard SHALL reserve a fixed stage for the routine. When Desktop Bro is enabled, the character SHALL render in its floating desktop panel instead, while the dashboard keeps the same reserved space. Loading, refresh, filters, and phases SHALL NOT shift surrounding controls or chart content. Piles and bottle arcs SHALL stay within the stage. The stage SHALL NOT intercept chart selection. Reduce Motion SHALL retain timed phase progression using stationary representative poses.

#### Scenario: Refresh and active routine
- **WHEN** the dashboard refreshes or Bro changes between drinking, throwing, rowdy, sleeping, and sobering
- **THEN** stage height stays constant and chart filtering remains available

#### Scenario: Resume walking after a gesture
- **GIVEN** a drink or throw interrupts a walking Bro
- **WHEN** the action and its resting pause finish
- **THEN** Bro resumes at the same position without catching up to an unseen route
- **AND** horizontal motion renders smoothly while sprite steps retain their normal cadence

#### Scenario: Reduced motion and narrow window
- **GIVEN** Reduce Motion is enabled or the stage is narrow
- **WHEN** fresh events and time advance the cycle
- **THEN** accounting and phases remain correct, animated movement is suppressed, and artwork stays within the reserved bounds


### Requirement: Desktop Bro
The app SHALL offer a persistent Desktop Bro toggle in its application and status menus. The desktop panel SHALL reuse the existing live cycle, remain transparent above other apps without activating Swear Stats, support dragging and a hide context menu, and let clicks outside the character pass through. Position SHALL survive restarts and be constrained to an available screen.

#### Scenario: Enable and hide
- **GIVEN** Bro has an active bottle cycle in the dashboard
- **WHEN** Desktop Bro is enabled, then hidden through its context menu
- **THEN** the same cycle moves to the desktop and back to the reserved dashboard stage without resetting
- **AND** controls and chart geometry do not shift

#### Scenario: Work in another app
- **WHEN** another app is active and the pointer is outside Bro
- **THEN** Bro remains visible without taking keyboard focus and the underlying app receives clicks

#### Scenario: Restore after a screen change
- **GIVEN** a saved location lies outside available displays
- **WHEN** the desktop panel is restored or displays change
- **THEN** Bro is constrained to a visible screen area

#### Scenario: Drop near the right edge
- **WHEN** Bro is dragged or his panel is moved partly beyond a display edge
- **THEN** the whole walking stage is constrained to a visible display after the move
- **AND** later animation frames cannot carry him offscreen
