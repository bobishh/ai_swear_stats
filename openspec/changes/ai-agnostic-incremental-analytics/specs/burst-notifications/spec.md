## ADDED Requirements

### Requirement: Live burst alerts
The app SHALL provide opt-in English joke notifications when at least five profanities occur in two minutes across two new messages. It SHALL suppress historical import, replay, and replacement alerts, enforce a fifteen-minute cooldown, and rearm only after a quiet window. Notification policy state SHALL persist across restarts.

#### Scenario: Burst and cooldown
- **GIVEN** notifications are enabled and the policy is armed
- **WHEN** two new messages cross the threshold and further messages arrive during cooldown
- **THEN** exactly one English notification is sent without chat excerpts

#### Scenario: Historical import
- **WHEN** a folder is imported or rebuilt with offensive historical messages
- **THEN** no notification is sent even if message timestamps are recent

#### Scenario: Permission denied
- **WHEN** notification permission is denied
- **THEN** analytics continue and the UI reports that notifications are unavailable with an action to open macOS notification settings
- **AND** indexing refreshes do not erase the permission status

#### Scenario: Permission pending
- **WHEN** macOS waits for a notification permission response
- **THEN** the reminder switch shows a disabled pending state until the result is known and persisted
