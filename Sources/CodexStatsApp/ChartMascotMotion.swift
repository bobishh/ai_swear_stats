import Foundation

enum ChartMascotMotion {
    enum Pose: String, CaseIterable, Sendable {
        case walkLeft = "walk-left"
        case walkRight = "walk-right"
        case squat, drink, rowdy, sleep
        case throwBottle = "throw"
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
    private static let walkDuration: TimeInterval = 10
    private static let squatRestDuration: TimeInterval = 5
    private static let rowdyRestDuration: TimeInterval = 1.5
    private static let drinkRestDuration: TimeInterval = 1
    private static let throwFlightDuration: TimeInterval = 0.6

    private struct Layout {
        let width: CGFloat
        let scale: CGFloat
        let homeX: CGFloat

    }

    private struct DrinkBeat {
        let pose: Pose
        let frameIndex: Int
        let throwElapsed: TimeInterval?
    }

    static func frame(
        snapshot: MascotCycle.Snapshot,
        at date: Date,
        availableWidth: CGFloat,
        patrolDate: Date? = nil,
        reduceMotion: Bool = false,
        appearance: MascotAppearance = .bundled
    ) -> Frame {
        let layout = makeLayout(width: availableWidth)
        if snapshot.phase == .sleeping {
            let elapsed = max(0, date.timeIntervalSince(snapshot.phaseStartedAt))
            return Frame(
                pose: .sleep,
                frameIndex: animatedIndex(
                    elapsed, pose: .sleep, appearance: appearance, reduceMotion: reduceMotion),
                x: reduceMotion
                    ? layout.homeX
                    : patrolFrame(at: patrolDate ?? snapshot.phaseStartedAt, layout: layout, appearance: appearance).x,
                scale: layout.scale)
        }

        if let beat = drinkBeat(snapshot: snapshot, at: date, appearance: appearance, reduceMotion: reduceMotion) {
            let originDate =
                patrolDate ?? (snapshot.phase == .drinking ? snapshot.phaseStartedAt : snapshot.drinkStartedAt ?? date)
            let x = reduceMotion ? layout.homeX : patrolFrame(at: originDate, layout: layout, appearance: appearance).x
            return Frame(pose: beat.pose, frameIndex: beat.frameIndex, x: x, scale: layout.scale)
        }

        switch snapshot.phase {
        case .settled, .sobering:
            if reduceMotion {
                return Frame(pose: .squat, frameIndex: 0, x: layout.homeX, scale: layout.scale)
            }
            return patrolFrame(at: patrolDate ?? date, layout: layout, appearance: appearance)
        case .buzzing:
            let elapsed = max(0, date.timeIntervalSince(snapshot.phaseStartedAt))
            let index = restingLoopIndex(
                elapsed, restDuration: rowdyRestDuration,
                pose: .rowdy, appearance: appearance, reduceMotion: reduceMotion)
            let heldDate = patrolDate ?? snapshot.phaseStartedAt
            let heldX = patrolFrame(at: heldDate, layout: layout, appearance: appearance).x
            let sway = reduceMotion ? 0 : CGFloat(sin(elapsed * .pi * 2 / 2.22)) * 6 * layout.scale
            let x = reduceMotion ? layout.homeX : clamped(heldX + sway, in: layout)
            return Frame(
                pose: .rowdy, frameIndex: index, x: x, scale: layout.scale)
        case .sleeping, .drinking:
            return Frame(pose: .squat, frameIndex: 0, x: layout.homeX, scale: layout.scale)
        }
    }

    static func frameCount(for pose: Pose, appearance: MascotAppearance = .bundled) -> Int {
        max(1, appearance.clip(pose)?.frames.count ?? 1)
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
        reduceMotion: Bool = false,
        appearance: MascotAppearance = .bundled
    ) -> [BottleProjectile] {
        guard !reduceMotion,
            let beat = drinkBeat(snapshot: snapshot, at: date, appearance: appearance, reduceMotion: false),
            let flightElapsed = beat.throwElapsed
        else { return [] }
        let layout = makeLayout(width: availableWidth)
        let originDate =
            patrolDate ?? (snapshot.phase == .drinking ? snapshot.phaseStartedAt : snapshot.drinkStartedAt ?? date)
        let actorX = patrolFrame(at: originDate, layout: layout, appearance: appearance).x
        let fromX = min(layout.width - 3 * layout.scale, actorX + spriteWidth * layout.scale * 0.82)
        let landing = emptyBottlePositions(count: snapshot.emptyBottles, availableWidth: availableWidth).last
        let toX = landing?.x ?? fromX
        let toY = landing?.y ?? laneHeight - 1
        let progress = flightElapsed / throwFlightDuration
        let x = fromX + (toX - fromX) * progress
        let y = 45 + (toY - 45) * progress - 40 * sin(progress * .pi)
        return [BottleProjectile(x: x, y: y)]
    }

    static func visibleEmptyBottleCount(
        snapshot: MascotCycle.Snapshot,
        at date: Date,
        availableWidth: CGFloat,
        patrolDate: Date? = nil,
        reduceMotion: Bool = false,
        appearance: MascotAppearance = .bundled
    ) -> Int {
        let heldBottle: Int
        if let started = snapshot.drinkStartedAt {
            let landingTime =
                throwStartsAt(appearance: appearance)
                + Double(appearance.clip(.throwBottle)?.releaseFrame ?? 0) * frameDuration(.throwBottle, appearance)
                + throwFlightDuration
            heldBottle = date.timeIntervalSince(started) < landingTime && !reduceMotion ? 1 : 0
        } else {
            heldBottle = 0
        }
        return min(bottleVisualLimit, max(0, snapshot.emptyBottles - heldBottle))
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

    private static func drinkBeat(
        snapshot: MascotCycle.Snapshot, at date: Date, appearance: MascotAppearance, reduceMotion: Bool
    ) -> DrinkBeat? {
        guard let drinkStartedAt = snapshot.drinkStartedAt else { return nil }
        guard date < drinkStartedAt.addingTimeInterval(MascotCycle.Timing.freshDrinkSceneDuration) else { return nil }
        let elapsed = max(0, date.timeIntervalSince(drinkStartedAt))

        let gulpDuration = Double(frameCount(for: .drink, appearance: appearance)) * frameDuration(.drink, appearance)
        if elapsed < gulpDuration {
            let index = animatedIndex(
                elapsed, pose: .drink, appearance: appearance, reduceMotion: reduceMotion)
            return DrinkBeat(pose: .drink, frameIndex: index, throwElapsed: nil)
        }
        let throwStart = gulpDuration + drinkRestDuration
        guard elapsed >= throwStart else {
            return DrinkBeat(
                pose: .drink, frameIndex: reduceMotion ? 0 : frameCount(for: .drink, appearance: appearance) - 1,
                throwElapsed: nil)
        }
        let throwElapsed = elapsed - throwStart
        let throwIndex = min(
            frameCount(for: .throwBottle, appearance: appearance) - 1,
            Int(throwElapsed / frameDuration(.throwBottle, appearance)))
        let flightElapsed =
            throwElapsed
            - Double(appearance.clip(.throwBottle)?.releaseFrame ?? 0) * frameDuration(.throwBottle, appearance)
        return DrinkBeat(
            pose: .throwBottle,
            frameIndex: reduceMotion ? 0 : throwIndex,
            throwElapsed: (0...throwFlightDuration).contains(flightElapsed) ? flightElapsed : nil)
    }

    private static func animatedIndex(
        _ elapsed: TimeInterval, pose: Pose, appearance: MascotAppearance, reduceMotion: Bool
    )
        -> Int
    {
        guard !reduceMotion else { return 0 }
        return Int(max(0, elapsed) / frameDuration(pose, appearance)) % frameCount(for: pose, appearance: appearance)
    }

    private static func restingLoopIndex(
        _ elapsed: TimeInterval,
        restDuration: TimeInterval,
        pose: Pose,
        appearance: MascotAppearance,
        reduceMotion: Bool
    ) -> Int {
        guard !reduceMotion else { return 0 }
        let frameDuration = frameDuration(pose, appearance)
        let lastFrame = frameCount(for: pose, appearance: appearance) - 1
        let clipDuration = Double(frameCount(for: pose, appearance: appearance)) * frameDuration
        let cycleDuration = clipDuration + restDuration
        let withinCycle = max(0, elapsed).truncatingRemainder(dividingBy: cycleDuration)
        guard withinCycle < clipDuration else { return lastFrame }
        return min(lastFrame, Int(withinCycle / frameDuration))
    }

}

extension ChartMascotMotion {
    private static func patrolFrame(at date: Date, layout: Layout, appearance: MascotAppearance) -> Frame {
        let maxX = max(0, layout.width - spriteWidth * layout.scale)
        let elapsed = max(0, date.timeIntervalSinceReferenceDate)
        let clipDuration = Double(frameCount(for: .squat, appearance: appearance)) * frameDuration(.squat, appearance)
        let squatDuration = 2 * clipDuration + squatRestDuration
        let patrolDuration = 2 * (walkDuration + squatDuration)
        let phase = elapsed.truncatingRemainder(dividingBy: patrolDuration)
        if phase < walkDuration {
            return Frame(
                pose: .walkRight,
                frameIndex: animatedIndex(phase, pose: .walkRight, appearance: appearance, reduceMotion: false),
                x: maxX * phase / walkDuration,
                scale: layout.scale)
        }
        if phase < walkDuration + squatDuration {
            return squatFrame(elapsed: phase - walkDuration, x: maxX, layout: layout, appearance: appearance)
        }
        if phase < 2 * walkDuration + squatDuration {
            let progress = (phase - walkDuration - squatDuration) / walkDuration
            return Frame(
                pose: .walkLeft,
                frameIndex: animatedIndex(
                    phase - walkDuration - squatDuration,
                    pose: .walkLeft, appearance: appearance, reduceMotion: false),
                x: maxX * (1 - progress),
                scale: layout.scale)
        }
        return squatFrame(
            elapsed: phase - 2 * walkDuration - squatDuration, x: 0, layout: layout, appearance: appearance)
    }

    private static func squatFrame(elapsed: TimeInterval, x: CGFloat, layout: Layout, appearance: MascotAppearance)
        -> Frame
    {
        let last = frameCount(for: .squat, appearance: appearance) - 1
        let rate = frameDuration(.squat, appearance)
        let clipDuration = Double(last + 1) * rate
        let index: Int
        if elapsed < clipDuration {
            index = min(last, Int(elapsed / rate))
        } else if elapsed < clipDuration + squatRestDuration {
            index = last
        } else {
            index = max(0, last - Int((elapsed - clipDuration - squatRestDuration) / rate))
        }
        return Frame(
            pose: .squat,
            frameIndex: index,
            x: x,
            scale: layout.scale)
    }

    private static func frameDuration(_ pose: Pose, _ appearance: MascotAppearance) -> TimeInterval {
        max(0.04, appearance.clip(pose)?.frameDuration ?? 0.12)
    }

    private static func throwStartsAt(appearance: MascotAppearance) -> TimeInterval {
        Double(frameCount(for: .drink, appearance: appearance)) * frameDuration(.drink, appearance) + drinkRestDuration
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
