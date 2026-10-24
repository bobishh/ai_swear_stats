import CodexStatsCore
import Foundation

struct LiveSoundPolicy {
    private var lastPlayedAt: Date?
    private let cooldownSeconds: TimeInterval = 1.5

    mutating func shouldPlay(
        _ messages: [MessageFact], enabled: Bool, classifier: WordClassifier, now: Date = Date()
    ) -> Bool {
        guard enabled else { return false }
        let containsProfanity = messages.contains { message in
            message.words.contains { word, count in
                count > 0 && classifier.classify(word)?.category == .profanity
            }
        }
        guard containsProfanity,
            lastPlayedAt.map({ now.timeIntervalSince($0) >= cooldownSeconds }) ?? true
        else { return false }
        lastPlayedAt = now
        return true
    }
}
