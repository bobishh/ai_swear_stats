import AppKit
import SwiftUI

struct ChartMascotView: View {
    @ObservedObject var state: DashboardState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 12, paused: reduceMotion)) { timeline in
            GeometryReader { geometry in
                let reactionElapsed = state.mascotReaction.map { timeline.date.timeIntervalSince($0.startedAt) }
                let motion = ChartMascotMotion.frame(
                    elapsed: timeline.date.timeIntervalSinceReferenceDate,
                    availableWidth: geometry.size.width,
                    reduceMotion: reduceMotion,
                    reactionElapsed: reactionElapsed)
                if let image = ChartMascotImages.image(pose: motion.pose, index: motion.frameIndex) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.none)
                        .frame(
                            width: ChartMascotMotion.spriteWidth * motion.scale,
                            height: ChartMascotMotion.spriteHeight * motion.scale
                        )
                        .position(
                            x: motion.x + ChartMascotMotion.spriteWidth * motion.scale / 2,
                            y: ChartMascotMotion.spriteHeight / 2)
                }
            }
        }
        .frame(height: ChartMascotMotion.spriteHeight)
        .accessibilityHidden(true)
    }
}

@MainActor
enum ChartMascotImages {
    private static let idle = load("idle", count: 6)
    private static let walkRight = load("walk-right", count: 8)
    private static let walkLeft = load("walk-left", count: 8)
    private static let squat = load("squat", count: 6)
    private static let reaction = load("reaction", count: 8)

    static var hasAllFrames: Bool {
        hasFrames(idle, count: 6) && hasFrames(walkRight, count: 8) && hasFrames(walkLeft, count: 8)
            && hasFrames(squat, count: 6) && hasFrames(reaction, count: 8)
    }

    static func image(pose: ChartMascotMotion.Pose, index: Int) -> NSImage? {
        let frames: [NSImage?]
        switch pose {
        case .idle: frames = idle
        case .walkLeft: frames = walkLeft
        case .walkRight: frames = walkRight
        case .squat: frames = squat
        case .reaction: frames = reaction
        }
        guard frames.indices.contains(index) else { return nil }
        return frames[index]
    }

    private static func load(_ action: String, count: Int) -> [NSImage?] {
        (0..<count).map { index in
            let name = String(format: "%02d", index)
            return AppResources.image(named: name, subdirectory: "Mascot/\(action)")
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
