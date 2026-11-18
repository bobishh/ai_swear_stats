import AppKit
import SwiftUI
import Testing
@testable import CodexStatsApp

@Suite(.serialized)
@MainActor
struct AquaInterfaceTests {
    @Test("Given idle, pending, and failed sync, when status changes, then its reserved row never moves the dashboard")
    func statusKeepsItsSpace() {
        _ = NSApplication.shared
        let host = NSHostingView(rootView: AquaStatusRow(error: nil).frame(width: 592))
        host.layoutSubtreeIfNeeded()
        let idle = host.fittingSize
        host.rootView = AquaStatusRow(error: "Log folder unavailable").frame(width: 592)
        host.layoutSubtreeIfNeeded()
        #expect(host.fittingSize == idle)
        #expect(idle.height >= 20)
    }

    @Test("Given an Aqua scroll bar, when its value and page size change, then native scrolling remains usable")
    func scrollerKeepsNativeGeometry() {
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 240, height: 300))
        let document = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 1_200))
        scroll.documentView = document
        scroll.hasVerticalScroller = true
        scroll.scrollerStyle = .legacy
        scroll.verticalScroller = AquaScroller()
        scroll.tile()
        let gutter = scroll.contentView.frame.width
        document.setFrameSize(NSSize(width: 200, height: 2_400))
        scroll.reflectScrolledClipView(scroll.contentView)
        #expect(scroll.contentView.frame.width == gutter)
        #expect(scroll.verticalScroller?.scrollerStyle == .legacy)
        #expect((scroll.verticalScroller?.knobProportion ?? 1) < 1)
        scroll.contentView.scroll(to: NSPoint(x: 0, y: 600))
        scroll.reflectScrolledClipView(scroll.contentView)
        #expect(scroll.contentView.bounds.origin.y == 600)
    }
}
