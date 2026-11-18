import Foundation
import Testing
@testable import CodexStatsApp

struct MascotSquatTests {
    @Test("Given a walking mascot, when he reaches the edge, then he squats at normal speed and holds for five seconds")
    func restsOnHeelsBeforeStanding() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let cycle = MascotCycle(now: start)
        let snapshot = cycle.snapshot(at: start)
        for elapsed in [11.0, 13.0, 15.5] {
            let date = start.addingTimeInterval(elapsed)
            let frame = ChartMascotMotion.frame(snapshot: snapshot, at: date, availableWidth: 480, patrolDate: date)
            #expect(frame.pose == .squat)
            #expect(frame.frameIndex == 5)
            #expect(frame.x == 424)
        }
        let moving = start.addingTimeInterval(16.5)
        #expect(
            ChartMascotMotion.frame(snapshot: snapshot, at: moving, availableWidth: 480, patrolDate: moving).pose
                == .walkLeft)
    }

    @Test("Given a held squat, when its pause finishes, then the character stands up before walking away")
    func standsUpAtNormalClipSpeed() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let snapshot = MascotCycle(now: start).snapshot(at: start)
        let date = start.addingTimeInterval(16.3)
        let frame = ChartMascotMotion.frame(snapshot: snapshot, at: date, availableWidth: 480, patrolDate: date)
        #expect(frame.pose == .squat)
        #expect(frame.frameIndex <= 1)
    }
}
