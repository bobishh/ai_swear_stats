import Foundation
import Testing
@testable import CodexStatsApp
@testable import CodexStatsCore

struct ThreadSortOrderTests {
    @Test("Given a tiny profane thread and an established hot thread, when sorting by heat, then weighted heat wins")
    func weightedTemperature() {
        let tiny = thread("tiny", messages: 2, profane: 2, latest: 30)
        let hot = thread("hot", messages: 100, profane: 60, latest: 10)
        let quiet = thread("quiet", messages: 100, profane: 0, latest: 40)
        #expect(ThreadSortOrder.temperature.ordered([quiet, tiny, hot]).map(\.id) == ["hot", "tiny", "quiet"])
        #expect(ThreadSortOrder.recent.ordered([hot, quiet, tiny]).map(\.id) == ["quiet", "tiny", "hot"])
    }

    @Test("Given equal temperatures, when refreshing with a different input order, then recency and ID break ties")
    func stableTies() {
        let older = thread("older", latest: 10)
        let newerA = thread("a", latest: 20)
        let newerB = thread("b", latest: 20)
        let unknown = thread("unknown", latest: nil)
        for order in ThreadSortOrder.allCases {
            let input = [unknown, newerB, older, newerA]
            let expected = ["a", "b", "older", "unknown"]
            #expect(order.ordered(input).map(\.id) == expected)
            #expect(order.ordered(input.reversed()).map(\.id) == expected)
            #expect(order.ordered([]).isEmpty)
        }
    }

    private func thread(_ id: String, messages: Int = 100, profane: Int = 10, latest: Double?) -> ThreadSummary {
        ThreadSummary(
            id: id, title: id, provider: "test", messages: messages, profaneMessages: profane, hits: profane,
            latest: latest.map(Date.init(timeIntervalSince1970:)))
    }
}
