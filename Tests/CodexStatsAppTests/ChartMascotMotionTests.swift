import Foundation
import Testing
@testable import CodexStatsApp

struct ChartMascotMotionTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("Given calm state, when time advances, then mascot walks both ways and squats at each end")
    func calmPatrolReturns() {
        let snapshot = makeSnapshot(phase: .settled)
        let outbound = ChartMascotMotion.frame(
            snapshot: snapshot, at: start.addingTimeInterval(5.2), availableWidth: 480)
        let rightSquat = ChartMascotMotion.frame(
            snapshot: snapshot, at: start.addingTimeInterval(11.4), availableWidth: 480)
        let inbound = ChartMascotMotion.frame(
            snapshot: snapshot, at: start.addingTimeInterval(17.8), availableWidth: 480)
        let leftSquat = ChartMascotMotion.frame(
            snapshot: snapshot, at: start.addingTimeInterval(24.2), availableWidth: 480)

        #expect(outbound.pose == .walkRight)
        #expect(rightSquat.pose == .squat)
        #expect(inbound.pose == .walkLeft)
        #expect(leftSquat.pose == .squat)
        #expect(outbound.x < rightSquat.x)
        #expect(inbound.x < rightSquat.x)
        #expect(outbound.x > leftSquat.x)
    }

    @Test("Given regenerated settled projections, when sampled at the same instant, then patrol does not restart")
    func settledProjectionDoesNotRestartPatrol() {
        let date = start.addingTimeInterval(7)
        let earlier = makeSnapshot(phase: .settled, phaseStartedAt: start)
        let regenerated = makeSnapshot(phase: .settled, phaseStartedAt: date)

        #expect(
            ChartMascotMotion.frame(snapshot: earlier, at: date, availableWidth: 480)
                == ChartMascotMotion.frame(snapshot: regenerated, at: date, availableWidth: 480))
    }

    @Test(
        "Given a fresh buzzing batch, when sampled through gulp and throw, then mascot drinks where patrol reached and bottles arc right"
    )
    func buzzingDrinkThrowsFromPatrol() throws {
        let patrol = ChartMascotMotion.frame(
            snapshot: makeSnapshot(phase: .settled), at: start, availableWidth: 480)
        let snapshot = makeSnapshot(
            phase: .buzzing,
            heat: 8,
            emptyBottles: 4,
            drinkHits: 4,
            drinkStartedAt: start)
        let gulp = ChartMascotMotion.frame(snapshot: snapshot, at: start.addingTimeInterval(0.5), availableWidth: 480)
        let release = ChartMascotMotion.frame(
            snapshot: snapshot, at: start.addingTimeInterval(2.1), availableWidth: 480)
        let projectiles = ChartMascotMotion.thrownBottlePositions(
            snapshot: snapshot, at: start.addingTimeInterval(2.1), availableWidth: 480)

        #expect(gulp.pose == .drink)
        #expect(release.pose == .throwBottle)
        #expect(gulp.x == release.x)
        #expect(gulp.x == patrol.x)
        #expect(
            ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: start.addingTimeInterval(0.5), availableWidth: 480
            ).isEmpty)
        #expect(projectiles.count <= 4)
        #expect(!projectiles.isEmpty)
        let projectile = try #require(projectiles.first)
        #expect(projectile.x > release.x)
        #expect(projectile.y < ChartMascotMotion.laneHeight)
        let arcStart = try #require(
            ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: start.addingTimeInterval(2.1), availableWidth: 480
            ).first)
        let arcPeak = try #require(
            ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: start.addingTimeInterval(2.38), availableWidth: 480
            ).first)
        let arcEnd = try #require(
            ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: start.addingTimeInterval(2.679), availableWidth: 480
            ).first)
        #expect(arcPeak.y < arcStart.y)
        #expect(arcPeak.y < arcEnd.y)
        #expect(
            ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: start.addingTimeInterval(2.7), availableWidth: 480
            ).isEmpty)
    }

    @Test("Given a four bottle fresh batch, when its scene plays, then gulp frames and volley remain readable")
    func freshBatchUsesFullSceneWindow() {
        let snapshot = makeSnapshot(phase: .buzzing, emptyBottles: 8, drinkHits: 8, drinkStartedAt: start)
        let gulpIndices = Set(
            stride(from: 0.05, to: 0.72, by: 0.1).compactMap { elapsed -> Int? in
                let frame = ChartMascotMotion.frame(
                    snapshot: snapshot, at: start.addingTimeInterval(elapsed), availableWidth: 480)
                return frame.pose == .drink ? frame.frameIndex : nil
            })
        let volley = ChartMascotMotion.thrownBottlePositions(
            snapshot: snapshot, at: start.addingTimeInterval(2.4), availableWidth: 480)

        #expect(gulpIndices.count == 6)
        #expect(volley.count <= 4)
        #expect(!volley.isEmpty)
        #expect(
            ChartMascotMotion.frame(
                snapshot: snapshot, at: start.addingTimeInterval(4.81), availableWidth: 480
            ).pose != .drink)
    }

    @Test("Given rowdy and sleeping poses, when sampled over time, then sprite clips use normal playback speed")
    func rowdyAndSleepUseNormalPlaybackSpeed() {
        let rowdy = makeSnapshot(phase: .buzzing, heat: 10)
        let sleep = makeSnapshot(phase: .sleeping)
        let rowdyFrames = stride(from: 0.0, to: 3.0, by: 0.1).map { elapsed in
            ChartMascotMotion.frame(snapshot: rowdy, at: start.addingTimeInterval(elapsed), availableWidth: 480)
                .frameIndex
        }
        let sleepFrames = stride(from: 0.0, to: 5.0, by: 0.1).map { elapsed in
            ChartMascotMotion.frame(snapshot: sleep, at: start.addingTimeInterval(elapsed), availableWidth: 480)
                .frameIndex
        }

        #expect(Set(rowdyFrames).count == 6)
        #expect(Set(sleepFrames).count <= 4)
        #expect(rowdyFrames[2] == 1)
        #expect(rowdyFrames[6] == 5)
        #expect(rowdyFrames[7] == 5)
        #expect(sleepFrames[5] == 1)
        #expect(sleepFrames[10] == 2)
    }

    @Test("Given active clips, when sampled after one frame interval, then sprites play at normal speed")
    func actionSpritesUseNormalFrameRate() {
        let rowdy = makeSnapshot(phase: .buzzing, heat: 10)
        let drink = makeSnapshot(phase: .sobering, heat: 1, drinkHits: 1, drinkStartedAt: start)
        let rowdyNext = ChartMascotMotion.frame(
            snapshot: rowdy, at: start.addingTimeInterval(0.13), availableWidth: 480)
        let drinkNext = ChartMascotMotion.frame(
            snapshot: drink, at: start.addingTimeInterval(0.13), availableWidth: 480)

        #expect(rowdyNext.frameIndex == 1)
        #expect(drinkNext.pose == .drink)
        #expect(drinkNext.frameIndex == 1)
    }

    @Test("Given a fresh action scene, when it ends, then patrol resumes near the held position")
    @MainActor
    func patrolResumesWithoutTeleporting() {
        let snapshot = makeSnapshot(phase: .sobering, heat: 1, drinkHits: 1, drinkStartedAt: start)
        let clock = MascotWalkClock(now: start)
        let heldDate = clock.advance(at: start.addingTimeInterval(0.4), paused: true)
        let duringScene = ChartMascotMotion.frame(
            snapshot: snapshot, at: start.addingTimeInterval(0.4), availableWidth: 480, patrolDate: heldDate)
        let resumedDate = clock.advance(at: start.addingTimeInterval(5.0), paused: false)
        let afterScene = ChartMascotMotion.frame(
            snapshot: snapshot, at: start.addingTimeInterval(5.0), availableWidth: 480, patrolDate: resumedDate)
        let nextDate = clock.advance(at: start.addingTimeInterval(5.1), paused: false)
        let nextFrame = ChartMascotMotion.frame(
            snapshot: snapshot, at: start.addingTimeInterval(5.1), availableWidth: 480, patrolDate: nextDate)

        #expect(afterScene.x == duringScene.x)
        #expect(abs(nextFrame.x - afterScene.x) > 0)
        #expect(abs(nextFrame.x - afterScene.x) < 10)
    }

    @Test("Given repeated action pauses, when patrol resumes, then paused time never enters movement elapsed")
    @MainActor
    func patrolClockAccumulatesOnlyWalkingTime() {
        let clock = MascotWalkClock(now: start)
        let beforeAction = clock.advance(at: start.addingTimeInterval(3), paused: false)
        let firstPause = clock.advance(at: start.addingTimeInterval(3), paused: true)
        let continuedPause = clock.advance(at: start.addingTimeInterval(7), paused: true)
        let firstResume = clock.advance(at: start.addingTimeInterval(10), paused: false)
        let staleTimeline = clock.advance(at: start.addingTimeInterval(9), paused: true)
        let moved = clock.advance(at: start.addingTimeInterval(11), paused: false)
        let secondPause = clock.advance(at: start.addingTimeInterval(12), paused: true)
        let secondResume = clock.advance(at: start.addingTimeInterval(15), paused: false)
        let movedAgain = clock.advance(at: start.addingTimeInterval(16), paused: false)

        #expect(firstPause == beforeAction)
        #expect(continuedPause == beforeAction)
        #expect(firstResume == beforeAction)
        #expect(staleTimeline == beforeAction)
        #expect(moved == beforeAction.addingTimeInterval(1))
        #expect(secondPause == beforeAction.addingTimeInterval(2))
        #expect(secondResume == secondPause)
        #expect(movedAgain == secondPause.addingTimeInterval(1))
    }

    @Test("Given a fresh drink scene, when its 4.8 second window ends, then patrol pause ends exactly once")
    func freshDrinkPauseUsesSceneBoundary() {
        let snapshot = makeSnapshot(phase: .sobering, heat: 1, drinkHits: 2, drinkStartedAt: start)

        #expect(ChartMascotMotion.pausesPatrol(snapshot: snapshot, at: start.addingTimeInterval(4.79)))
        #expect(!ChartMascotMotion.pausesPatrol(snapshot: snapshot, at: start.addingTimeInterval(4.8)))
    }

    @Test("Given a rowdy mascot without a new bottle, when time advances, then only small in-place sway occurs")
    func rowdyHoldsPosition() {
        let snapshot = makeSnapshot(phase: .buzzing, heat: 10)
        let frames = stride(from: 0.0, to: 8.0, by: 0.1).map { elapsed in
            ChartMascotMotion.frame(snapshot: snapshot, at: start.addingTimeInterval(elapsed), availableWidth: 480)
        }
        #expect(frames.allSatisfy { $0.pose == .rowdy })
        #expect(frames.allSatisfy { abs($0.x - frames[0].x) <= 12 })
    }

    @Test("Given queued wake-up drinks, when the batch advances, then gulp precedes the bottle throw")
    func queuedDrinkingAnimation() {
        let snapshot = makeSnapshot(
            phase: .drinking,
            bottleCount: 0,
            emptyBottles: 2,
            drinkHits: 2,
            drinkStartedAt: start)
        let gulp = ChartMascotMotion.frame(snapshot: snapshot, at: start.addingTimeInterval(0.3), availableWidth: 480)
        let release = ChartMascotMotion.frame(
            snapshot: snapshot, at: start.addingTimeInterval(2.1), availableWidth: 480)
        let projectiles = ChartMascotMotion.thrownBottlePositions(
            snapshot: snapshot, at: start.addingTimeInterval(2.2), availableWidth: 480)

        #expect(gulp.pose == .drink)
        #expect(release.pose == .throwBottle)
        #expect(!projectiles.isEmpty)
        #expect(snapshot.emptyBottles == 2)
    }

    @Test("Given bottles in flight, when tested across widths, then stack and projectile bounds stay inside lane")
    func bottleVisualsStayBounded() {
        let snapshot = makeSnapshot(phase: .buzzing, emptyBottles: 40, drinkHits: 4, drinkStartedAt: start)
        for width: CGFloat in [24, 56, 180, 480] {
            for elapsed in stride(from: 1.9, to: 2.6, by: 0.1) {
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
        let snapshot = makeSnapshot(phase: .buzzing, heat: 8, emptyBottles: 1, drinkHits: 1, drinkStartedAt: start)
        let flying = try #require(
            ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: start.addingTimeInterval(2.679), availableWidth: 480
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
        let sleepStart = start.addingTimeInterval(10)
        #expect(cycle.snapshot(at: sleepStart).phase == .sleeping)
        cycle.receive(hits: 2, at: start.addingTimeInterval(11))

        let beforeWake = cycle.snapshot(at: start.addingTimeInterval(49.9))
        let afterWake = cycle.snapshot(at: start.addingTimeInterval(50))
        let sleepingFrame = ChartMascotMotion.frame(
            snapshot: beforeWake, at: start.addingTimeInterval(49.9), availableWidth: 480, reduceMotion: true)
        let wakingFrame = ChartMascotMotion.frame(
            snapshot: afterWake, at: start.addingTimeInterval(50), availableWidth: 480, reduceMotion: true)

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
        #expect(reducedFirst.x == ChartMascotMotion.homeX(availableWidth: 480))
    }

    @Test(
        "Given reduced motion during awake drink phases, when timeline samples advance, then artwork and bottles stay static"
    )
    func reducedMotionAwakePhasesStayStatic() {
        for phase: MascotCycle.Phase in [.settled, .buzzing, .drinking, .sobering] {
            let snapshot = makeSnapshot(phase: phase, heat: 8, emptyBottles: 4, drinkHits: 2, drinkStartedAt: start)
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
                let snapshot = makeSnapshot(phase: phase, heat: 10, drinkHits: 4, drinkStartedAt: start)
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

    @Test("Given a finished throw, when the resting pause continues, then its final pose holds instead of looping")
    func throwHoldsDuringRest() {
        let snapshot = makeSnapshot(phase: .sobering, drinkHits: 1, drinkStartedAt: start)
        for elapsed in [3.0, 3.7, 4.6] {
            let frame = ChartMascotMotion.frame(
                snapshot: snapshot, at: start.addingTimeInterval(elapsed), availableWidth: 480)
            #expect(frame.pose == .throwBottle)
            #expect(frame.frameIndex == 5)
        }
    }

    private func makeSnapshot(
        phase: MascotCycle.Phase,
        phaseStartedAt: Date? = nil,
        heat: Double = 0,
        bottleCount: Int = 0,
        emptyBottles: Int = 0,
        drinkHits: Int = 0,
        drinkStartedAt: Date? = nil
    ) -> MascotCycle.Snapshot {
        MascotCycle.Snapshot(
            phase: phase,
            phaseStartedAt: phaseStartedAt ?? start,
            heat: heat,
            bottleCount: bottleCount,
            emptyBottles: emptyBottles,
            totalDrunk: emptyBottles,
            totalReceived: emptyBottles + bottleCount,
            drinkStartedAt: drinkStartedAt,
            drinkHits: drinkHits)
    }
}
