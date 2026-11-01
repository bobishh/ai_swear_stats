import AppKit

@MainActor
final class AppMenus: NSObject {
    private let onShow: () -> Void
    private let onDesktopToggle: (Bool) -> Void
    private let onRefresh: () -> Void
    private let onConfig: () -> Void
    private var desktopBroItems: [NSMenuItem] = []
    private let statusItem: NSStatusItem

    init(
        desktopBroEnabled: Bool,
        onShow: @escaping () -> Void,
        onDesktopToggle: @escaping (Bool) -> Void,
        onRefresh: @escaping () -> Void,
        onConfig: @escaping () -> Void
    ) {
        self.onShow = onShow
        self.onDesktopToggle = onDesktopToggle
        self.onRefresh = onRefresh
        self.onConfig = onConfig

        let menu = NSMenu()
        let show = NSMenuItem(title: "Show Swear Stats", action: #selector(showDashboard), keyEquivalent: "0")
        menu.addItem(show)
        let desktopBro = NSMenuItem(title: "Desktop Bro", action: #selector(toggleDesktopBro), keyEquivalent: "")
        desktopBro.state = desktopBroEnabled ? .on : .off
        desktopBroItems.append(desktopBro)
        menu.addItem(desktopBro)
        let refresh = NSMenuItem(title: "Refresh", action: #selector(refresh), keyEquivalent: "r")
        refresh.keyEquivalentModifierMask = [.command]
        menu.addItem(refresh)
        menu.addItem(NSMenuItem(title: "Configuration…", action: #selector(openConfig), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit Swear Stats", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        let main = NSMenu()
        let root = NSMenuItem()
        root.submenu = menu
        main.addItem(root)
        NSApp.mainMenu = main

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let statusMenu = menu.copy() as? NSMenu {
            desktopBroItems.append(contentsOf: statusMenu.items.filter { $0.action == #selector(toggleDesktopBro) })
            statusItem.menu = statusMenu
        }
        statusItem.button?.toolTip = "Swear Stats"
        super.init()
        for item in menu.items + (statusItem.menu?.items ?? []) {
            item.target = item.action == #selector(NSApplication.terminate(_:)) ? NSApp : self
        }
    }

    func setDesktopBroEnabled(_ enabled: Bool) {
        desktopBroItems.forEach { $0.state = enabled ? .on : .off }
    }

    func setSyncing(_ syncing: Bool) {
        statusItem.button?.image = NSImage(
            systemSymbolName: syncing ? "arrow.clockwise" : "waveform.path", accessibilityDescription: "Swear Stats")
        statusItem.button?.image?.isTemplate = true
    }

    @objc private func showDashboard() { onShow() }
    @objc private func toggleDesktopBro() {
        let enabled = desktopBroItems.first?.state != .on
        setDesktopBroEnabled(enabled)
        onDesktopToggle(enabled)
    }
    @objc private func refresh() { onRefresh() }
    @objc private func openConfig() { onConfig() }
}
