import CodexStatsCore
import Foundation
import SwiftUI

@MainActor
final class DashboardState: ObservableObject {
    @Published var snapshot = AnalyticsSnapshot.empty
    @Published var models: [ModelSummary] = []
    @Published var threads: [ThreadSummary] = []
    @Published var filter = AnalyticsFilter()
    @Published var isScanning = false
    @Published var isSyncing = false
    @Published var error: String?
    @Published var roots: [String] = []
    @Published var files = 0
    @Published var totalFiles = 0
    @Published var bytesRead = 0
    @Published var notificationsEnabled = false
    @Published var notificationRequestPending = false
    @Published var notificationNeedsSettings = false
    @Published var notificationStatus = ""
    @Published var soundEnabled = false
    @Published var mascotCycle = MascotCycle()
    @Published var desktopBroEnabled = false
    @Published var showFolders = false
    @Published var showMascotSettings = false
    @Published var mascotLook = MascotLook.builtIn
    @Published var mascotAppearanceError: String?

    private let mascotWalkClock = MascotWalkClock()
    private let defaults: UserDefaults
    private static let appearancePreference = "mascotAppearanceFolder"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let path = defaults.string(forKey: Self.appearancePreference) {
            do { try selectMascot(from: URL(fileURLWithPath: path)) } catch {
                mascotAppearanceError = error.localizedDescription
            }
        }
    }

    func selectMascot(from folder: URL) throws {
        let appearance = try MascotAppearance.load(from: folder)
        let look = MascotLook(appearance: appearance)
        guard look.isComplete else {
            throw MascotAppearance.InvalidPackage(reason: "Some PNG frames could not be opened.")
        }
        mascotLook = look
        mascotAppearanceError = nil
        defaults.set(folder.path, forKey: Self.appearancePreference)
    }

    func resetMascot() {
        mascotLook = .builtIn
        mascotAppearanceError = nil
        defaults.removeObject(forKey: Self.appearancePreference)
    }

    func mascotPatrolDate(
        snapshot: MascotCycle.Snapshot,
        at date: Date
    ) -> Date {
        let paused = ChartMascotMotion.pausesPatrol(snapshot: snapshot, at: date)
        return mascotWalkClock.advance(at: date, paused: paused)
    }
}

@MainActor
struct DashboardActions {
    var openConfig: () -> Void
    var filter: (AnalyticsFilter) -> Void
    var addFolder: () -> Void
    var removeFolder: (String) -> Void
    var notifications: (Bool) -> Void
    var sound: (Bool) -> Void
    var previewSound: () -> Void
    var desktopMascot: (Bool) -> Void = { _ in }
}
