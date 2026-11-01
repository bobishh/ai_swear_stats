import Foundation

enum ChartMascotMotion {
    enum Pose: Equatable {
        case walkLeft, walkRight, squat, drink, throwBottle, rowdy, sleep
    }

    struct Frame: Equatable {
        let pose: Pose
        let frameIndex: Int
        let x: CGFloat
        let scale: CGFloat
    }

    struct BottleProjectile: Equatable {
        let x: CGFloat
        let y: CGFloat
    }

    static let spriteWidth: CGFloat = 56
    static let spriteHeight: CGFloat = 61
    static let laneHeight: CGFloat = 90
    static let bottleVisualLimit = 12
    private static let visibleDrinkLimit = 4
    private static let walkDuration: TimeInterval = 10
    private static let squatDuration: TimeInterval = 2.8
    private static let gaitFrameDuration: TimeInterval = 0.12
    private static let patrolDuration = 2 * (walkDuration + squatDuration)
    private static let clipFrameDuration: TimeInterval = 0.12
    private static let rowdyRestDuration: TimeInterval = 1.5
    private static let drinkRestDuration: TimeInterval = 1
    private static let throwFlightDuration: TimeInterval = 0.6
    private static let throwReleaseFrame = 3

    private struct Layout {
        let width: CGFloat
        let scale: CGFloat
        let homeX: CGFloat

    }

    private struct DrinkBeat {
        let pose: Pose
        let frameIndex: Int
        let throwElapsed: TimeInterval?
        let pendingThrows: Int
    }

    static func frame(
        snapshot: MascotCycle.Snapshot,
        at date: Date,
        availableWidth: CGFloat,
        patrolDate: Date? = nil,
        reduceMotion: Bool = false
    ) -> Frame {
        let layout = makeLayout(width: availableWidth)
        if snapshot.phase == .sleeping {
            let elapsed = max(0, date.timeIntervalSince(snapshot.phaseStartedAt))
            return Frame(
                pose: .sleep, frameIndex: animatedIndex(elapsed, rate: 0.5, pose: .sleep, reduceMotion: reduceMotion),
                x: reduceMotion
                    ? layout.homeX : patrolFrame(at: patrolDate ?? snapshot.phaseStartedAt, layout: layout).x,
                scale: layout.scale)
        }

        if let beat = drinkBeat(snapshot: snapshot, at: date, reduceMotion: reduceMotion) {
            let originDate =
                patrolDate ?? (snapshot.phase == .drinking ? snapshot.phaseStartedAt : snapshot.drinkStartedAt ?? date)
            let x = reduceMotion ? layout.homeX : patrolFrame(at: originDate, layout: layout).x
            return Frame(pose: beat.pose, frameIndex: beat.frameIndex, x: x, scale: layout.scale)
        }

        switch snapshot.phase {
        case .settled, .sobering:
            if reduceMotion {
                return Frame(pose: .squat, frameIndex: 0, x: layout.homeX, scale: layout.scale)
            }
            return patrolFrame(at: patrolDate ?? date, layout: layout)
        case .buzzing:
            let elapsed = max(0, date.timeIntervalSince(snapshot.phaseStartedAt))
            let index = restingLoopIndex(
                elapsed, frameDuration: clipFrameDuration, restDuration: rowdyRestDuration,
                pose: .rowdy, reduceMotion: reduceMotion)
            let heldDate = patrolDate ?? snapshot.phaseStartedAt
            let heldX = patrolFrame(at: heldDate, layout: layout).x
            let sway = reduceMotion ? 0 : CGFloat(sin(elapsed * .pi * 2 / 2.22)) * 6 * layout.scale
            let x = reduceMotion ? layout.homeX : clamped(heldX + sway, in: layout)
            return Frame(
                pose: .rowdy, frameIndex: index, x: x, scale: layout.scale)
        case .sleeping, .drinking:
            return Frame(pose: .squat, frameIndex: 0, x: layout.homeX, scale: layout.scale)
        }
    }

    static func frameCount(for pose: Pose) -> Int {
        switch pose {
        case .walkLeft, .walkRight: 8
        case .squat: 6
        case .drink, .throwBottle, .rowdy: 6
        case .sleep: 4
        }
    }

    static func homeX(availableWidth: CGFloat) -> CGFloat {
        makeLayout(width: availableWidth).homeX
    }

    static func queuedBottlePositions(count: Int, availableWidth: CGFloat) -> [BottleProjectile] {
        bottleStack(count: count, side: .left, layout: makeLayout(width: availableWidth))
    }

    static func emptyBottlePositions(count: Int, availableWidth: CGFloat) -> [BottleProjectile] {
        bottleStack(count: count, side: .right, layout: makeLayout(width: availableWidth))
    }

    static func thrownBottlePositions(
        snapshot: MascotCycle.Snapshot,
        at date: Date,
        availableWidth: CGFloat,
        patrolDate: Date? = nil,
        reduceMotion: Bool = false
    ) -> [BottleProjectile] {
        guard !reduceMotion,
            let beat = drinkBeat(snapshot: snapshot, at: date, reduceMotion: false),
            let flightElapsed = beat.throwElapsed
        else { return [] }
        let layout = makeLayout(width: availableWidth)
        let originDate =
            patrolDate ?? (snapshot.phase == .drinking ? snapshot.phaseStartedAt : snapshot.drinkStartedAt ?? date)
        let actorX = patrolFrame(at: originDate, layout: layout).x
        let fromX = min(layout.width - 3 * layout.scale, actorX + spriteWidth * layout.scale * 0.82)
        let landing = emptyBottlePositions(count: snapshot.emptyBottles, availableWidth: availableWidth).last
        let toX = landing?.x ?? fromX
        let toY = landing?.y ?? laneHeight - 1
        let visible = min(visibleDrinkLimit, max(0, beat.pendingThrows))
        return (0..<visible).compactMap { index in
            let delayedElapsed = flightElapsed - Double(index) * 0.08
            let delayed = delayedElapsed / throwFlightDuration
            guard (0...1).contains(delayed) else { return nil }
            let x = fromX + (toX - fromX) * delayed
            let y = 45 + (toY - 45) * delayed - 40 * sin(delayed * .pi)
            return BottleProjectile(x: x, y: y)
        }
    }

    static func visibleEmptyBottleCount(
        snapshot: MascotCycle.Snapshot,
        at date: Date,
        availableWidth: CGFloat,
        patrolDate: Date? = nil,
        reduceMotion: Bool = false
    ) -> Int {
        max(
            0,
            min(
                bottleVisualLimit,
                snapshot.emptyBottles
                    - thrownBottlePositions(
                        snapshot: snapshot, at: date, availableWidth: availableWidth,
                        patrolDate: patrolDate, reduceMotion: reduceMotion
                    ).count))
    }

    static func pausesPatrol(snapshot: MascotCycle.Snapshot, at date: Date) -> Bool {
        switch snapshot.phase {
        case .buzzing, .sleeping, .drinking:
            return true
        case .settled, .sobering:
            guard let drinkStartedAt = snapshot.drinkStartedAt else { return false }
            return date < drinkStartedAt.addingTimeInterval(MascotCycle.Timing.freshDrinkSceneDuration)
        }
    }

    private enum StackSide { case left, right }

    private static func bottleStack(count: Int, side: StackSide, layout: Layout) -> [BottleProjectile] {
        let visible = min(max(0, count), bottleVisualLimit)
        let columns = min(6, max(1, Int(max(8, layout.width - 8) / 8)))
        let pileWidth = CGFloat(columns * 8 - 2) * layout.scale
        let leftEdge: CGFloat
        switch side {
        case .left:
            leftEdge = max(0, layout.homeX - pileWidth - 5 * layout.scale)
        case .right:
            leftEdge = min(
                max(0, layout.homeX + spriteWidth * layout.scale + 32 * layout.scale), max(0, layout.width - pileWidth))
        }
        return (0..<visible).map { index in
            let column = index % columns
            let row = index / columns
            return BottleProjectile(
                x: leftEdge + CGFloat(column * 8 + 3) * layout.scale,
                y: laneHeight - 1 - CGFloat(row * (side == .left ? 17 : 8)))
        }
    }

    private static func drinkBeat(snapshot: MascotCycle.Snapshot, at date: Date, reduceMotion: Bool) -> DrinkBeat? {
        guard let drinkStartedAt = snapshot.drinkStartedAt else { return nil }
        let queued = snapshot.phase == .drinking
        let duration = queued ? MascotCycle.Timing.wakeDrinkSceneDuration : MascotCycle.Timing.freshDrinkSceneDuration
        let sceneStartedAt = queued ? snapshot.phaseStartedAt : drinkStartedAt
        guard date < sceneStartedAt.addingTimeInterval(duration) else { return nil }
        let elapsed = max(0, date.timeIntervalSince(sceneStartedAt))

        let count = min(visibleDrinkLimit, max(1, snapshot.drinkHits))
        let gulpDuration = Double(frameCount(for: .drink)) * clipFrameDuration
        if elapsed < gulpDuration {
            let index = animatedIndex(
                elapsed, rate: clipFrameDuration, pose: .drink, reduceMotion: reduceMotion)
            return DrinkBeat(pose: .drink, frameIndex: index, throwElapsed: nil, pendingThrows: count)
        }
        let throwStart = gulpDuration + drinkRestDuration
        guard elapsed >= throwStart else {
            return DrinkBeat(
                pose: .drink, frameIndex: reduceMotion ? 0 : frameCount(for: .drink) - 1,
                throwElapsed: nil, pendingThrows: count)
        }
        let throwElapsed = elapsed - throwStart
        let throwIndex = min(frameCount(for: .throwBottle) - 1, Int(throwElapsed / clipFrameDuration))
        let flightElapsed = throwElapsed - Double(throwReleaseFrame) * clipFrameDuration
        return DrinkBeat(
            pose: .throwBottle,
            frameIndex: reduceMotion ? 0 : throwIndex,
            throwElapsed: (0...throwFlightDuration).contains(flightElapsed) ? flightElapsed : nil,
            pendingThrows: count)
    }

    private static func animatedIndex(_ elapsed: TimeInterval, rate: TimeInterval, pose: Pose, reduceMotion: Bool)
        -> Int
    {
        guard !reduceMotion, rate > 0 else { return 0 }
        return Int(max(0, elapsed) / rate) % frameCount(for: pose)
    }

    private static func restingLoopIndex(
        _ elapsed: TimeInterval,
        frameDuration: TimeInterval,
        restDuration: TimeInterval,
        pose: Pose,
        reduceMotion: Bool
    ) -> Int {
        guard !reduceMotion, frameDuration > 0 else { return 0 }
        let lastFrame = frameCount(for: pose) - 1
        let clipDuration = Double(frameCount(for: pose)) * frameDuration
        let cycleDuration = clipDuration + restDuration
        let withinCycle = max(0, elapsed).truncatingRemainder(dividingBy: cycleDuration)
        guard withinCycle < clipDuration else { return lastFrame }
        return min(lastFrame, Int(withinCycle / frameDuration))
    }

    private static func patrolFrame(at date: Date, layout: Layout) -> Frame {
        let maxX = max(0, layout.width - spriteWidth * layout.scale)
        let elapsed = max(0, date.timeIntervalSinceReferenceDate)
        let phase = elapsed.truncatingRemainder(dividingBy: patrolDuration)
        if phase < walkDuration {
            return Frame(
                pose: .walkRight,
                frameIndex: gaitFrameIndex(at: phase),
                x: maxX * phase / walkDuration,
                scale: layout.scale)
        }
        if phase < walkDuration + squatDuration {
            let progress = (phase - walkDuration) / squatDuration
            return Frame(
                pose: .squat,
                frameIndex: min(5, Int(progress * 6)),
                x: maxX,
                scale: layout.scale)
        }
        if phase < 2 * walkDuration + squatDuration {
            let progress = (phase - walkDuration - squatDuration) / walkDuration
            return Frame(
                pose: .walkLeft,
                frameIndex: gaitFrameIndex(at: phase - walkDuration - squatDuration),
                x: maxX * (1 - progress),
                scale: layout.scale)
        }
        let progress = (phase - 2 * walkDuration - squatDuration) / squatDuration
        return Frame(
            pose: .squat,
            frameIndex: min(5, Int(progress * 6)),
            x: 0,
            scale: layout.scale)
    }

    private static func gaitFrameIndex(at elapsed: TimeInterval) -> Int {
        Int(elapsed / gaitFrameDuration) % frameCount(for: .walkRight)
    }

    private static func makeLayout(width: CGFloat) -> Layout {
        let laneWidth = max(0, width)
        let scale = min(1, laneWidth / spriteWidth)
        let actorWidth = spriteWidth * scale
        return Layout(width: laneWidth, scale: scale, homeX: max(0, (laneWidth - actorWidth) / 2))
    }

    private static func clamped(_ x: CGFloat, in layout: Layout) -> CGFloat {
        min(max(0, x), max(0, layout.width - spriteWidth * layout.scale))
    }

}

@MainActor
final class MascotWalkClock {
    private var patrolElapsed: TimeInterval
    private var lastAdvancedAt: Date
    private var isPaused = false

    init(now: Date = Date()) {
        patrolElapsed = now.timeIntervalSinceReferenceDate
        lastAdvancedAt = now
    }

    func advance(at date: Date, paused: Bool) -> Date {
        guard date >= lastAdvancedAt else { return Date(timeIntervalSinceReferenceDate: patrolElapsed) }
        let timestamp = date
        if !isPaused {
            patrolElapsed += timestamp.timeIntervalSince(lastAdvancedAt)
        }
        lastAdvancedAt = timestamp
        isPaused = paused
        return Date(timeIntervalSinceReferenceDate: patrolElapsed)
    }
}
