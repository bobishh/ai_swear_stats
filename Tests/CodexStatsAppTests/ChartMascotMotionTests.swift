import Foundation
import Testing
@testable import CodexStatsApp

struct ChartMascotMotionTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("Given calm state, when time advances, then mascot stays home without an itinerary")
    func calmStaysHome() {
        let snapshot = makeSnapshot(phase: .settled)
        let first = ChartMascotMotion.frame(snapshot: snapshot, at: start, availableWidth: 480)
        let later = ChartMascotMotion.frame(snapshot: snapshot, at: start.addingTimeInterval(20), availableWidth: 480)

        #expect(first.pose == .squat)
        #expect(first.x == later.x)
        #expect(first.x == ChartMascotMotion.homeX(availableWidth: 480))
    }

    @Test(
        "Given a fresh buzzing batch, when sampled through gulp and throw, then mascot stays home and bottles arc right"
    )
    func buzzingDrinkThrowsAtHome() throws {
        let snapshot = makeSnapshot(
            phase: .buzzing,
            heat: 8,
            emptyBottles: 1,
            drinkHits: 1,
            lastDrinkAt: start)
        let gulp = ChartMascotMotion.frame(snapshot: snapshot, at: start.addingTimeInterval(0.7), availableWidth: 480)
        let release = ChartMascotMotion.frame(
            snapshot: snapshot, at: start.addingTimeInterval(0.9), availableWidth: 480)
        let projectiles = ChartMascotMotion.thrownBottlePositions(
            snapshot: snapshot, at: start.addingTimeInterval(1.2), availableWidth: 480)

        #expect(gulp.pose == .drink)
        #expect(release.pose == .throwBottle)
        #expect(gulp.x == release.x)
        #expect(
            ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: start.addingTimeInterval(0.7), availableWidth: 480
            ).isEmpty)
        #expect(projectiles.count == 1)
        let projectile = try #require(projectiles.first)
        #expect(projectile.x > release.x)
        #expect(projectile.y < ChartMascotMotion.laneHeight)
        let arcStart = try #require(
            ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: start.addingTimeInterval(1.13), availableWidth: 480
            ).first)
        let arcPeak = try #require(
            ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: start.addingTimeInterval(1.315), availableWidth: 480
            ).first)
        let arcEnd = try #require(
            ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: start.addingTimeInterval(1.49), availableWidth: 480
            ).first)
        #expect(arcPeak.y < arcStart.y)
        #expect(arcPeak.y < arcEnd.y)
        #expect(
            ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: start.addingTimeInterval(1.51), availableWidth: 480
            ).isEmpty)
    }

    @Test("Given a rowdy mascot without a new bottle, when time advances, then only small in-place sway occurs")
    func rowdySwaysAtHome() {
        let snapshot = makeSnapshot(phase: .buzzing, heat: 10)
        let frames = stride(from: 0.0, to: 8.0, by: 0.1).map { elapsed in
            ChartMascotMotion.frame(snapshot: snapshot, at: start.addingTimeInterval(elapsed), availableWidth: 480)
        }
        let home = ChartMascotMotion.homeX(availableWidth: 480)

        #expect(frames.allSatisfy { $0.pose == .rowdy })
        #expect(frames.allSatisfy { abs($0.x - home) <= 6 })
    }

    @Test("Given queued wake-up drinks, when the batch advances, then gulp precedes the bottle throw")
    func queuedDrinkingAnimation() {
        let snapshot = makeSnapshot(
            phase: .drinking,
            bottleCount: 0,
            emptyBottles: 2,
            drinkHits: 2,
            lastDrinkAt: start)
        let gulp = ChartMascotMotion.frame(snapshot: snapshot, at: start.addingTimeInterval(0.3), availableWidth: 480)
        let release = ChartMascotMotion.frame(
            snapshot: snapshot, at: start.addingTimeInterval(0.9), availableWidth: 480)
        let projectiles = ChartMascotMotion.thrownBottlePositions(
            snapshot: snapshot, at: start.addingTimeInterval(1.2), availableWidth: 480)

        #expect(gulp.pose == .drink)
        #expect(release.pose == .throwBottle)
        #expect(!projectiles.isEmpty)
        #expect(snapshot.emptyBottles == 2)
    }

    @Test("Given bottles in flight, when tested across widths, then stack and projectile bounds stay inside lane")
    func bottleVisualsStayBounded() {
        let snapshot = makeSnapshot(phase: .buzzing, emptyBottles: 40, drinkHits: 4, lastDrinkAt: start)
        for width: CGFloat in [24, 56, 180, 480] {
            for elapsed in stride(from: 0.2, to: 1.5, by: 0.1) {
                let positions = ChartMascotMotion.thrownBottlePositions(
                    snapshot: snapshot, at: start.addingTimeInterval(elapsed), availableWidth: width)
                #expect(positions.count <= 4)
                #expect(positions.allSatisfy { $0.x >= 0 && $0.x <= width })
                #expect(positions.allSatisfy { $0.y >= 0 && $0.y <= ChartMascotMotion.laneHeight })
            }
            #expect(ChartMascotMotion.queuedBottlePositions(count: 100, availableWidth: width).count <= 12)
            #expect(ChartMascotMotion.emptyBottlePositions(count: 100, availableWidth: width).count <= 12)
        }
    }

    @Test("Given queued and empty bottles, when drawn, then piles sit on opposite sides of actor")
    func bottlePilesFrameActor() {
        let width: CGFloat = 480
        let homeX = ChartMascotMotion.homeX(availableWidth: width)
        let queued = ChartMascotMotion.queuedBottlePositions(count: 8, availableWidth: width)
        let empties = ChartMascotMotion.emptyBottlePositions(count: 8, availableWidth: width)

        #expect(queued.allSatisfy { $0.x < homeX })
        #expect(empties.allSatisfy { $0.x > homeX + ChartMascotMotion.spriteWidth })
    }

    @Test("Given full and empty bottle piles, when laid out, then their bottom row rests on the stage floor")
    func bottlesRestOnFloor() throws {
        let queued = try #require(ChartMascotMotion.queuedBottlePositions(count: 1, availableWidth: 480).first)
        let empty = try #require(ChartMascotMotion.emptyBottlePositions(count: 1, availableWidth: 480).first)
        #expect(queued.y == ChartMascotMotion.laneHeight - 1)
        #expect(empty.y == ChartMascotMotion.laneHeight - 1)
    }

    @Test("Given an empty bottle throw, when its arc ends, then it lands in the empty pile")
    func thrownBottleLandsInPile() throws {
        let snapshot = makeSnapshot(phase: .buzzing, heat: 8, emptyBottles: 1, drinkHits: 1, lastDrinkAt: start)
        let flying = try #require(
            ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: start.addingTimeInterval(1.499), availableWidth: 480
            ).first)
        let landing = try #require(ChartMascotMotion.emptyBottlePositions(count: 1, availableWidth: 480).first)
        #expect(abs(flying.x - landing.x) < 1)
        #expect(abs(flying.y - landing.y) < 1)
    }

    @Test(
        "Given sleep with queued bottles, when sleep timer expires, then reduced-motion projection follows wake phase")
    func reducedMotionStillProjectsTimedWake() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 12, at: start)
        let sleepStart = start.addingTimeInterval(4)
        #expect(cycle.snapshot(at: sleepStart).phase == .sleeping)
        cycle.receive(hits: 2, at: start.addingTimeInterval(5))

        let beforeWake = cycle.snapshot(at: start.addingTimeInterval(21.9))
        let afterWake = cycle.snapshot(at: start.addingTimeInterval(22))
        let sleepingFrame = ChartMascotMotion.frame(
            snapshot: beforeWake, at: start.addingTimeInterval(21.9), availableWidth: 480, reduceMotion: true)
        let wakingFrame = ChartMascotMotion.frame(
            snapshot: afterWake, at: start.addingTimeInterval(22), availableWidth: 480, reduceMotion: true)

        #expect(sleepingFrame.pose == .sleep)
        #expect(afterWake.phase == .drinking)
        #expect(wakingFrame.pose == .drink)
    }

    @Test("Given sleep or reduced motion, when sampled, then pose stays static and actor remains home")
    func sleepAndReducedMotionStayStatic() {
        let snapshot = makeSnapshot(phase: .sleeping, bottleCount: 3)
        let first = ChartMascotMotion.frame(snapshot: snapshot, at: start, availableWidth: 480)
        let later = ChartMascotMotion.frame(snapshot: snapshot, at: start.addingTimeInterval(17), availableWidth: 480)
        let reducedFirst = ChartMascotMotion.frame(
            snapshot: snapshot, at: start, availableWidth: 480, reduceMotion: true)
        let reducedLater = ChartMascotMotion.frame(
            snapshot: snapshot, at: start.addingTimeInterval(17), availableWidth: 480, reduceMotion: true)

        #expect(first.pose == .sleep)
        #expect(first.x == later.x)
        #expect(reducedFirst == reducedLater)
        #expect(reducedFirst.x == first.x)
    }

    @Test(
        "Given reduced motion during awake drink phases, when timeline samples advance, then artwork and bottles stay static"
    )
    func reducedMotionAwakePhasesStayStatic() {
        for phase: MascotCycle.Phase in [.settled, .buzzing, .drinking, .sobering] {
            let snapshot = makeSnapshot(phase: phase, heat: 8, emptyBottles: 4, drinkHits: 2, lastDrinkAt: start)
            let first = ChartMascotMotion.frame(
                snapshot: snapshot, at: start.addingTimeInterval(0.9), availableWidth: 480, reduceMotion: true)
            let later = ChartMascotMotion.frame(
                snapshot: snapshot, at: start.addingTimeInterval(1.2), availableWidth: 480, reduceMotion: true)

            #expect(first.frameIndex == 0)
            #expect(later.frameIndex == 0)
            #expect(first.x == later.x)
            #expect(
                ChartMascotMotion.thrownBottlePositions(
                    snapshot: snapshot, at: start.addingTimeInterval(1.2), availableWidth: 480, reduceMotion: true
                ).isEmpty)
        }
    }

    @Test("Given each phase and narrow lane, when a frame is sampled, then pose index and actor bounds remain valid")
    func frameIndicesAndBounds() {
        for phase: MascotCycle.Phase in [.settled, .buzzing, .sleeping, .drinking, .sobering] {
            for width: CGFloat in [24, 56, 180, 480] {
                let snapshot = makeSnapshot(phase: phase, heat: 10, drinkHits: 4, lastDrinkAt: start)
                for elapsed in stride(from: 0.0, to: 4.0, by: 0.13) {
                    let frame = ChartMascotMotion.frame(
                        snapshot: snapshot, at: start.addingTimeInterval(elapsed), availableWidth: width)
                    #expect(frame.frameIndex >= 0)
                    #expect(frame.frameIndex < ChartMascotMotion.frameCount(for: frame.pose))
                    #expect(frame.x >= 0)
                    #expect(frame.x + ChartMascotMotion.spriteWidth * frame.scale <= width + 0.01)
                }
            }
        }
    }

    private func makeSnapshot(
        phase: MascotCycle.Phase,
        heat: Double = 0,
        bottleCount: Int = 0,
        emptyBottles: Int = 0,
        drinkHits: Int = 0,
        lastDrinkAt: Date? = nil
    ) -> MascotCycle.Snapshot {
        MascotCycle.Snapshot(
            phase: phase,
            phaseStartedAt: start,
            heat: heat,
            bottleCount: bottleCount,
            emptyBottles: emptyBottles,
            totalDrunk: emptyBottles,
            totalReceived: emptyBottles + bottleCount,
            lastDrinkAt: lastDrinkAt,
            drinkHits: drinkHits)
    }
}
