import Foundation
import Testing
@testable import CodexStatsApp

struct MascotCycleTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    @Test("Given queued bottles, when Bro wakes, then he drinks them, sleeps again, and later sobers")
    func queuedDrinksAndSecondSleep() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 12, at: start)
        cycle.receive(hits: 2, at: start.addingTimeInterval(2))
        #expect(cycle.snapshot(at: start.addingTimeInterval(4)).phase == .sleeping)
        cycle.receive(hits: 9, at: start.addingTimeInterval(5))
        let wake = cycle.snapshot(at: start.addingTimeInterval(22))
        #expect(wake.phase == .drinking)
        #expect(wake.bottleCount == 0)
        #expect(wake.emptyBottles == 23)
        #expect(wake.totalDrunk == 23)
        #expect(wake.totalReceived == 23)
        let secondSleep = cycle.snapshot(at: start.addingTimeInterval(25))
        #expect(secondSleep.phase == .sleeping)
        #expect(secondSleep.heat == 12.6)
        let sober = cycle.snapshot(at: start.addingTimeInterval(43))
        #expect(sober.phase == .sobering)
        #expect(abs(sober.heat - 3.6) < 0.000_001)
        #expect(sober.totalReceived == sober.totalDrunk + sober.bottleCount)
    }

    @Test("Given low frequency drinks, when heat cools below rowdy level, then Bro sobers without scheduling sleep")
    func coolingAndSoberPhase() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 5, at: start)
        #expect(cycle.snapshot(at: start).phase == .buzzing)
        let sober = cycle.snapshot(at: start.addingTimeInterval(6))
        #expect(sober.heat == 3.8)
        #expect(sober.phase == .sobering)
        #expect(cycle.snapshot(at: start.addingTimeInterval(30)).phase == .settled)
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
        let asleep = cycle.snapshot(at: start.addingTimeInterval(4))
        #expect(asleep.phase == .sleeping)
    }

    @Test(
        "Given sleep and drinking boundaries, when events arrive around them, then projections stay pure and dates clamp backward"
    )
    func boundariesAndPureProjection() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 12, at: start)
        cycle.receive(hits: 4, at: start.addingTimeInterval(3.9))
        let sleep = cycle.snapshot(at: start.addingTimeInterval(4))
        #expect(sleep.phase == .sleeping)
        #expect(sleep.bottleCount == 0)
        #expect(cycle.snapshot(at: start.addingTimeInterval(4)) == sleep)
        cycle.receive(hits: 1, at: start.addingTimeInterval(4))
        cycle.receive(hits: 2, at: start.addingTimeInterval(3))
        let backward = cycle.snapshot(at: start.addingTimeInterval(3))
        #expect(backward.phase == .sleeping)
        #expect(backward.bottleCount == 3)
        #expect(backward.totalReceived == 19)
        #expect(backward.totalReceived == backward.totalDrunk + backward.bottleCount)
    }

    @Test("Given queued bottles at wake, when drinking phase is active, then fresh hits are drunk immediately")
    func freshHitDuringWakeDrink() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 12, at: start)
        cycle.receive(hits: 2, at: start.addingTimeInterval(5))
        let waking = start.addingTimeInterval(22)
        #expect(cycle.snapshot(at: waking).phase == .drinking)
        cycle.receive(hits: 1, at: waking.addingTimeInterval(1))
        let afterHit = cycle.snapshot(at: waking.addingTimeInterval(1))
        #expect(afterHit.phase == .drinking)
        #expect(afterHit.bottleCount == 0)
        #expect(afterHit.totalDrunk == 15)
        #expect(afterHit.totalReceived == 15)
    }

    @Test("Given no queued bottles, when sleep cools below rowdy level, then wake stays finite and sobers")
    func emptyWakeDoesNotLoop() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 12, at: start)
        let wake = cycle.snapshot(at: start.addingTimeInterval(22))
        #expect(wake.phase == .sobering)
        #expect(abs(wake.heat - 2.2) < 0.000_001)
        #expect(wake.bottleCount == 0)
        #expect(wake.totalReceived == 12)
        #expect(cycle.snapshot(at: start.addingTimeInterval(40)).phase == .settled)
    }

    @Test("Given rowdy heat and no queued bottles, when Bro wakes, then he sleeps again until heat drops")
    func emptyRowdyWakeSleepsAgain() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 24, at: start)
        let firstWake = start.addingTimeInterval(22)
        #expect(cycle.snapshot(at: firstWake).phase == .sleeping)
        #expect(cycle.snapshot(at: firstWake).heat > 12)
        #expect(cycle.snapshot(at: start.addingTimeInterval(40)).phase == .buzzing)
        #expect(cycle.snapshot(at: start.addingTimeInterval(65)).phase == .sobering)
    }
}
