import Foundation
import Testing
@testable import CodexStatsApp

struct ChartMascotMotionTests {
    @Test("Given the chart mascot loop, when time advances, then it walks both ways and squats at each end")
    func walkAndSquatLoop() {
        let width: CGFloat = 240
        let outbound = ChartMascotMotion.frame(elapsed: 5.2, availableWidth: width)
        let rightSquat = ChartMascotMotion.frame(elapsed: 11.4, availableWidth: width)
        let inbound = ChartMascotMotion.frame(elapsed: 17.8, availableWidth: width)
        let leftSquat = ChartMascotMotion.frame(elapsed: 24.2, availableWidth: width)
        let nextLap = ChartMascotMotion.frame(elapsed: 26.4, availableWidth: width)

        #expect(outbound.pose == .walkRight)
        #expect(rightSquat.pose == .squat)
        #expect(inbound.pose == .walkLeft)
        #expect(leftSquat.pose == .squat)
        #expect(nextLap.pose == .walkRight)
        #expect(outbound.x < rightSquat.x)
        #expect(inbound.x < rightSquat.x)
        #expect(outbound.x > leftSquat.x)
    }

    @Test("Given a long walk across the chart, when gait frames repeat, then horizontal motion stays independent")
    func gaitRepeatsWhileMascotMoves() {
        let firstGait = ChartMascotMotion.frame(elapsed: 0.13, availableWidth: 600)
        let repeatedGait = ChartMascotMotion.frame(elapsed: 1.09, availableWidth: 600)
        let nextGait = ChartMascotMotion.frame(elapsed: 1.21, availableWidth: 600)

        #expect(firstGait.pose == .walkRight)
        #expect(repeatedGait.frameIndex == firstGait.frameIndex)
        #expect(nextGait.frameIndex != firstGait.frameIndex)
        #expect(firstGait.x < repeatedGait.x)
        #expect(repeatedGait.x < nextGait.x)
    }

    @Test("Given narrow and wide chart tracks, when motion is calculated, then sprite bounds stay inside track")
    func motionStaysWithinTrack() {
        for width: CGFloat in [42, 240] {
            let motion = ChartMascotMotion.frame(elapsed: 1.4, availableWidth: width)
            #expect(motion.x >= 0)
            #expect(motion.x + 56 * motion.scale <= width)
        }
    }

    @Test("Given reduced motion, when elapsed time or reaction changes, then mascot remains on one idle frame")
    func reducedMotionIsStatic() {
        let first = ChartMascotMotion.frame(elapsed: 1, availableWidth: 240, reduceMotion: true)
        let later = ChartMascotMotion.frame(
            elapsed: 7, availableWidth: 240, reduceMotion: true, reactionElapsed: 0.2)

        #expect(first.pose == .idle)
        #expect(first.frameIndex == 0)
        #expect(later == first)
    }

    @Test("Given a fresh profanity reaction, when its animation runs, then reaction frames temporarily replace walking")
    func reactionTemporarilyOverridesLoop() {
        let first = ChartMascotMotion.frame(elapsed: 1.4, availableWidth: 240, reactionElapsed: 0.4)
        let later = ChartMascotMotion.frame(elapsed: 1.4, availableWidth: 240, reactionElapsed: 1.6)
        let resumed = ChartMascotMotion.frame(elapsed: 1.4, availableWidth: 240, reactionElapsed: 2.5)

        #expect(first.pose == .reaction)
        #expect(later.pose == .reaction)
        #expect(first.frameIndex != later.frameIndex)
        #expect(resumed.pose == .walkRight)
    }
}
