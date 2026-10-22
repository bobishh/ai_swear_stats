import Foundation

@MainActor
final class NotificationSettings {
    private let state: DashboardState
    private let authorize: () async throws -> Bool
    private let save: (Bool) throws -> Void

    init(state: DashboardState, authorize: @escaping () async throws -> Bool, save: @escaping (Bool) throws -> Void) {
        self.state = state
        self.authorize = authorize
        self.save = save
    }

    func setEnabled(_ enabled: Bool) async {
        guard !state.notificationRequestPending else { return }
        let previous = state.notificationsEnabled
        state.notificationsEnabled = enabled
        state.notificationNeedsSettings = false
        state.notificationRequestPending = enabled
        state.notificationStatus = enabled ? "Waiting for macOS notification permission…" : "Burst reminders are off."
        defer { state.notificationRequestPending = false }
        do {
            let allowed = enabled ? try await authorize() : false
            try Task.checkCancellation()
            try save(allowed)
            state.notificationsEnabled = allowed
            state.notificationNeedsSettings = enabled && !allowed
            if enabled {
                state.notificationStatus =
                    allowed
                    ? "English reminders · 5 hits / 2 min · 15 min cooldown."
                    : "Blocked by macOS. Allow Swear Stats in Notification Settings, then try again."
            }
        } catch {
            state.notificationsEnabled = previous
            state.notificationStatus =
                "Could not \(enabled ? "enable" : "disable") reminders: \(error.localizedDescription)"
        }
    }
}
