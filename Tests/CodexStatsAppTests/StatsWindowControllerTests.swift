import AppKit
@testable import CodexStatsCore
import Testing
import SwiftUI
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
        #expect(window.title == "Swear Stats")
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

    @Test("Given the narrowest dashboard, when showing rankings, then the header fits without vertical letter wrapping")
    func compactRankingHeader() {
        _ = NSApplication.shared
        let header = NSHostingView(
            rootView: RankingsHeader(
                families: .constant(true), categories: [.profanity: 999_999, .insult: 999_999, .vulgarity: 999_999]
            ).frame(width: 592))
        #expect(header.fittingSize.height > 30)
        #expect(header.fittingSize.height < 75)
    }

    @Test("Given a narrow sidebar, when a hot thread is selected, then its title and percentage fit together")
    func compactThreadHeatRow() {
        _ = NSApplication.shared
        let thread = ThreadSummary(
            id: "thread", title: String(repeating: "A long conversation title ", count: 5),
            provider: "codex", messages: 200, profaneMessages: 100, hits: 300, latest: nil)
        let row = NSHostingView(rootView: ThreadRowView(thread: thread, selected: true).frame(width: 210))
        #expect(row.fittingSize.height > 40)
        #expect(row.fittingSize.height < 120)
    }

    @Test("Given an overall dashboard, when selecting a model, then its filter is sent to the index")
    func selectsModel() {
        _ = NSApplication.shared
        var selected: String?
        let controller = StatsWindowController(onRefresh: {}, onOpenConfig: {}, onFilter: { selected = $0.model })
        controller.selectFilter(AnalyticsFilter(model: "claude/model-b"))
        #expect(selected == "claude/model-b")
    }
}
