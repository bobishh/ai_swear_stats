import Foundation

struct MascotCycle: Equatable, Sendable {
    enum Timing {
        static let awakeCoolingRate = 0.04
        static let sleepingCoolingRate = 0.1
        static let rowdyBuildup: TimeInterval = 10
        static let sleepDuration: TimeInterval = 40
        static let freshDrinkSceneDuration: TimeInterval = 4.8
        static let wakeDrinkSceneDuration: TimeInterval = 8
    }

    enum Phase: Equatable, Sendable {
        case settled, buzzing, sleeping, drinking, sobering
    }

    struct Snapshot: Equatable, Sendable {
        let phase: Phase
        let phaseStartedAt: Date
        let heat: Double
        let bottleCount: Int
        let emptyBottles: Int
        let totalDrunk: Int
        let totalReceived: Int
        let drinkStartedAt: Date?
        let drinkHits: Int
    }

    private(set) var phase: Phase = .settled
    private(set) var phaseStartedAt: Date
    private(set) var heat = 0.0
    private(set) var bottleCount = 0
    private(set) var emptyBottles = 0
    private(set) var totalDrunk = 0
    private(set) var totalReceived = 0
    private(set) var drinkStartedAt: Date?
    private(set) var drinkHits = 0
    private var lastAdvancedAt: Date
    private var sleepDueAt: Date?

    private static let buzzThreshold = 4.0
    private static let sleepThreshold = 12.0
    private static let maximumHeat = 24.0

    init(now: Date = Date()) {
        phaseStartedAt = now
        lastAdvancedAt = now
    }

    mutating func receive(hits: Int, at date: Date) {
        guard hits > 0 else { return }
        let eventDate = max(date, lastAdvancedAt)
        advance(to: eventDate)
        totalReceived += hits
        switch phase {
        case .sleeping:
            bottleCount += hits
        case .settled, .buzzing, .sobering, .drinking:
            drink(hits: hits, at: eventDate)
            if phase != .drinking {
                setAwakePhase(at: eventDate)
            }
            if heat >= Self.sleepThreshold, sleepDueAt == nil {
                sleepDueAt = eventDate.addingTimeInterval(Timing.rowdyBuildup)
            }
        }
    }

    func snapshot(at: Date) -> Snapshot {
        var projection = self
        projection.advance(to: at)
        return Snapshot(
            phase: projection.phase, phaseStartedAt: projection.phaseStartedAt, heat: projection.heat,
            bottleCount: projection.bottleCount, emptyBottles: projection.emptyBottles,
            totalDrunk: projection.totalDrunk, totalReceived: projection.totalReceived,
            drinkStartedAt: projection.drinkStartedAt, drinkHits: projection.drinkHits)
    }

    private mutating func drink(hits: Int, at date: Date) {
        totalDrunk += hits
        emptyBottles += hits
        heat = min(Self.maximumHeat, heat + Double(hits))
        if let drinkStartedAt, date.timeIntervalSince(drinkStartedAt) < Timing.freshDrinkSceneDuration {
            drinkHits += hits
        } else {
            drinkStartedAt = date
            drinkHits = hits
        }
    }

    private mutating func advance(to date: Date) {
        let target = max(date, lastAdvancedAt)
        var cursor = lastAdvancedAt
        while cursor < target {
            if phase == .sleeping {
                let wakeAt = phaseStartedAt.addingTimeInterval(Timing.sleepDuration)
                if wakeAt <= target {
                    heat = max(0, heat - wakeAt.timeIntervalSince(cursor) * Timing.sleepingCoolingRate)
                    cursor = wakeAt
                    wake(at: wakeAt)
                    continue
                }
                heat = max(0, heat - target.timeIntervalSince(cursor) * Timing.sleepingCoolingRate)
                cursor = target
                continue
            }

            let drinkingEndsAt =
                phase == .drinking
                ? phaseStartedAt.addingTimeInterval(Timing.wakeDrinkSceneDuration)
                : nil
            let boundary = [sleepDueAt, drinkingEndsAt].compactMap { $0 }.filter { $0 <= target }.min()
            let segmentEnd = boundary ?? target
            heat = max(0, heat - segmentEnd.timeIntervalSince(cursor) * Timing.awakeCoolingRate)
            cursor = segmentEnd

            if let sleepDueAt, sleepDueAt <= cursor {
                self.sleepDueAt = nil
                setPhase(.sleeping, at: sleepDueAt)
                continue
            }
            if let drinkingEndsAt, drinkingEndsAt <= cursor {
                if heat >= Self.sleepThreshold {
                    setPhase(.sleeping, at: drinkingEndsAt)
                    sleepDueAt = nil
                } else {
                    setAwakePhase(at: drinkingEndsAt)
                }
                continue
            }
            if boundary == nil { break }
        }
        if cursor == target, phase != .sleeping, phase != .drinking {
            setAwakePhase(at: target)
        }
        lastAdvancedAt = target
    }

    private mutating func wake(at wakeAt: Date) {
        if bottleCount > 0 {
            let queued = bottleCount
            bottleCount = 0
            totalDrunk += queued
            emptyBottles += queued
            heat = min(Self.maximumHeat, heat + Double(queued))
            drinkStartedAt = wakeAt
            drinkHits = queued
            setPhase(.drinking, at: wakeAt)
            if heat >= Self.sleepThreshold {
                sleepDueAt = wakeAt.addingTimeInterval(Timing.rowdyBuildup)
            }
        } else {
            sleepDueAt = nil
            if heat >= Self.sleepThreshold {
                phaseStartedAt = wakeAt
            } else {
                setAwakePhase(at: wakeAt)
            }
        }
    }

    private mutating func setAwakePhase(at date: Date) {
        if heat == 0 {
            emptyBottles = 0
            sleepDueAt = nil
            setPhase(.settled, at: date)
        } else if heat >= Self.buzzThreshold || (phase == .buzzing && heat >= 2) {
            setPhase(.buzzing, at: date)
        } else {
            setPhase(.sobering, at: date)
        }
    }

    private mutating func setPhase(_ newPhase: Phase, at date: Date) {
        guard phase != newPhase else { return }
        phase = newPhase
        phaseStartedAt = date
    }
}
