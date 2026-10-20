import AppKit
import Foundation
import CodexStatsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let configStore = CodexStatsConfigStore()

    private var statusItem: NSStatusItem?
    private var dashboard: StatsWindowController?
    private var scanError: String?
    private var timer: Timer?
    private var isScanning = false
    private var config = CodexStatsConfig()
    private var loadSource: CodexStatsConfigStore.LoadSource = .createdDefault
    private var snapshot = CodexStatsSnapshot.empty

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadConfig()
        installStatusItem()
        installApplicationMenu()
        dashboard = StatsWindowController(
            onRefresh: { [weak self] in self?.refreshScan() },
            onOpenConfig: { [weak self] in self?.openConfig() }
        )
        showDashboard()
        refreshScan()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showDashboard()
        return true
    }

    private func installApplicationMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        let showItem = NSMenuItem(title: "Show Codex Stats", action: #selector(showDashboard), keyEquivalent: "0")
        showItem.target = self
        appMenu.addItem(showItem)
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Codex Stats", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)
        NSApp.mainMenu = mainMenu
    }

    @objc private func showDashboard() {
        dashboard?.showWindow(nil)
        dashboard?.window?.deminiaturize(nil)
        dashboard?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateDashboard() {
        var error = scanError
        if case .fallbackDefault(let reason) = loadSource {
            error = [error, "Config fallback: \(reason)"].compactMap { $0 }.joined(separator: "\n")
        }
        dashboard?.update(snapshot: snapshot, isScanning: isScanning, error: error, roots: config.rootPaths)
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }

    private func loadConfig() {
        let loaded = configStore.load()
        config = loaded.config
        loadSource = loaded.source
        scheduleTimer()
    }

    private func scheduleTimer() {
        timer?.invalidate()

        let interval = max(config.intervalSeconds, 30)
        timer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(refreshScan),
            userInfo: nil,
            repeats: true
        )
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.menu = NSMenu()
        item.menu?.delegate = self
        statusItem = item
        updateStatusIcon()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    @objc
    private func refreshScan() {
        guard isScanning == false else {
            return
        }

        isScanning = true
        scanError = nil
        dashboard?.state.scannedFiles = 0
        dashboard?.state.scannedMessages = 0
        updateStatusIcon()
        updateDashboard()

        let currentConfig = config
        Task.detached(priority: .utility) {
            let result: Result<CodexStatsSnapshot, Error>
            do {
                let snapshot = try CodexStatsScanner().scan(config: currentConfig) { files, messages in
                    Task { @MainActor in
                        self.dashboard?.state.scannedFiles = files
                        self.dashboard?.state.scannedMessages = messages
                    }
                }
                result = .success(snapshot)
            } catch {
                result = .failure(error)
            }

            await MainActor.run {
                self.finishScan(result)
            }
        }
    }

    private func finishScan(_ result: Result<CodexStatsSnapshot, Error>) {
        isScanning = false

        switch result {
        case .success(let snapshot):
            self.snapshot = snapshot
        case .failure(let error):
            scanError = error.localizedDescription
        }

        updateStatusIcon()
        rebuildMenu()
        updateDashboard()
    }

    private func updateStatusIcon() {
        guard let button = statusItem?.button else {
            return
        }

        button.title = ""
        button.imagePosition = .imageOnly

        let imageName: String
        let tooltip: String

        if isScanning {
            imageName = "arrow.clockwise"
            tooltip = "Codex Stats: scanning"
        } else if case .fallbackDefault(let error) = loadSource {
            imageName = "exclamationmark.triangle.fill"
            tooltip = "Codex Stats: config fallback (\(error))"
        } else {
            imageName = "chart.bar.doc.horizontal"
            tooltip = "Codex Stats"
        }

        button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: tooltip)
        button.image?.isTemplate = true
        button.toolTip = tooltip
    }

    private func rebuildMenu() {
        guard let menu = statusItem?.menu else {
            return
        }

        menu.removeAllItems()
        let showItem = NSMenuItem(title: "Show Codex Stats", action: #selector(showDashboard), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)
        menu.addItem(.separator())
        menu.addItem(infoItem(title: "Codex Stats"))
        menu.addItem(infoItem(title: summaryLine()))

        if case .fallbackDefault(let error) = loadSource {
            menu.addItem(infoItem(title: "Config fallback: \(error)"))
        }

        menu.addItem(infoItem(title: "Roots: \(config.rootPaths.joined(separator: ", "))"))
        menu.addItem(infoItem(title: "Interval: \(Int(config.intervalSeconds))s"))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(infoItem(title: "Files: \(snapshot.scannedFiles)"))
        menu.addItem(infoItem(title: "User messages: \(snapshot.userMessages)"))
        menu.addItem(infoItem(title: "Profanity hits: \(snapshot.profanityHits)"))
        menu.addItem(infoItem(title: "Exact total: \(snapshot.exactMatchTotal)"))

        if snapshot.exactMatchCounts.isEmpty == false {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(infoItem(title: "Exact filters"))
            for token in config.exactMatchTokens {
                let count = snapshot.exactMatchCounts[token.lowercased(), default: 0]
                menu.addItem(infoItem(title: "  \(token) — \(count)"))
            }
        }

        if snapshot.topTokens.isEmpty == false {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(infoItem(title: "Top profanity"))
            for entry in snapshot.topTokens {
                menu.addItem(infoItem(title: "  \(entry.token) — \(entry.count)"))
            }
        }

        menu.addItem(NSMenuItem.separator())

        let refreshItem = NSMenuItem(title: isScanning ? "Scanning..." : "Rescan Now", action: #selector(refreshScan), keyEquivalent: "")
        refreshItem.target = self
        refreshItem.isEnabled = isScanning == false
        menu.addItem(refreshItem)

        let reloadItem = NSMenuItem(title: "Reload Config", action: #selector(reloadConfig), keyEquivalent: "")
        reloadItem.target = self
        menu.addItem(reloadItem)

        let openConfigItem = NSMenuItem(title: "Open Config", action: #selector(openConfig), keyEquivalent: "")
        openConfigItem.target = self
        menu.addItem(openConfigItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func summaryLine() -> String {
        let scanAge = snapshot.finishedAt == .distantPast ? "never" : DateFormatter.codexStats.relativeString(for: snapshot.finishedAt)
        return "Last scan: \(scanAge)"
    }

    private func infoItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc
    private func reloadConfig() {
        loadConfig()
        refreshScan()
    }

    @objc
    private func openConfig() {
        _ = NSWorkspace.shared.open(configStore.configURL)
    }

    @objc
    private func quit() {
        NSApp.terminate(nil)
    }
}

private extension DateFormatter {
    static let codexStats: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    func relativeString(for date: Date) -> String {
        let delta = Int(Date().timeIntervalSince(date))
        if delta < 60 {
            return "\(delta)s ago"
        }
        if delta < 3600 {
            return "\(delta / 60)m ago"
        }
        return Self.codexStats.string(from: date)
    }
}
