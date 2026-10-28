import AppKit
import SwiftUI

struct ChartMascotView: View {
    @ObservedObject var state: DashboardState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: reduceMotion ? 0.25 : 1 / 12)) { timeline in
            GeometryReader { geometry in
                let snapshot = state.mascotCycle.snapshot(at: timeline.date)
                let frame = ChartMascotMotion.frame(
                    snapshot: snapshot,
                    at: timeline.date,
                    availableWidth: geometry.size.width,
                    reduceMotion: reduceMotion)
                ZStack(alignment: .topLeading) {
                    floor
                    bottleStacks(
                        snapshot: snapshot,
                        date: timeline.date,
                        width: geometry.size.width,
                        reduceMotion: reduceMotion)
                    tossedBottles(
                        snapshot: snapshot,
                        date: timeline.date,
                        width: geometry.size.width,
                        reduceMotion: reduceMotion)
                    if let image = ChartMascotImages.image(pose: frame.pose, index: frame.frameIndex) {
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.none)
                            .scaleEffect(x: frame.pose == .throwBottle ? -1 : 1, y: 1)
                            .frame(
                                width: ChartMascotMotion.spriteWidth * frame.scale,
                                height: ChartMascotMotion.spriteHeight * frame.scale
                            )
                            .position(
                                x: frame.x + ChartMascotMotion.spriteWidth * frame.scale / 2,
                                y: ChartMascotMotion.laneHeight - ChartMascotMotion.spriteHeight * frame.scale / 2)
                    }
                }
                .frame(height: ChartMascotMotion.laneHeight)
            }
        }
        .frame(height: ChartMascotMotion.laneHeight)
        .accessibilityHidden(true)
    }

    private var floor: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.18))
            .frame(height: 1)
            .offset(y: ChartMascotMotion.laneHeight - 1)
    }

    private func bottleStacks(
        snapshot: MascotCycle.Snapshot,
        date: Date,
        width: CGFloat,
        reduceMotion: Bool
    ) -> some View {
        let queued = ChartMascotMotion.queuedBottlePositions(count: snapshot.bottleCount, availableWidth: width)
        let emptyCount = ChartMascotMotion.visibleEmptyBottleCount(
            snapshot: snapshot, at: date, availableWidth: width, reduceMotion: reduceMotion)
        let empties = ChartMascotMotion.emptyBottlePositions(count: emptyCount, availableWidth: width)
        return Canvas { context, _ in
            for (index, position) in queued.enumerated() {
                drawBottle(in: context, at: position, color: bottleColor(index))
            }
            for (index, position) in empties.enumerated() {
                drawBottle(
                    in: context,
                    at: position,
                    color: bottleColor(index),
                    empty: true,
                    opacity: min(1, snapshot.heat / 4))
            }
        }
        .frame(height: ChartMascotMotion.laneHeight)
        .clipped()
        .allowsHitTesting(false)
    }

    private func tossedBottles(
        snapshot: MascotCycle.Snapshot,
        date: Date,
        width: CGFloat,
        reduceMotion: Bool
    ) -> some View {
        let projectiles = ChartMascotMotion.thrownBottlePositions(
            snapshot: snapshot, at: date, availableWidth: width, reduceMotion: reduceMotion)
        return Canvas { context, _ in
            for (index, position) in projectiles.enumerated() {
                drawBottle(in: context, at: position, color: bottleColor(index))
            }
        }
        .frame(height: ChartMascotMotion.laneHeight)
        .clipped()
        .allowsHitTesting(false)
    }

    private func drawBottle(
        in context: GraphicsContext,
        at point: ChartMascotMotion.BottleProjectile,
        color: Color,
        empty: Bool = false,
        opacity: Double = 1
    ) {
        let body =
            empty
            ? CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 4)
            : CGRect(x: point.x - 2, y: point.y - 9, width: 4, height: 9)
        let neck =
            empty
            ? CGRect(x: point.x + 4, y: point.y - 3, width: 3, height: 2)
            : CGRect(x: point.x - 1, y: point.y - 12, width: 2, height: 3)
        let glint =
            empty
            ? CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 1)
            : CGRect(x: point.x - 1, y: point.y - 8, width: 1, height: 5)
        context.fill(Path(body), with: .color(color.opacity((empty ? 0.4 : 0.85) * opacity)))
        if empty { context.stroke(Path(body), with: .color(color.opacity(opacity)), lineWidth: 0.5) }
        context.fill(Path(neck), with: .color(color.opacity(0.85 * opacity)))
        context.fill(Path(glint), with: .color(.white.opacity(0.55 * opacity)))
    }

    private func bottleColor(_ index: Int) -> Color {
        index.isMultiple(of: 2)
            ? Color(red: 0.22, green: 0.38, blue: 0.17)
            : Color(red: 0.49, green: 0.32, blue: 0.12)
    }
}

@MainActor
enum ChartMascotImages {
    private static let squat = load("squat", count: 6)
    private static let drink = load("drink", count: 6)
    private static let sleep = load("sleep", count: 4)
    private static let throwBottle = load("throw", count: 6)
    private static let rowdy = load("rowdy", count: 6)

    static var hasAllFrames: Bool {
        hasFrames(squat, count: 6) && hasFrames(drink, count: 6) && hasFrames(sleep, count: 4)
            && hasFrames(throwBottle, count: 6) && hasFrames(rowdy, count: 6)
    }

    static func image(pose: ChartMascotMotion.Pose, index: Int) -> NSImage? {
        let frames: [NSImage?]
        switch pose {
        case .squat: frames = squat
        case .drink: frames = drink
        case .throwBottle: frames = throwBottle
        case .rowdy: frames = rowdy
        case .sleep: frames = sleep
        }
        guard frames.indices.contains(index) else { return nil }
        return frames[index]
    }

    private static func load(_ action: String, count: Int) -> [NSImage?] {
        (0..<count).map { index in
            AppResources.image(named: String(format: "%02d", index), subdirectory: "Mascot/\(action)")
        }
    }

    private static func hasFrames(_ frames: [NSImage?], count: Int) -> Bool {
        frames.count == count
            && frames.allSatisfy { image in
                guard let image else { return false }
                return image.size.width > 0 && image.size.height > 0
            }
    }
}
