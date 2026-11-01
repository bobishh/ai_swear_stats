import AppKit
import Testing
@testable import CodexStatsApp

@Suite(.serialized)
@MainActor
struct DesktopBroControllerTests {
    @Test("Given the dashboard mascot cycle, when Desktop Bro is enabled, then transparent nonactivating Bro reuses it")
    func enablingShowsPanelAndReusesCycle() throws {
        _ = NSApplication.shared
        let (defaults, suiteName) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let state = DashboardState()
        state.mascotCycle.receive(hits: 3, at: Date(timeIntervalSince1970: 1_800_000_000))
        let expected = state.mascotCycle.snapshot(at: Date(timeIntervalSince1970: 1_800_000_001))
        let controller = DesktopBroController(state: state, defaults: defaults)
        defer { controller.close(); state.desktopBroEnabled = false }

        controller.setEnabled(true)

        #expect(controller.panel.isVisible)
        #expect(state.desktopBroEnabled)
        #expect(controller.panel.backgroundColor == .clear)
        #expect(controller.panel.isOpaque == false)
        #expect(controller.panel.canBecomeKey == false)
        #expect(controller.panel.canBecomeMain == false)
        #expect(controller.panel.level == .floating)
        #expect(controller.panel.hidesOnDeactivate == false)
        #expect(controller.panel.collectionBehavior.contains(.canJoinAllSpaces))
        #expect(state.mascotCycle.snapshot(at: Date(timeIntervalSince1970: 1_800_000_001)) == expected)
        #expect(defaults.bool(forKey: DesktopBroController.preferenceKey))
        controller.hide()
        #expect(controller.panel.isVisible == false)
        #expect(state.desktopBroEnabled == false)
        #expect(defaults.bool(forKey: DesktopBroController.preferenceKey) == false)
        #expect(state.mascotCycle.snapshot(at: Date(timeIntervalSince1970: 1_800_000_001)) == expected)
    }

    @Test("Given a saved Bro position outside the display, when restoring, then origin stays within visible screen")
    func restoreClampsOrigin() {
        let visible = NSRect(x: 50, y: 60, width: 500, height: 700)
        let restored = DesktopBroController.clampedOrigin(
            NSPoint(x: 900, y: -100), panelSize: NSSize(width: 480, height: 135), screenFrame: visible)
        #expect(restored == NSPoint(x: 70, y: 60))
        let opposite = DesktopBroController.clampedOrigin(
            NSPoint(x: -900, y: 1_000), panelSize: NSSize(width: 480, height: 135), screenFrame: visible)
        #expect(opposite == NSPoint(x: 50, y: 625))
    }

    @Test("Given Bro window bounds, when pointer is outside the moving actor, then window ignores mouse events")
    func clickThroughOutsideActor() {
        let actor = DesktopBroController.actorFrame(panelOrigin: NSPoint(x: 100, y: 200), actorX: 40)
        #expect(DesktopBroController.ignoresMouse(at: NSPoint(x: 101, y: 201), actorFrame: actor))
        #expect(
            DesktopBroController.ignoresMouse(at: NSPoint(x: actor.midX, y: actor.midY), actorFrame: actor) == false)
    }

    @Test(
        "Given a desktop panel moved beyond the right edge, when tracking resumes, then its whole stage returns onscreen"
    )
    func movedStageReturnsOnscreen() async throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.main)
        let (defaults, suiteName) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let controller = DesktopBroController(state: DashboardState(), defaults: defaults)
        defer { controller.close() }
        controller.show()
        controller.panel.setFrameOrigin(NSPoint(x: screen.visibleFrame.maxX - 20, y: screen.visibleFrame.midY))
        try await Task.sleep(for: .milliseconds(300))
        #expect(NSScreen.screens.contains { $0.visibleFrame.contains(controller.panel.frame) })
    }

    private func isolatedDefaults() throws -> (UserDefaults, String) {
        let suiteName = "DesktopBroControllerTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }
}
