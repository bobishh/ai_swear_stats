import CodexStatsCore
import Foundation

struct LiveSoundPolicy {
    private var lastPlayedAt: Date?
    private let cooldownSeconds: TimeInterval = 1.5

    static func profanityHits(in messages: [MessageFact], classifier: WordClassifier) -> Int {
        messages.reduce(0) { total, message in
            total
                + message.words.reduce(0) { messageHits, entry in
                    messageHits
                        + (entry.value > 0 && classifier.classify(entry.key)?.category == .profanity
                            ? entry.value : 0)
                }
        }
    }

    mutating func cue(profanityHits: Int, enabled: Bool, now: Date = Date()) -> LiveSoundCue? {
        guard enabled, profanityHits > 0,
            lastPlayedAt.map({ now.timeIntervalSince($0) >= cooldownSeconds }) ?? true
        else { return nil }
        lastPlayedAt = now
        return LiveSoundCue(profanityHits: profanityHits)
    }
}

struct LiveSoundCue: Equatable, Sendable {
    let tier: Int
    let rateMultiplier: Float
    let pitchMultiplier: Float
    let volume: Float = 0.3

    init(profanityHits: Int) {
        switch profanityHits {
        case ..<2:
            tier = 1
            rateMultiplier = 0.9
            pitchMultiplier = 1.0
        case 2..<4:
            tier = 2
            rateMultiplier = 0.82
            pitchMultiplier = 0.92
        case 4..<8:
            tier = 3
            rateMultiplier = 0.72
            pitchMultiplier = 0.84
        default:
            tier = 4
            rateMultiplier = 0.62
            pitchMultiplier = 0.76
        }
    }
}
