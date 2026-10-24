import AppKit
import CodexStatsCore
import SwiftUI

@MainActor
final class StatsWindowController: NSWindowController {
    let state = DashboardState()
    private let onFilter: (AnalyticsFilter) -> Void

    init(
        onRefresh: @escaping () -> Void, onOpenConfig: @escaping () -> Void,
        onFilter: @escaping (AnalyticsFilter) -> Void = { _ in },
        onAddFolder: @escaping () -> Void = {}, onRemoveFolder: @escaping (String) -> Void = { _ in },
        onNotifications: @escaping (Bool) -> Void = { _ in }, onSound: @escaping (Bool) -> Void = { _ in },
        onPreviewSound: @escaping () -> Void = {}
    ) {
        self.onFilter = onFilter
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1_100, height: 780),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "Swear Stats"
        window.minSize = NSSize(width: 900, height: 650)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        let actions = DashboardActions(
            refresh: onRefresh, openConfig: onOpenConfig,
            filter: { [weak self] in self?.selectFilter($0) }, addFolder: onAddFolder,
            removeFolder: onRemoveFolder, notifications: onNotifications, sound: onSound,
            previewSound: onPreviewSound)
        window.contentView = NSHostingView(rootView: DashboardView(state: state, actions: actions))
        window.center()
    }

    required init?(coder: NSCoder) { nil }

    func selectFilter(_ filter: AnalyticsFilter) {
        state.filter = filter
        onFilter(filter)
    }

    func update(snapshot: AnalyticsSnapshot, isScanning: Bool, error: String?, roots: [String]) {
        state.snapshot = snapshot
        state.isScanning = isScanning
        state.error = error
        state.roots = roots
    }
}
