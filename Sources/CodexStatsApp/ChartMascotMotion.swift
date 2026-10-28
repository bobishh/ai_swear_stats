import Foundation

enum ChartMascotMotion {
    enum Pose: Equatable {
        case squat, drink, throwBottle, rowdy, sleep
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
    private static let drinkBatchDuration: TimeInterval = 1.5
    private static let queuedDrinkDuration: TimeInterval = 3
    private static let gulpShare = 0.48
    private static let visibleDrinkLimit = 4

    private struct Layout {
        let width: CGFloat
        let scale: CGFloat
        let homeX: CGFloat

    }

    private struct DrinkBeat {
        let pose: Pose
        let frameIndex: Int
        let throwProgress: Double?
        let pendingThrows: Int
    }

    static func frame(
        snapshot: MascotCycle.Snapshot,
        at date: Date,
        availableWidth: CGFloat,
        reduceMotion: Bool = false
    ) -> Frame {
        let layout = makeLayout(width: availableWidth)
        if snapshot.phase == .sleeping {
            let elapsed = max(0, date.timeIntervalSince(snapshot.phaseStartedAt))
            return Frame(
                pose: .sleep, frameIndex: animatedIndex(elapsed, rate: 0.5, pose: .sleep, reduceMotion: reduceMotion),
                x: layout.homeX, scale: layout.scale)
        }

        if let beat = drinkBeat(snapshot: snapshot, at: date, reduceMotion: reduceMotion) {
            return Frame(pose: beat.pose, frameIndex: beat.frameIndex, x: layout.homeX, scale: layout.scale)
        }

        switch snapshot.phase {
        case .settled, .sobering:
            return Frame(pose: .squat, frameIndex: 0, x: layout.homeX, scale: layout.scale)
        case .buzzing:
            let elapsed = max(0, date.timeIntervalSince(snapshot.phaseStartedAt))
            let rate = max(0.2, 0.32 - min(snapshot.heat, 24) * 0.0035)
            let index = animatedIndex(elapsed, rate: rate, pose: .rowdy, reduceMotion: reduceMotion)
            let sway = reduceMotion ? 0 : CGFloat(sin(elapsed * .pi * 2 / (rate * 6))) * 6 * layout.scale
            return Frame(
                pose: .rowdy, frameIndex: index, x: clamped(layout.homeX + sway, in: layout), scale: layout.scale)
        case .sleeping, .drinking:
            return Frame(pose: .squat, frameIndex: 0, x: layout.homeX, scale: layout.scale)
        }
    }

    static func frameCount(for pose: Pose) -> Int {
        switch pose {
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
        reduceMotion: Bool = false
    ) -> [BottleProjectile] {
        guard !reduceMotion,
            let beat = drinkBeat(snapshot: snapshot, at: date, reduceMotion: false),
            let progress = beat.throwProgress
        else { return [] }
        guard progress >= 0.52 else { return [] }
        let layout = makeLayout(width: availableWidth)
        let fromX = min(layout.width - 3 * layout.scale, layout.homeX + spriteWidth * layout.scale * 0.82)
        let landing = emptyBottlePositions(count: snapshot.emptyBottles, availableWidth: availableWidth).last
        let toX = landing?.x ?? fromX
        let toY = landing?.y ?? laneHeight - 1
        let visible = min(visibleDrinkLimit, max(0, beat.pendingThrows))
        let released = max(0, (progress - 0.52) / 0.48)
        return (0..<visible).compactMap { index in
            let delay = Double(index) * 0.08
            let delayed = (released - delay) / (1 - delay)
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
        reduceMotion: Bool = false
    ) -> Int {
        max(
            0,
            min(
                bottleVisualLimit,
                snapshot.emptyBottles
                    - thrownBottlePositions(
                        snapshot: snapshot, at: date, availableWidth: availableWidth, reduceMotion: reduceMotion
                    ).count))
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
        guard let lastDrinkAt = snapshot.lastDrinkAt else { return nil }
        let queued = snapshot.phase == .drinking
        let duration = queued ? queuedDrinkDuration : drinkBatchDuration
        let elapsed = max(0, date.timeIntervalSince(queued ? snapshot.phaseStartedAt : lastDrinkAt))
        guard elapsed < duration else { return nil }

        let count = min(visibleDrinkLimit, max(1, snapshot.drinkHits))
        let segmentDuration = duration / Double(count)
        let withinSegment = elapsed.truncatingRemainder(dividingBy: segmentDuration)
        let gulpDuration = segmentDuration * gulpShare
        if withinSegment < gulpDuration {
            let index = animatedIndex(
                withinSegment, rate: max(0.08, gulpDuration / 6), pose: .drink, reduceMotion: reduceMotion)
            return DrinkBeat(pose: .drink, frameIndex: index, throwProgress: nil, pendingThrows: count)
        }
        let throwProgress = (withinSegment - gulpDuration) / (segmentDuration - gulpDuration)
        let index = animatedIndex(throwProgress * 0.65, rate: 0.11, pose: .throwBottle, reduceMotion: reduceMotion)
        return DrinkBeat(pose: .throwBottle, frameIndex: index, throwProgress: throwProgress, pendingThrows: count)
    }

    private static func animatedIndex(_ elapsed: TimeInterval, rate: TimeInterval, pose: Pose, reduceMotion: Bool)
        -> Int
    {
        guard !reduceMotion, rate > 0 else { return 0 }
        return Int(max(0, elapsed) / rate) % frameCount(for: pose)
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
