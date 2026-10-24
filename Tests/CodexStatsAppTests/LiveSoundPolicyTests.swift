import Foundation
import CodexStatsCore
import Testing
@testable import CodexStatsApp

struct LiveSoundPolicyTests {
    @Test("Given live profanity, when detected, then sound plays once per batch and observes a short cooldown")
    func liveProfanityCoalescesAndCoolsDown() throws {
        let classifier = try WordClassifier()
        let now = Date(timeIntervalSince1970: 10_000)
        let batch = [
            try fact("first", words: ["fuck": 1]),
            try fact("second", words: ["shit": 2]),
        ]
        var policy = LiveSoundPolicy()

        let off = policy.shouldPlay(batch, enabled: false, classifier: classifier, now: now)
        let first = policy.shouldPlay(batch, enabled: true, classifier: classifier, now: now)
        let duplicate = policy.shouldPlay(
            batch, enabled: true, classifier: classifier, now: now.addingTimeInterval(0.2))
        let duringCooldown = policy.shouldPlay(
            [try fact("third", words: ["fuck": 1])], enabled: true, classifier: classifier,
            now: now.addingTimeInterval(0.9))
        let afterCooldown = policy.shouldPlay(
            [try fact("fourth", words: ["fuck": 1])], enabled: true, classifier: classifier,
            now: now.addingTimeInterval(2.1))
        #expect(!off)
        #expect(first)
        #expect(!duplicate)
        #expect(!duringCooldown)
        #expect(afterCooldown)
    }

    @Test("Given live non-profanity or no newly indexed messages, when evaluated, then sound stays silent")
    func ignoresNonProfanityAndEmptyBatch() throws {
        let classifier = try WordClassifier()
        let now = Date(timeIntervalSince1970: 10_000)
        var policy = LiveSoundPolicy()

        let empty = policy.shouldPlay([], enabled: true, classifier: classifier, now: now)
        let insult = policy.shouldPlay(
            [try fact("insult", words: ["мудак": 1])], enabled: true, classifier: classifier, now: now)
        let vulgarity = policy.shouldPlay(
            [try fact("vulgarity", words: ["говно": 1])], enabled: true, classifier: classifier, now: now)
        let profanity = policy.shouldPlay(
            [try fact("profanity", words: ["fuck": 1])], enabled: true, classifier: classifier, now: now)
        #expect(!empty)
        #expect(!insult)
        #expect(!vulgarity)
        #expect(profanity)
    }

    private func fact(_ id: String, words: [String: Int]) throws -> MessageFact {
        let json = try JSONSerialization.data(withJSONObject: [
            "id": id, "threadID": "thread", "title": "test", "provider": "generic", "model": NSNull(),
            "effort": NSNull(), "timestamp": NSNull(), "project": NSNull(), "words": words,
        ])
        return try JSONDecoder().decode(MessageFact.self, from: json)
    }
}
