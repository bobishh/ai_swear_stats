import Foundation
import Testing
@testable import CodexStatsCore

struct AnalyticsAggregationTests {
    @Test("Given several hits in one message, when summarizing a thread, then its percentage counts messages once")
    func threadProfanityShare() throws {
        let words = [["fuck": 3], ["fucking": 1], ["hello": 5, "говно": 1]]
        let facts = words.enumerated().map { number, words in
            MessageFact(
                id: String(number), threadID: "thread", title: "test", provider: "test", model: nil,
                effort: nil, timestamp: nil, project: nil, words: words)
        }
        let result = AnalyticsAggregator(classifier: try WordClassifier()).build(
            facts, filter: AnalyticsFilter(), sources: [], indexedAt: nil)
        let thread = try #require(result.threads.first)
        #expect(thread.messages == 3)
        #expect(thread.hits == 4)
        #expect(thread.profaneMessages == 2)
        #expect(abs(thread.profaneMessageShare - 2.0 / 3.0) < 0.0001)
        #expect(thread.profaneMessageShare == result.profaneMessageShare)
    }

    @Test("Given related word forms, when aggregating, then their family rank combines inflections")
    func familyRank() throws {
        let classifier = try WordClassifier()
        let fact = MessageFact(
            id: "1", threadID: "thread", title: "test", provider: "test", model: nil,
            effort: nil, timestamp: nil, project: nil, words: ["fuck": 1, "fucking": 2, "hello": 10])
        let result = AnalyticsAggregator(classifier: classifier).build(
            [fact], filter: AnalyticsFilter(), sources: [], indexedAt: nil)
        #expect(result.topWords.count == 2)
        #expect(result.topFamilies.first?.id == "fuck")
        #expect(result.topFamilies.first?.count == 3)
        #expect(result.missingTimestamps == 1)
    }
}
