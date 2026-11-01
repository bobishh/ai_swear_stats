import AppKit
import SwiftUI

@MainActor
final class DesktopBroController {
    static let preferenceKey = "desktopBroEnabled"
    private static let originKey = "desktopBroOrigin"
    private static let scale: CGFloat = 1.5
    private static let stage = NSSize(width: 320 * scale, height: 90 * scale)
    private static let actor = NSSize(width: 56 * scale, height: 61 * scale)

    let state: DashboardState
    let panel: NSPanel
    var onEnabledChanged: ((Bool) -> Void)?
    private let defaults: UserDefaults
    private let openDashboard: () -> Void
    private var trackingTimer: Timer?
    private var observers: [NSObjectProtocol] = []

    init(state: DashboardState, defaults: UserDefaults = .standard, openDashboard: @escaping () -> Void = {}) {
        self.state = state
        self.defaults = defaults
        self.openDashboard = openDashboard
        panel = DesktopBroPanel(
            contentRect: NSRect(origin: .zero, size: Self.stage),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        let bro = DesktopBroInteractionView(rootView: AnyView(EmptyView()))
        bro.frame = NSRect(origin: .zero, size: Self.stage)
        bro.mouseDownAction = { [weak self] (event: NSEvent) in
            guard let self else { return }
            self.panel.ignoresMouseEvents = false
            (self.panel as? DesktopBroPanel)?.isDragging = true
            defer {
                (self.panel as? DesktopBroPanel)?.isDragging = false
                self.clampToVisibleScreen()
                self.saveOrigin()
            }
            self.panel.performDrag(with: event)
        }
        bro.contextMenuAction = { [weak self] event, view in self?.showContextMenu(event, in: view) }
        bro.rootView = AnyView(
            ZStack {
                Color.clear
                ChartMascotView(state: state, showsFloor: false)
                    .frame(width: 320, height: 90)
                    .scaleEffect(Self.scale)
                    .frame(width: Self.stage.width, height: Self.stage.height)
            }
            .frame(width: Self.stage.width, height: Self.stage.height))
        panel.contentView = bro
        let origin = Self.restoredOrigin(defaults: defaults, panelSize: Self.stage)
        panel.setFrameOrigin(origin)
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification, object: panel, queue: .main
            ) { [weak self] _ in Task { @MainActor in self?.saveOrigin() } })
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
            ) { [weak self] _ in Task { @MainActor in self?.clampToVisibleScreen() } })
        if defaults.bool(forKey: Self.preferenceKey) { setEnabled(true, persist: false) }
    }

    func setEnabled(_ enabled: Bool) { setEnabled(enabled, persist: true) }

    private func setEnabled(_ enabled: Bool, persist: Bool) {
        state.desktopBroEnabled = enabled
        if persist { defaults.set(enabled, forKey: Self.preferenceKey) }
        onEnabledChanged?(enabled)
        if enabled {
            clampToVisibleScreen()
            panel.orderFrontRegardless()
            startTracking()
        } else {
            panel.orderOut(nil)
            trackingTimer?.invalidate()
            trackingTimer = nil
        }
    }

    func show() { setEnabled(true) }
    func hide() { setEnabled(false) }

    func close() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        panel.close()
    }

    static func clampedOrigin(_ origin: NSPoint, panelSize: NSSize, screenFrame: NSRect) -> NSPoint {
        let maxX = max(screenFrame.minX, screenFrame.maxX - panelSize.width)
        let maxY = max(screenFrame.minY, screenFrame.maxY - panelSize.height)
        return NSPoint(x: min(max(origin.x, screenFrame.minX), maxX), y: min(max(origin.y, screenFrame.minY), maxY))
    }

    static func ignoresMouse(at point: NSPoint, actorFrame: NSRect) -> Bool { !actorFrame.contains(point) }

    static func actorFrame(panelOrigin: NSPoint, actorX: CGFloat) -> NSRect {
        NSRect(x: panelOrigin.x + actorX * scale, y: panelOrigin.y, width: actor.width, height: actor.height)
    }

    private static func restoredOrigin(defaults: UserDefaults, panelSize: NSSize) -> NSPoint {
        let saved = defaults.array(forKey: originKey) as? [Double]
        let screens = NSScreen.screens.map(\.visibleFrame)
        let fallback = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1_024, height: 768)
        let preferred =
            saved.flatMap { values -> NSPoint? in
                guard values.count == 2, values.allSatisfy(\.isFinite) else { return nil }
                return NSPoint(x: values[0], y: values[1])
            } ?? NSPoint(x: fallback.maxX - panelSize.width - 24, y: fallback.minY + 24)
        let savedFrame = NSRect(origin: preferred, size: panelSize)
        let screen =
            screens.first(where: { $0.contains(savedFrame) })
            ?? screens.first(where: { $0.intersects(savedFrame) }) ?? fallback
        return clampedOrigin(preferred, panelSize: panelSize, screenFrame: screen)
    }

    private func startTracking() {
        guard trackingTimer == nil else { return }
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateClickThrough() }
        }
        RunLoop.main.add(timer, forMode: .common)
        trackingTimer = timer
    }

    private func updateClickThrough() {
        guard state.desktopBroEnabled, (panel as? DesktopBroPanel)?.isDragging != true else { return }
        if !NSScreen.screens.contains(where: { $0.visibleFrame.contains(panel.frame) }) {
            clampToVisibleScreen()
        }
        let point = NSEvent.mouseLocation
        let now = Date()
        let snapshot = state.mascotCycle.snapshot(at: now)
        let patrolDate = state.mascotPatrolDate(snapshot: snapshot, at: now)
        let frame = ChartMascotMotion.frame(
            snapshot: snapshot, at: now, availableWidth: 320,
            patrolDate: patrolDate,
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        let actorRect = Self.actorFrame(panelOrigin: panel.frame.origin, actorX: frame.x)
        panel.ignoresMouseEvents = Self.ignoresMouse(at: point, actorFrame: actorRect)
    }

    private func saveOrigin() {
        defaults.set([panel.frame.origin.x, panel.frame.origin.y], forKey: Self.originKey)
    }

    private func clampToVisibleScreen() {
        let screen =
            panel.screen ?? NSScreen.screens.first(where: { $0.frame.intersects(panel.frame) }) ?? NSScreen.main
        guard let screen else { return }
        panel.setFrameOrigin(
            Self.clampedOrigin(panel.frame.origin, panelSize: panel.frame.size, screenFrame: screen.visibleFrame))
    }

    private func showContextMenu(_ event: NSEvent, in view: NSView) {
        let menu = NSMenu()
        let hideItem = NSMenuItem(title: "Hide Bro", action: #selector(hideFromMenu), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)
        let dashboardItem = NSMenuItem(
            title: "Show Swear Stats", action: #selector(openDashboardFromMenu), keyEquivalent: "")
        dashboardItem.target = self
        menu.addItem(dashboardItem)
        menu.popUp(positioning: nil, at: view.convert(event.locationInWindow, from: nil), in: view)
    }

    @objc private func hideFromMenu() { hide() }
    @objc private func openDashboardFromMenu() { openDashboard() }
}

@MainActor
private final class DesktopBroPanel: NSPanel {
    var isDragging = false
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
private final class DesktopBroInteractionView: NSHostingView<AnyView> {
    var mouseDownAction: ((NSEvent) -> Void)?
    var contextMenuAction: ((NSEvent, NSView) -> Void)?

    override func mouseDown(with event: NSEvent) { mouseDownAction?(event) }
    override func rightMouseDown(with event: NSEvent) { contextMenuAction?(event, self) }
}
