import AppKit
import CodexStatsCore
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let configStore = CodexStatsConfigStore()
    private var config = CodexStatsConfig()
    private var index: AnalyticsIndex?
    private var classifier: WordClassifier?
    private var dashboard: StatsWindowController?
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var refreshTask: Task<Void, Never>?
    private var notifications: NotificationService?
    private var notificationSettings: NotificationSettings?
    private var notificationTask: Task<Void, Never>?
    private var snapshot = AnalyticsSnapshot.empty
    private var scanError: String?
    private var isScanning = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let loaded = configStore.load()
        config = loaded.config
        if case .fallbackDefault(let error) = loaded.source { scanError = "Configuration fallback: " + error }
        dashboard = StatsWindowController(
            onRefresh: { [weak self] in self?.refreshScan() },
            onOpenConfig: { [weak self] in self?.openConfig() },
            onFilter: { [weak self] filter in self?.applyFilter(filter) },
            onAddFolder: { [weak self] in self?.addFolder() },
            onRemoveFolder: { [weak self] path in self?.removeFolder(path) },
            onNotifications: { [weak self] enabled in self?.setNotifications(enabled) })
        if let dashboard {
            dashboard.state.notificationsEnabled = config.notificationsEnabled
            notificationSettings = NotificationSettings(
                state: dashboard.state,
                authorize: { [weak self] in
                    guard let self else { return false }
                    let service = self.notifications ?? NotificationService()
                    self.notifications = service
                    return try await service.authorize()
                },
                save: { [weak self] enabled in
                    guard let self else { return }
                    var updated = self.config
                    updated.notificationsEnabled = enabled
                    try self.configStore.save(updated)
                    self.config = updated
                })
        }
        if config.notificationsEnabled { setNotifications(true) }
        installMenus()
        showDashboard()
        updateDashboard()
        initializeIndex()
        timer = Timer.scheduledTimer(
            timeInterval: max(5, config.intervalSeconds), target: self,
            selector: #selector(refreshScan), userInfo: nil, repeats: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showDashboard()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        refreshTask?.cancel()
        notificationTask?.cancel()
    }

    private func initializeIndex() {
        refreshTask = Task {
            do {
                let classifier = try WordClassifier()
                self.classifier = classifier
                let databaseURL = configStore.configURL.deletingLastPathComponent().appendingPathComponent(
                    "analytics.sqlite")
                let index = try AnalyticsIndex(databaseURL: databaseURL, classifier: classifier)
                self.index = index
                snapshot = try await index.snapshot(roots: config.resolvedRootURLs())
                updateDashboard()
                refreshScan()
            } catch { showError(error) }
        }
    }

    @objc private func refreshScan() {
        guard !isScanning, let index else { return }
        isScanning = true
        scanError = nil
        dashboard?.state.files = 0
        dashboard?.state.totalFiles = 0
        updateDashboard()
        let roots = config.resolvedRootURLs()
        refreshTask = Task {
            defer { isScanning = false; updateDashboard() }
            do {
                let result = try await index.refresh(roots: roots) { [weak self] progress in
                    guard progress.files.isMultiple(of: 10) || progress.files == progress.total else { return }
                    Task { @MainActor in
                        self?.dashboard?.state.files = progress.files
                        self?.dashboard?.state.totalFiles = progress.total
                        self?.dashboard?.state.bytesRead = progress.bytesRead
                        if let partial = progress.snapshot, let self {
                            self.snapshot = partial
                            self.updateDashboard()
                        }
                    }
                }
                snapshot =
                    roots == config.resolvedRootURLs()
                    ? result.snapshot : try await index.snapshot(roots: config.resolvedRootURLs())
                dashboard?.state.bytesRead = result.bytesRead
                if dashboard?.state.filter != AnalyticsFilter() { await refreshFilteredSnapshot() }
                try await evaluateNotifications(result.liveMessages, index: index)
            } catch is CancellationError { return } catch { showError(error) }
        }
    }

    private func applyFilter(_ filter: AnalyticsFilter) {
        Task { await refreshFilteredSnapshot() }
    }

    private func refreshFilteredSnapshot() async {
        guard let index, let dashboard else { return }
        let filter = dashboard.state.filter
        do {
            let filtered = try await index.snapshot(filter: filter, roots: config.resolvedRootURLs())
            var navigationFilter = filter
            navigationFilter.thread = nil
            let navigation =
                filter.thread == nil
                ? filtered
                : try await index.snapshot(filter: navigationFilter, roots: config.resolvedRootURLs())
            guard dashboard.state.filter == filter else { return }
            updateDashboard(filtered: filtered)
            dashboard.state.threads = navigation.threads
        } catch { showError(error) }
    }

    private func updateDashboard(filtered: AnalyticsSnapshot? = nil) {
        guard let dashboard else { return }
        let displayed = filtered ?? (dashboard.state.filter == AnalyticsFilter() ? snapshot : dashboard.state.snapshot)
        dashboard.update(snapshot: displayed, isScanning: isScanning, error: scanError, roots: config.rootPaths)
        dashboard.state.models = snapshot.models
        if dashboard.state.filter.model == nil, dashboard.state.filter.since == nil {
            dashboard.state.threads = snapshot.threads
        }
        statusItem?.button?.image = NSImage(
            systemSymbolName: isScanning ? "arrow.clockwise" : "waveform.path", accessibilityDescription: "Swear Stats")
        statusItem?.button?.image?.isTemplate = true
    }

    private func addFolder() {
        let picker = NSOpenPanel()
        picker.title = "Attach a log folder"
        picker.prompt = "Attach"
        picker.canChooseFiles = false
        picker.canChooseDirectories = true
        picker.allowsMultipleSelection = true
        guard picker.runModal() == .OK else { return }
        let existing = Set(config.resolvedRootURLs())
        config.rootPaths += picker.urls.filter { !existing.contains($0.standardizedFileURL.resolvingSymlinksInPath()) }
            .map(\.path)
        persistFolders()
    }

    private func removeFolder(_ path: String) {
        config.rootPaths.removeAll { $0 == path }
        dashboard?.state.filter = AnalyticsFilter()
        persistFolders()
    }

    private func persistFolders() {
        do { try configStore.save(config); updateDashboard(); refreshScan() } catch { showError(error) }
    }

    private func setNotifications(_ enabled: Bool) {
        guard let notificationSettings, dashboard?.state.notificationRequestPending != true else { return }
        notificationTask = Task { await notificationSettings.setEnabled(enabled) }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if dashboard?.state.notificationNeedsSettings == true { setNotifications(true) }
    }

    private func evaluateNotifications(_ messages: [MessageFact], index: AnalyticsIndex) async throws {
        guard config.notificationsEnabled, let classifier else { return }
        var policy = try await index.loadBurstState()
        let reminder = try policy.evaluate(messages, classifier: classifier)
        try await index.saveBurstState(policy)
        if let reminder {
            let service = notifications ?? NotificationService()
            notifications = service
            try await service.send(reminder)
        }
    }

    private func showError(_ error: Error) {
        scanError = error.localizedDescription
        updateDashboard()
    }

    @objc private func showDashboard() {
        dashboard?.showWindow(nil)
        dashboard?.window?.deminiaturize(nil)
        dashboard?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openConfig() { NSWorkspace.shared.open(configStore.configURL) }

    private func installMenus() {
        let menu = NSMenu()
        let show = NSMenuItem(title: "Show Swear Stats", action: #selector(showDashboard), keyEquivalent: "0")
        show.target = self
        menu.addItem(show)
        let settings = NSMenuItem(title: "Configuration…", action: #selector(openConfig), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(title: "Quit Swear Stats", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        let main = NSMenu()
        let item = NSMenuItem()
        item.submenu = menu
        main.addItem(item)
        NSApp.mainMenu = main
        let status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.menu = menu.copy() as? NSMenu
        status.button?.toolTip = "Swear Stats"
        statusItem = status
    }
}
