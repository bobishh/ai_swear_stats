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
        let hits = LiveSoundPolicy.profanityHits(in: batch, classifier: classifier)

        let off = policy.cue(profanityHits: hits, enabled: false, now: now)
        let first = policy.cue(profanityHits: hits, enabled: true, now: now)
        let duplicate = policy.cue(profanityHits: hits, enabled: true, now: now.addingTimeInterval(0.2))
        let duringCooldown = policy.cue(profanityHits: 1, enabled: true, now: now.addingTimeInterval(0.9))
        let afterCooldown = policy.cue(profanityHits: 1, enabled: true, now: now.addingTimeInterval(2.1))
        #expect(off == nil)
        #expect(first?.tier == 2)
        #expect(duplicate == nil)
        #expect(duringCooldown == nil)
        #expect(afterCooldown?.tier == 1)
        #expect(first?.volume == afterCooldown?.volume)
        #expect((first?.pitchMultiplier ?? 0) < (afterCooldown?.pitchMultiplier ?? 0))
        #expect((first?.rateMultiplier ?? 0) < (afterCooldown?.rateMultiplier ?? 0))
    }

    @Test("Given live non-profanity or no newly indexed messages, when evaluated, then sound stays silent")
    func ignoresNonProfanityAndEmptyBatch() throws {
        let classifier = try WordClassifier()
        let now = Date(timeIntervalSince1970: 10_000)
        var policy = LiveSoundPolicy()

        let messages = [
            try fact("insult", words: ["мудак": 1]),
            try fact("vulgarity", words: ["говно": 1]),
            try fact("profanity", words: ["fuck": 1]),
        ]
        let hits = LiveSoundPolicy.profanityHits(in: messages, classifier: classifier)
        let empty = policy.cue(profanityHits: 0, enabled: true, now: now)
        let nonProfanity = LiveSoundPolicy.profanityHits(in: Array(messages.prefix(2)), classifier: classifier)
        let disabled = policy.cue(profanityHits: hits, enabled: false, now: now)
        let profanity = policy.cue(profanityHits: hits, enabled: true, now: now)
        #expect(empty == nil)
        #expect(nonProfanity == 0)
        #expect(disabled == nil)
        #expect(hits == 1)
        #expect(profanity?.tier == 1)
    }

    @Test("Given newly indexed хули and хуяли messages, when live sound policy checks them, then exact profanity plays")
    func newRussianTermsTriggerLiveSound() throws {
        let classifier = try WordClassifier()
        let now = Date(timeIntervalSince1970: 10_000)
        let batch = [
            try fact("new-huli", words: ["хули": 1]),
            try fact("new-huyali", words: ["хуяли": 1]),
        ]
        var policy = LiveSoundPolicy()
        let hits = LiveSoundPolicy.profanityHits(in: batch, classifier: classifier)
        #expect(policy.cue(profanityHits: hits, enabled: true, now: now)?.tier == 2)
    }

    @Test("Given one coalesced burst, when its profanity count crosses each threshold, then cue intensity rises once")
    func intensityTracksFreshProfanityHits() {
        let now = Date(timeIntervalSince1970: 10_000)
        let cases: [(Int, Int)] = [(1, 1), (2, 2), (3, 2), (4, 3), (7, 3), (8, 4), (40, 4)]

        for (offset, expectedTier) in cases {
            var policy = LiveSoundPolicy()
            let cue = policy.cue(profanityHits: offset, enabled: true, now: now)
            #expect(cue?.tier == expectedTier)
            #expect(cue?.volume == 0.3)
        }
    }

    private func fact(_ id: String, words: [String: Int]) throws -> MessageFact {
        let json = try JSONSerialization.data(withJSONObject: [
            "id": id, "threadID": "thread", "title": "test", "provider": "generic", "model": NSNull(),
            "effort": NSNull(), "timestamp": NSNull(), "project": NSNull(), "words": words,
        ])
        return try JSONDecoder().decode(MessageFact.self, from: json)
    }
}
