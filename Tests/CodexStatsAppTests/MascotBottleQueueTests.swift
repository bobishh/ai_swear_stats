import Foundation
import Testing
@testable import CodexStatsApp

struct MascotBottleQueueTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    @Test("Given five fresh hits, when each drink starts, then exactly one bottle leaves the queue")
    func drinksOneBottlePerScene() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 5, at: start)
        for index in 0..<5 {
            let date = start.addingTimeInterval(Double(index) * MascotCycle.Timing.freshDrinkSceneDuration + 0.01)
            let snapshot = cycle.snapshot(at: date)
            #expect(snapshot.totalDrunk == index + 1)
            #expect(snapshot.bottleCount == 4 - index)
            #expect(snapshot.drinkHits == 1)
            #expect(snapshot.totalReceived == snapshot.totalDrunk + snapshot.bottleCount)
        }
    }

    @Test("Given an active drink, when fresh hits arrive, then its anchor stays fixed and new bottles wait")
    func arrivalsAppendWithoutRestarting() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 2, at: start)
        cycle.receive(hits: 3, at: start.addingTimeInterval(2))
        let snapshot = cycle.snapshot(at: start.addingTimeInterval(2))
        #expect(snapshot.drinkStartedAt == start)
        #expect(snapshot.totalDrunk == 1)
        #expect(snapshot.bottleCount == 4)
        #expect(cycle.snapshot(at: start.addingTimeInterval(5)).totalDrunk == 2)
    }

    @Test("Given five queued drinks, when each throw releases, then one bottle flies rather than a volley")
    func throwsOneBottlePerDrink() {
        var cycle = MascotCycle(now: start)
        cycle.receive(hits: 5, at: start)
        for index in 0..<5 {
            let date = start.addingTimeInterval(Double(index) * MascotCycle.Timing.freshDrinkSceneDuration + 2.2)
            let snapshot = cycle.snapshot(at: date)
            let projectiles = ChartMascotMotion.thrownBottlePositions(
                snapshot: snapshot, at: date, availableWidth: 480)
            #expect(projectiles.count == 1)
        }
    }
}
