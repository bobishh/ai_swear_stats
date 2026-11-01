import Foundation
import Testing
@testable import CodexStatsApp

struct MascotCycleTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    @Test("Given queued bottles, when Bro wakes, then he drinks them, sleeps again, and later sobers")
    func queuedDrinksAndSecondSleep() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 12, at: start)
        #expect(cycle.snapshot(at: start.addingTimeInterval(11)).phase == .sleeping)
        cycle.receive(hits: 2, at: start.addingTimeInterval(11))
        cycle.receive(hits: 9, at: start.addingTimeInterval(12))
        let wake = cycle.snapshot(at: start.addingTimeInterval(50))
        #expect(wake.phase == .drinking)
        #expect(wake.bottleCount == 0)
        #expect(wake.emptyBottles == 23)
        #expect(wake.totalDrunk == 23)
        #expect(wake.totalReceived == 23)
        let secondSleep = cycle.snapshot(at: start.addingTimeInterval(60))
        #expect(secondSleep.phase == .sleeping)
        #expect(abs(secondSleep.heat - 18.08) < 0.000_001)
        let sober = cycle.snapshot(at: start.addingTimeInterval(141))
        #expect(sober.phase == .buzzing)
        #expect(abs(sober.heat - 10.16) < 0.000_001)
        #expect(sober.totalReceived == sober.totalDrunk + sober.bottleCount)
    }

    @Test("Given low frequency drinks, when heat leaves rowdy range, then Bro sobers without scheduling sleep")
    func coolingAndSoberPhase() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 5, at: start)
        #expect(cycle.snapshot(at: start).phase == .buzzing)
        let sober = cycle.snapshot(at: start.addingTimeInterval(6))
        #expect(sober.heat == 4.76)
        #expect(sober.phase == .buzzing)
        #expect(cycle.snapshot(at: start.addingTimeInterval(80)).phase == .sobering)
        #expect(cycle.snapshot(at: start.addingTimeInterval(130)).phase == .settled)
    }

    @Test("Given one fresh hit, when time advances, then Bro stays visible for about 25 seconds")
    func oneHitRemainsVisibleForHumanScaleWindow() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 1, at: start)

        #expect(cycle.snapshot(at: start.addingTimeInterval(24)).heat > 0)
        #expect(cycle.snapshot(at: start.addingTimeInterval(26)).heat == 0)
    }

    @Test("Given four fresh hits, when Bro cools, then rowdy state persists at 30 seconds and settles after 50")
    func fourHitsCoolOverHumanScaleWindow() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 4, at: start)

        #expect(cycle.snapshot(at: start.addingTimeInterval(30)).phase == .buzzing)
        #expect(cycle.snapshot(at: start.addingTimeInterval(51)).phase == .sobering)
        #expect(cycle.snapshot(at: start.addingTimeInterval(101)).phase == .settled)
    }

    @Test("Given rowdy entry, when hits stop, then buildup precedes sleep and sleep lasts about 40 seconds")
    func buildupAndSleepHaveReadableDurations() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 12, at: start)

        #expect(cycle.snapshot(at: start.addingTimeInterval(9)).phase == .buzzing)
        #expect(cycle.snapshot(at: start.addingTimeInterval(11)).phase == .sleeping)
        #expect(cycle.snapshot(at: start.addingTimeInterval(49)).phase == .sleeping)
        #expect(cycle.snapshot(at: start.addingTimeInterval(50)).phase == .buzzing)
    }

    @Test("Given an active fresh-drink scene, when another batch arrives, then the scene anchor stays fixed")
    func activeDrinkSceneDoesNotRestart() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 2, at: start)
        cycle.receive(hits: 3, at: start.addingTimeInterval(2))

        let active = cycle.snapshot(at: start.addingTimeInterval(2))
        #expect(active.drinkStartedAt == start)
        #expect(active.drinkHits == 5)
        #expect(cycle.snapshot(at: start.addingTimeInterval(4.7)).drinkStartedAt == start)
        cycle.receive(hits: 1, at: start.addingTimeInterval(4.9))
        #expect(cycle.snapshot(at: start.addingTimeInterval(4.9)).drinkStartedAt == start.addingTimeInterval(4.9))
    }

    @Test("Given a large batch, when Bro drinks it, then all hits count exactly and rowdy heat caps")
    func largeBatchCountsExactly() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 40, at: start)
        let snapshot = cycle.snapshot(at: start)
        #expect(snapshot.phase == .buzzing)
        #expect(snapshot.totalDrunk == 40)
        #expect(snapshot.totalReceived == 40)
        #expect(snapshot.heat == 24)
        #expect(snapshot.drinkHits == 40)
        let asleep = cycle.snapshot(at: start.addingTimeInterval(11))
        #expect(asleep.phase == .sleeping)
    }

    @Test(
        "Given sleep and drinking boundaries, when events arrive around them, then projections stay pure and dates clamp backward"
    )
    func boundariesAndPureProjection() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 12, at: start)
        cycle.receive(hits: 4, at: start.addingTimeInterval(3.9))
        let sleep = cycle.snapshot(at: start.addingTimeInterval(10))
        #expect(sleep.phase == .sleeping)
        #expect(sleep.bottleCount == 0)
        #expect(cycle.snapshot(at: start.addingTimeInterval(10)) == sleep)
        cycle.receive(hits: 1, at: start.addingTimeInterval(10))
        cycle.receive(hits: 2, at: start.addingTimeInterval(9))
        let backward = cycle.snapshot(at: start.addingTimeInterval(9))
        #expect(backward.phase == .sleeping)
        #expect(backward.bottleCount == 3)
        #expect(backward.totalReceived == 19)
        #expect(backward.totalReceived == backward.totalDrunk + backward.bottleCount)
    }

    @Test("Given queued bottles at wake, when drinking phase is active, then fresh hits are drunk immediately")
    func freshHitDuringWakeDrink() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 12, at: start)
        cycle.receive(hits: 2, at: start.addingTimeInterval(11))
        let waking = start.addingTimeInterval(50)
        #expect(cycle.snapshot(at: waking).phase == .drinking)
        cycle.receive(hits: 1, at: waking.addingTimeInterval(1))
        let afterHit = cycle.snapshot(at: waking.addingTimeInterval(1))
        #expect(afterHit.phase == .drinking)
        #expect(afterHit.bottleCount == 0)
        #expect(afterHit.totalDrunk == 15)
        #expect(afterHit.totalReceived == 15)
        #expect(afterHit.phaseStartedAt == waking)
    }

    @Test("Given no queued bottles, when sleep cools below rowdy level, then wake stays finite and sobers")
    func emptyWakeDoesNotLoop() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 12, at: start)
        let wake = cycle.snapshot(at: start.addingTimeInterval(50))
        #expect(wake.phase == .buzzing)
        #expect(abs(wake.heat - 7.6) < 0.000_001)
        #expect(wake.bottleCount == 0)
        #expect(wake.totalReceived == 12)
        #expect(cycle.snapshot(at: start.addingTimeInterval(250)).phase == .settled)
    }

    @Test("Given rowdy heat and no queued bottles, when Bro wakes, then he sleeps again until heat drops")
    func emptyRowdyWakeSleepsAgain() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 24, at: start)
        let firstWake = start.addingTimeInterval(50)
        #expect(cycle.snapshot(at: firstWake).phase == .sleeping)
        #expect(cycle.snapshot(at: firstWake).heat > 12)
        #expect(cycle.snapshot(at: start.addingTimeInterval(130)).phase == .buzzing)
        #expect(cycle.snapshot(at: start.addingTimeInterval(400)).phase == .sobering)
    }
}
