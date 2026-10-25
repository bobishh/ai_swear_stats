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
    @Published var showFolders = false
}

@MainActor
struct DashboardActions {
    var refresh: () -> Void
    var openConfig: () -> Void
    var filter: (AnalyticsFilter) -> Void
    var addFolder: () -> Void
    var removeFolder: (String) -> Void
    var notifications: (Bool) -> Void
    var sound: (Bool) -> Void
    var previewSound: () -> Void
}
