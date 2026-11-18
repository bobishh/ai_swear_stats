import AppKit
@testable import CodexStatsCore
import Foundation
import SwiftUI
import Testing
@testable import CodexStatsApp

@Suite(.serialized)
@MainActor
struct AquaDashboardPreviewTests {
    @Test("Given indexed conversations, when the dashboard opens narrow and wide, then both scroll panes remain usable")
    func populatedDashboard() throws {
        for width in [900.0, 1_100.0] {
            let state = populatedState()
            try render(state, width: width, height: width == 900 ? 740 : 780, name: "dashboard-\(Int(width))")
        }
    }

    @Test("Given pending indexing, when the dashboard opens at minimum width, then its controls retain their space")
    func pendingDashboard() throws {
        let state = DashboardState()
        state.isSyncing = true
        state.isScanning = true
        state.totalFiles = 150
        state.files = 24
        state.bytesRead = 2_048
        state.notificationRequestPending = true
        state.notificationStatus = "Requesting notification access…"
        try render(state, width: 900, height: 740, name: "dashboard-pending-900")
    }

    @Test(
        "Given an unavailable log folder, when sync fails, then the dashboard retains its layout and exposes the error")
    func failedDashboard() throws {
        let state = DashboardState()
        state.error = "Log folder unavailable. Reconnect the volume or attach another folder."
        state.notificationNeedsSettings = true
        state.notificationStatus = "Notifications are disabled in System Settings."
        try render(state, width: 1_100, height: 780, name: "dashboard-error-1100")
    }

    private func render(_ state: DashboardState, width: Double, height: Double, name: String) throws {
        _ = NSApplication.shared
        let size = NSSize(width: width, height: height)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .aqua)
        window.title = "Swear Stats — synthetic preview"
        let actions = DashboardActions(
            openConfig: {}, filter: { state.filter = $0 }, addFolder: {}, removeFolder: { _ in },
            notifications: { state.notificationsEnabled = $0 }, sound: { state.soundEnabled = $0 }, previewSound: {})
        let host = NSHostingView(rootView: DashboardView(state: state, actions: actions))
        window.contentView = host
        window.setContentSize(size)
        window.orderBack(nil)
        defer { window.close() }
        host.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        host.layoutSubtreeIfNeeded()
        let panes = scrollViews(in: host)
        #expect(panes.count >= 2)
        for scroll in panes where scroll.hasVerticalScroller {
            #expect(scroll.scrollerStyle == .legacy)
            #expect(scroll.verticalScroller is AquaScroller)
            #expect(!scroll.autohidesScrollers)
            if let document = scroll.documentView, document.frame.height > scroll.contentView.bounds.height {
                #expect(document.frame.width <= scroll.contentView.bounds.width + 1)
            }
        }
        #expect(host.bounds.size == size)
        try savePreview(host, name: name)
    }

    private func savePreview(_ host: NSView, name: String) throws {
        guard let path = ProcessInfo.processInfo.environment["SWEAR_STATS_PREVIEW_DIR"] else { return }
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let png = try #require(bitmap.representation(using: .png, properties: [:]))
        try png.write(to: directory.appendingPathComponent(name + ".png"), options: .atomic)
    }

    private func scrollViews(in view: NSView) -> [NSScrollView] {
        let own = (view as? NSScrollView).map { [$0] } ?? []
        return own + view.subviews.flatMap { scrollViews(in: $0) }
    }

    private func populatedState() -> DashboardState {
        let state = DashboardState()
        let titles = [
            "Repair the parser's partial records", "Refine the dashboard filters", "Compare two model responses",
            "Track the build failure", "Review the release notes", "Finish the keyboard navigation",
        ]
        let day = Date(timeIntervalSince1970: 1_795_000_000)
        state.threads = (0..<30).map { index in
            ThreadSummary(
                id: "synthetic-\(index)", title: titles[index % titles.count] + " · \(index + 1)",
                provider: index.isMultiple(of: 2) ? "codex" : "claude", messages: 40 + index * 3,
                profaneMessages: index % 9, hits: (index % 9) * 2, latest: day.addingTimeInterval(Double(index) * 60))
        }
        state.models = [
            ModelSummary(id: "codex/example-model", messages: 900, hits: 70),
            ModelSummary(id: "claude/another-example", messages: 1_100, hits: 80),
        ]
        state.snapshot.messages = state.threads.reduce(0) { $0 + $1.messages }
        state.snapshot.profaneMessages = state.threads.reduce(0) { $0 + $1.profaneMessages }
        state.snapshot.profanityHits = state.threads.reduce(0) { $0 + $1.hits }
        state.snapshot.totalWords = state.snapshot.messages * 35
        state.snapshot.categories = [.profanity: state.snapshot.profanityHits, .insult: 14, .vulgarity: 9]
        let vocabulary = ["fuck", "блядь", "shit", "нахуй", "damn", "пиздец", "fucking", "хуй"]
        state.snapshot.topWords = vocabulary.enumerated().map { index, word in
            RankedWord(
                id: word, family: word, category: .profanity, count: 30 - index * 3,
                language: index.isMultiple(of: 2) ? "en" : "ru")
        }
        state.snapshot.timeline = (0..<48).map { index in
            IntensityPoint(time: day.addingTimeInterval(Double(index) * 3_600), hits: (index * 7) % 13, duration: 3_600)
        }
        state.snapshot.models = state.models
        state.snapshot.threads = state.threads
        state.soundEnabled = true
        return state
    }
}
