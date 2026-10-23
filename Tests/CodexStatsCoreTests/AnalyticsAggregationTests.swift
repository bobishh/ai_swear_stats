import Foundation
import Testing
@testable import CodexStatsCore

struct AnalyticsAggregationTests {
    @Test("Given messages across ten days, when All time is selected, then the chart retains the entire history")
    func fullHistoryTimeline() throws {
        let first = Date(timeIntervalSince1970: 1_790_000_000)
        let facts = [
            timedFact("first", time: first, hits: 2),
            timedFact("middle", time: first.addingTimeInterval(5 * 86_400), hits: 3),
            timedFact("last", time: first.addingTimeInterval(10 * 86_400), hits: 4),
        ]
        let aggregator = AnalyticsAggregator(classifier: try WordClassifier())
        let result = aggregator.build(facts, filter: AnalyticsFilter(), sources: [], indexedAt: nil)
        #expect(result.timeline.first.map { $0.time <= first } == true)
        #expect(result.timeline.reduce(0) { $0 + $1.hits } == 9)
        #expect(result.timeline.contains { $0.hits == 0 })
        #expect(result.timeline.count <= 1_440)
        let filtered = aggregator.build(
            facts, filter: AnalyticsFilter(since: first.addingTimeInterval(9 * 86_400)), sources: [], indexedAt: nil)
        #expect(filtered.timeline.reduce(0) { $0 + $1.hits } == 4)
        #expect(filtered.messages == 1)
    }

    @Test("Given centuries of sparse history, when building the chart, then it remains bounded without dropping hits")
    func longHistoryTimeline() throws {
        let first = Date(timeIntervalSince1970: 0)
        let last = first.addingTimeInterval(200 * 365 * 86_400)
        let result = AnalyticsAggregator(classifier: try WordClassifier()).build(
            [timedFact("first", time: first, hits: 2), timedFact("last", time: last, hits: 3)],
            filter: AnalyticsFilter(), sources: [], indexedAt: nil)
        #expect(result.timeline.first?.time == first)
        #expect(result.timeline.reduce(0) { $0 + $1.hits } == 5)
        #expect(result.timeline.count <= 1_440)
    }

    @Test("Given different history lengths, when coarsening buckets, then rates use the complete bucket duration")
    func adaptiveTimelineRates() throws {
        let first = Date(timeIntervalSince1970: 0)
        let aggregator = AnalyticsAggregator(classifier: try WordClassifier())
        for (span, seconds) in [(180.0, 60.0), (10 * 86_400.0, 3_600.0), (100 * 86_400.0, 86_400.0)] {
            let last = first.addingTimeInterval(span)
            let result = aggregator.build(
                [timedFact("first", time: first, hits: 2), timedFact("last", time: last, hits: 3)],
                filter: AnalyticsFilter(), sources: [], indexedAt: nil)
            #expect(result.timeline.first?.perSecond == 2 / seconds)
            #expect(result.timeline.last?.perSecond == 3 / seconds)
            #expect(result.timeline.reduce(0) { $0 + $1.hits } == 5)
        }
    }

    private func timedFact(_ id: String, time: Date, hits: Int) -> MessageFact {
        MessageFact(
            id: id, threadID: "thread", title: "test", provider: "test", model: nil, effort: nil,
            timestamp: time, project: nil, words: ["fuck": hits])
    }

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

    @Test("Given related word forms, when aggregating, then their Snowball stem rank combines inflections")
    func stemRank() throws {
        let classifier = try WordClassifier()
        let fact = MessageFact(
            id: "1", threadID: "thread", title: "test", provider: "test", model: nil,
            effort: nil, timestamp: nil, project: nil, words: ["fuck": 1, "fucking": 2, "hello": 10])
        let result = AnalyticsAggregator(classifier: classifier).build(
            [fact], filter: AnalyticsFilter(), sources: [], indexedAt: nil)
        #expect(result.topWords.count == 2)
        #expect(result.topStems.first?.stem == "fuck")
        #expect(result.topStems.first?.count == 3)
        #expect(result.missingTimestamps == 1)
    }

    @Test("Given a stem group, when frequencies tie, then its label uses the lexical-first frequent word")
    func stemRepresentativeLabel() throws {
        let facts = [
            MessageFact(
                id: "frequent-base", threadID: "base", title: "test", provider: "test", model: nil,
                effort: nil, timestamp: nil, project: nil, words: ["fuck": 2, "fucked": 4]),
            MessageFact(
                id: "frequent-inflection", threadID: "inflection", title: "test", provider: "test", model: nil,
                effort: nil, timestamp: nil, project: nil, words: ["fucking": 4]),
        ]
        let aggregator = AnalyticsAggregator(classifier: try WordClassifier())
        let all = aggregator.build(facts, filter: AnalyticsFilter(), sources: [], indexedAt: nil)
        let filtered = aggregator.build(
            facts, filter: AnalyticsFilter(thread: "inflection"), sources: [], indexedAt: nil)
        let group = try #require(all.topStems.first)
        #expect(group.displayWord == "fucked")
        #expect(group.family == "fuck")
        #expect(group.memberWords == ["fuck", "fucked", "fucking"])
        #expect(group.count == 10)
        #expect(filtered.topStems.first?.displayWord == "fucking")
        #expect(filtered.topStems.first?.id == group.id)
    }

    @Test("Given recognized words, when ranked by Snowball stem, then inflections group within language and category")
    func snowballStemRanking() throws {
        let fact = MessageFact(
            id: "snowball-groups", threadID: "thread", title: "test", provider: "test", model: nil,
            effort: nil, timestamp: nil, project: nil,
            words: [
                "долбоеб": 1, "долбоеба": 2, "долбоебы": 3, "долбоебина": 1, "долбоебизм": 1,
                "ебать": 1, "еблан": 1, "fucked": 2, "fucking": 1, "motherfuck": 1,
                "puta": 1, "merda": 1,
            ])
        let result = AnalyticsAggregator(classifier: try WordClassifier()).build(
            [fact], filter: AnalyticsFilter(), sources: [], indexedAt: nil)
        #expect(result.topStems.contains { $0.stem == "долбоеб" && $0.language == "ru" && $0.count == 6 })
        #expect(!result.topWords.contains { $0.id == "долбоебина" || $0.id == "долбоебизм" })
        #expect(result.topStems.contains { $0.stem == "еба" && $0.language == "ru" && $0.count == 1 })
        #expect(result.topStems.contains { $0.stem == "ебла" && $0.language == "ru" && $0.count == 1 })
        #expect(result.topStems.contains { $0.stem == "fuck" && $0.language == "en" && $0.count == 3 })
        #expect(result.topStems.contains { $0.stem == "motherfuck" && $0.language == "en" && $0.count == 1 })
        #expect(
            result.topStems.contains {
                $0.stem == "merda" && $0.language == nil && $0.count == 1 && $0.displayWord == "merda"
            })
        #expect(!result.topWords.contains { $0.id == "puta" })
        #expect(result.profanityHits == 13)
    }

    @Test(
        "Given one spelling with conflicting language labels, when grouping, then IDs keep language and category distinct"
    )
    func languageAndCategoryArePartOfStemIdentity() throws {
        let classifier = try WordClassifier()
        guard let spanish = classifier.classify("puta", language: "es"),
            let portuguese = classifier.classify("puta", language: "pt")
        else {
            Issue.record("Expected language-specific classifications")
            return
        }
        let spanishKey = classifier.stemIdentity(for: spanish)
        let portugueseKey = classifier.stemIdentity(for: portuguese)
        #expect(spanishKey.id != portugueseKey.id)
        #expect(spanishKey.language == "es")
        #expect(portugueseKey.language == "pt")
        #expect(spanishKey.category != portugueseKey.category)
    }
}
