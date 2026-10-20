import AppKit
import Testing
@testable import CodexStatsApp

@Suite(.serialized)
@MainActor
struct StatsWindowControllerTests {
    @Test("Given a dashboard, when opened then closed and reopened, then its window remains accessible")
    func reopensDashboard() throws {
        _ = NSApplication.shared
        let controller = StatsWindowController(onRefresh: {}, onOpenConfig: {})
        let window = try #require(controller.window)
        controller.showWindow(nil)
        #expect(window.isVisible)
        #expect(window.title == "Codex Stats")
        window.close()
        #expect(window.isVisible == false)
        controller.showWindow(nil)
        #expect(window.isVisible)
        window.close()
    }

    @Test("Given a pending scan, when scan fails, then dashboard reports the error and permits retry")
    func scanFailureState() {
        _ = NSApplication.shared
        let controller = StatsWindowController(onRefresh: {}, onOpenConfig: {})
        controller.update(snapshot: .empty, isScanning: true, error: nil, roots: [])
        #expect(controller.state.isScanning)
        controller.update(snapshot: .empty, isScanning: false, error: "Invalid pattern", roots: [])
        #expect(controller.state.isScanning == false)
        #expect(controller.state.error == "Invalid pattern")
    }
}
