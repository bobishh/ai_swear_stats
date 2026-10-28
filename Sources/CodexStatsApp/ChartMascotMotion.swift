import Foundation

struct ChartMascotReaction: Equatable, Sendable {
    let id: UUID
    let startedAt: Date
    let profanityHits: Int

    init(profanityHits: Int, startedAt: Date = Date()) {
        id = UUID()
        self.startedAt = startedAt
        self.profanityHits = profanityHits
    }
}

enum ChartMascotMotion {
    enum Pose: Equatable {
        case idle
        case walkLeft
        case walkRight
        case squat
        case reaction
    }

    struct Frame: Equatable {
        let pose: Pose
        let frameIndex: Int
        let x: CGFloat
        let scale: CGFloat
    }

    static let spriteWidth: CGFloat = 56
    static let spriteHeight: CGFloat = 61
    private static let walkDuration = 10.0
    private static let squatDuration = 2.8
    private static let gaitFrameDuration = 0.12
    private static let cycleDuration = 2 * (walkDuration + squatDuration)
    private static let reactionDuration = 2.4

    static func frame(
        elapsed: TimeInterval,
        availableWidth: CGFloat,
        reduceMotion: Bool = false,
        reactionElapsed: TimeInterval? = nil
    ) -> Frame {
        let scale = min(1, max(0, availableWidth / spriteWidth))
        let scaledWidth = spriteWidth * scale
        let maxX = max(0, availableWidth - scaledWidth)

        if reduceMotion {
            return Frame(pose: .idle, frameIndex: 0, x: maxX / 2, scale: scale)
        }

        let phase = max(0, elapsed).truncatingRemainder(dividingBy: cycleDuration)
        let walkingFrame = walkingFrame(phase: phase, maxX: maxX, scale: scale)
        if let reactionElapsed, reactionElapsed >= 0, reactionElapsed < reactionDuration {
            let frameIndex = min(7, Int(reactionElapsed / reactionDuration * 8))
            return Frame(pose: .reaction, frameIndex: frameIndex, x: walkingFrame.x, scale: scale)
        }
        return walkingFrame
    }

    private static func walkingFrame(phase: TimeInterval, maxX: CGFloat, scale: CGFloat) -> Frame {
        if phase < walkDuration {
            let progress = phase / walkDuration
            return Frame(
                pose: .walkRight, frameIndex: gaitFrameIndex(at: phase), x: maxX * progress, scale: scale)
        }
        if phase < walkDuration + squatDuration {
            let progress = (phase - walkDuration) / squatDuration
            return Frame(pose: .squat, frameIndex: min(5, Int(progress * 6)), x: maxX, scale: scale)
        }
        if phase < 2 * walkDuration + squatDuration {
            let progress = (phase - walkDuration - squatDuration) / walkDuration
            return Frame(
                pose: .walkLeft,
                frameIndex: gaitFrameIndex(at: phase - walkDuration - squatDuration),
                x: maxX * (1 - progress),
                scale: scale)
        }
        let progress = (phase - 2 * walkDuration - squatDuration) / squatDuration
        return Frame(pose: .squat, frameIndex: min(5, Int(progress * 6)), x: 0, scale: scale)
    }

    private static func gaitFrameIndex(at walkElapsed: TimeInterval) -> Int {
        Int(walkElapsed / gaitFrameDuration) % 8
    }
}
