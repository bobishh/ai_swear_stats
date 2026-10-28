import AppKit
import Foundation
import SwiftUI
import Testing
@testable import CodexStatsApp

struct ChartMascotViewTests {
    @Test("Given bundled brand art, when sidebar loads, then pixel logo is available")
    @MainActor
    func bundledSidebarLogoLoads() {
        #expect(AppResources.sidebarLogo != nil)
    }

    @Test("Given the bundled mascot atlas, when frames load, then every action has complete nonempty PNG frames")
    @MainActor
    func bundledMascotFramesLoad() {
        #expect(ChartMascotImages.hasAllFrames)
    }

    @Test("Given idle and reaction poses, when the mascot updates, then chart lane height stays fixed")
    @MainActor
    func reactionKeepsLaneHeight() {
        _ = NSApplication.shared
        let state = DashboardState()
        let host = NSHostingView(rootView: ChartMascotView(state: state).frame(width: 240))
        host.layoutSubtreeIfNeeded()
        let idleHeight = host.fittingSize.height

        state.mascotReaction = ChartMascotReaction(profanityHits: 8)
        host.rootView = ChartMascotView(state: state).frame(width: 240)
        host.layoutSubtreeIfNeeded()

        #expect(idleHeight == ChartMascotMotion.spriteHeight)
        #expect(host.fittingSize.height == idleHeight)
    }
}
