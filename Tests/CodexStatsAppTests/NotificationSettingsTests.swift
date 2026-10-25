import Foundation
import Testing
@testable import CodexStatsApp

@Suite(.serialized)
@MainActor
struct NotificationSettingsTests {
    @Test("Given a pending permission request, when statistics refresh, then reminder state stays pending until saved")
    func permissionPending() async throws {
        let state = DashboardState()
        #expect(state.notificationStatus.isEmpty)
        var complete: CheckedContinuation<Bool, any Error>?
        var saved: [Bool] = []
        let settings = NotificationSettings(
            state: state,
            authorize: {
                try await withCheckedThrowingContinuation { complete = $0 }
            }, save: { saved.append($0) })
        let request = Task { await settings.setEnabled(true) }
        while complete == nil { await Task.yield() }
        #expect(state.notificationRequestPending)
        #expect(state.notificationsEnabled)
        #expect(state.notificationStatus == "Waiting for macOS notification permission…")
        state.snapshot = .empty
        #expect(state.notificationRequestPending)
        complete?.resume(returning: true)
        await request.value
        #expect(state.notificationsEnabled)
        #expect(!state.notificationRequestPending)
        #expect(state.notificationStatus.isEmpty)
        #expect(saved == [true])
        await settings.setEnabled(false)
        #expect(!state.notificationsEnabled)
        #expect(state.notificationStatus.isEmpty)
        #expect(saved == [true, false])
    }

    @Test("Given denied permission, when enabling reminders, then settings recovery stays visible across refreshes")
    func permissionDenied() async {
        let state = DashboardState()
        let settings = NotificationSettings(state: state, authorize: { false }, save: { _ in })
        await settings.setEnabled(true)
        #expect(!state.notificationsEnabled)
        #expect(state.notificationNeedsSettings)
        #expect(state.notificationStatus.contains("macOS"))
        #expect(state.notificationStatus.contains("Notification Settings"))
        state.isScanning = true
        state.error = nil
        #expect(state.notificationNeedsSettings)
        #expect(!state.notificationRequestPending)
    }

    @Test("Given authorization or persistence failure, when enabling, then the toggle resets and explains retry")
    func permissionFailure() async {
        let state = DashboardState()
        let settings = NotificationSettings(state: state, authorize: { throw TestError.failed }, save: { _ in })
        await settings.setEnabled(true)
        #expect(!state.notificationsEnabled)
        #expect(state.notificationStatus.contains("Could not enable"))
        #expect(!state.notificationRequestPending)
        let failedSave = NotificationSettings(state: state, authorize: { true }, save: { _ in throw TestError.failed })
        await failedSave.setEnabled(true)
        #expect(!state.notificationsEnabled)
        #expect(state.notificationStatus.contains("Could not enable"))
    }
}

private enum TestError: Error { case failed }
