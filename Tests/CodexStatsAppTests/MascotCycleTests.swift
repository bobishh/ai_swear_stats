import Foundation
import Testing
@testable import CodexStatsApp

struct MascotCycleTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    @Test("Given a sleeping mascot with a stash, when he wakes, then only the next bottle is consumed")
    func queuedDrinksAtWake() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 40, at: start)
        let asleep = cycle.snapshot(at: start.addingTimeInterval(100))
        #expect(asleep.phase == .sleeping)
        cycle.receive(hits: 11, at: start.addingTimeInterval(100))
        let wakeDate = asleep.phaseStartedAt.addingTimeInterval(MascotCycle.Timing.sleepDuration + 0.01)
        let wake = cycle.snapshot(at: wakeDate)
        #expect(wake.phase == .drinking)
        #expect(wake.totalDrunk == asleep.totalDrunk + 1)
        #expect(wake.bottleCount == asleep.bottleCount + 10)
        #expect(wake.totalReceived == wake.totalDrunk + wake.bottleCount)
    }

    @Test("Given five queued drinks, when they finish and input stops, then Bro gradually sobers")
    func coolingAndSoberPhase() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 5, at: start)
        #expect(cycle.snapshot(at: start).phase == .drinking)
        #expect(cycle.snapshot(at: start.addingTimeInterval(25)).phase == .buzzing)
        #expect(cycle.snapshot(at: start.addingTimeInterval(80)).phase == .sobering)
        #expect(cycle.snapshot(at: start.addingTimeInterval(130)).phase == .settled)
    }

    @Test("Given one fresh hit, when time advances, then heat remains visible for about 25 seconds")
    func oneHitRemainsVisibleForHumanScaleWindow() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 1, at: start)
        #expect(cycle.snapshot(at: start.addingTimeInterval(24)).heat > 0)
        #expect(cycle.snapshot(at: start.addingTimeInterval(26)).heat == 0)
    }

    @Test("Given five consumed bottles, when heat cools, then rowdy hysteresis keeps the recovery readable")
    func rowdyCoolingHasHysteresis() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 5, at: start)
        #expect(cycle.snapshot(at: start.addingTimeInterval(30)).phase == .buzzing)
        #expect(cycle.snapshot(at: start.addingTimeInterval(76)).phase == .sobering)
        #expect(cycle.snapshot(at: start.addingTimeInterval(126)).phase == .settled)
    }

    @Test(
        "Given sustained queued drinks, when heat reaches sleep threshold, then the throw finishes before buildup and sleep"
    )
    func buildupAndSleepHaveReadableDurations() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 40, at: start)
        let asleep = cycle.snapshot(at: start.addingTimeInterval(100))
        let sleepDate = asleep.phaseStartedAt
        #expect(asleep.phase == .sleeping)
        #expect(cycle.snapshot(at: sleepDate.addingTimeInterval(-1)).phase == .buzzing)
        #expect(cycle.snapshot(at: sleepDate.addingTimeInterval(-11)).phase == .drinking)
        #expect(cycle.snapshot(at: sleepDate.addingTimeInterval(39)).phase == .sleeping)
        #expect(cycle.snapshot(at: sleepDate.addingTimeInterval(40.01)).phase == .drinking)
    }

    @Test(
        "Given a large batch, when time advances through repeated sleeps, then every bottle is eventually consumed exactly once"
    )
    func largeBatchCountsExactly() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 40, at: start)
        let first = cycle.snapshot(at: start)
        #expect(first.totalDrunk == 1)
        #expect(first.bottleCount == 39)
        #expect(first.heat == 1)
        let final = cycle.snapshot(at: start.addingTimeInterval(10_000))
        #expect(final.totalReceived == 40)
        #expect(final.totalDrunk == 40)
        #expect(final.bottleCount == 0)
        #expect(final.phase == .settled)
        for seconds in stride(from: 0.0, through: 1_000.0, by: 5) {
            let snapshot = cycle.snapshot(at: start.addingTimeInterval(seconds))
            #expect(snapshot.heat >= 0 && snapshot.heat <= 24)
            #expect(snapshot.totalReceived == snapshot.totalDrunk + snapshot.bottleCount)
        }
    }

    @Test(
        "Given backward events and repeated projections, when snapshots are queried, then time clamps and retained state stays pure"
    )
    func boundariesAndPureProjection() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 40, at: start)
        let date = start.addingTimeInterval(100)
        let asleep = cycle.snapshot(at: date)
        #expect(cycle.snapshot(at: date) == asleep)
        #expect(cycle.totalDrunk == 1)
        cycle.receive(hits: 1, at: date)
        cycle.receive(hits: 2, at: date.addingTimeInterval(-1))
        let backward = cycle.snapshot(at: date.addingTimeInterval(-1))
        #expect(backward.phase == .sleeping)
        #expect(backward.bottleCount == asleep.bottleCount + 3)
        #expect(backward.totalReceived == 43)
    }

    @Test("Given an active wake-up drink, when new hits arrive, then they append without restarting that drink")
    func freshHitDuringWakeDrink() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 40, at: start)
        let asleep = cycle.snapshot(at: start.addingTimeInterval(100))
        let waking = asleep.phaseStartedAt.addingTimeInterval(40.01)
        let before = cycle.snapshot(at: waking)
        cycle.receive(hits: 2, at: waking.addingTimeInterval(1))
        let after = cycle.snapshot(at: waking.addingTimeInterval(1))
        #expect(after.phase == .drinking)
        #expect(after.totalDrunk == before.totalDrunk)
        #expect(after.bottleCount == before.bottleCount + 2)
        #expect(after.drinkStartedAt == before.drinkStartedAt)
    }

    @Test("Given no remaining stash, when sleep finishes, then Bro wakes without manufacturing another bottle")
    func emptyWakeDoesNotLoop() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 15, at: start)
        let asleep = cycle.snapshot(at: start.addingTimeInterval(100))
        #expect(asleep.phase == .sleeping)
        #expect(asleep.bottleCount == 0)
        let wake = cycle.snapshot(at: asleep.phaseStartedAt.addingTimeInterval(40.01))
        #expect(wake.phase == .buzzing)
        #expect(wake.totalDrunk == 15)
        #expect(cycle.snapshot(at: start.addingTimeInterval(400)).phase == .settled)
    }

    @Test(
        "Given identical simultaneous input split across batches, when projected, then accounting and current drink agree"
    )
    func batchingDoesNotChangeQueue() {
        var coalesced = MascotCycle(now: start)
        var split = MascotCycle(now: start)
        coalesced.receive(hits: 25, at: start)
        split.receive(hits: 5, at: start)
        split.receive(hits: 20, at: start)
        for seconds in [0.0, 2.0, 15.0, 100.0, 150.0, 500.0] {
            #expect(
                coalesced.snapshot(at: start.addingTimeInterval(seconds))
                    == split.snapshot(at: start.addingTimeInterval(seconds)))
        }
    }
}
