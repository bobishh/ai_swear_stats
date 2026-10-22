import Foundation
import Testing
@testable import CodexStatsCore

struct BurstPolicyTests {
    @Test(
        "Given two live messages crossing threshold, when repeated within cooldown, then only one English alert fires")
    func burstCooldown() throws {
        let classifier = try WordClassifier()
        let now = Date(timeIntervalSince1970: 1_000)
        let facts = [fact("1", hits: 3, time: now), fact("2", hits: 2, time: now)]
        var policy = BurstPolicy()
        let first = try policy.evaluate(facts, classifier: classifier, now: now)
        #expect(first != nil)
        #expect(first?.contains("блять") == false)
        #expect(try policy.evaluate(facts, classifier: classifier, now: now) == nil)
        let data = try JSONEncoder().encode(policy)
        policy = try JSONDecoder().decode(BurstPolicy.self, from: data)
        #expect(
            try policy.evaluate(
                [fact("3", hits: 9, time: now.addingTimeInterval(10))], classifier: classifier,
                now: now.addingTimeInterval(10)) == nil)
        let later = now.addingTimeInterval(1_000)
        #expect(
            try policy.evaluate(
                [fact("4", hits: 3, time: later), fact("5", hits: 2, time: later)], classifier: classifier, now: later)
                != nil)
    }

    @Test("Given a single long message or stale events, when evaluated, then no alert fires")
    func notABurst() throws {
        var policy = BurstPolicy()
        let classifier = try WordClassifier()
        let now = Date()
        #expect(try policy.evaluate([fact("1", hits: 30, time: now)], classifier: classifier, now: now) == nil)
        #expect(
            try policy.evaluate(
                [fact("2", hits: 30, time: now.addingTimeInterval(-300))], classifier: classifier, now: now) == nil)
    }

    private func fact(_ id: String, hits: Int, time: Date) -> MessageFact {
        MessageFact(
            id: id, threadID: "thread", title: "test", provider: "generic", model: nil, effort: nil, timestamp: time,
            project: nil, words: ["fuck": hits])
    }
}
