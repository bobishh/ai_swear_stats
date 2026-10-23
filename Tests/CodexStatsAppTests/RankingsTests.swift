@testable import CodexStatsCore
import Testing
@testable import CodexStatsApp

struct RankingsTests {
    @Test("Given a ranked word beyond the first fifteen, when searched, then it appears in results with the full count")
    func findsLowRankedWord() {
        let words = (0..<20).map { number in
            RankedWord(id: "word\(number)", family: "family\(number)", category: .profanity, count: 20 - number)
        }
        let results = RankingSearchResults(words: words, query: "word19")
        #expect(results.words.map(\.id) == ["word19"])
        #expect(results.totalCount == 20)
        #expect(results.status == "Found 1 of 20")
        #expect(results.emptyMessage == nil)
    }

    @Test("Given an indexed Russian spelling with е, when searched with ё, then the same word is found")
    func matchesRussianYoVariant() {
        let word = RankedWord(id: "долбоеб", family: "долбоеб", category: .profanity, count: 3)
        let results = RankingSearchResults(words: [word], query: "ДОЛБОЁБ")
        #expect(results.words.map(\.id) == ["долбоеб"])
    }

    @Test("Given a stem ranking, when searching an inflected member, then the group is found")
    func findsGroupByMemberWord() {
        let group = RankedWord(
            id: "ru|profanity|долбоеб", family: "долбоеб", category: .profanity, count: 63, language: "ru",
            displayWord: "долбоеб", memberWords: ["долбоеб", "долбоеба"])
        let results = RankingSearchResults(words: [group], query: "долбоеба")
        #expect(results.words.map(\.id) == [group.id])
        #expect(results.status == "Found 1 of 1")
    }

    @Test("Given rankings with no query match, when searched, then no-results state remains visible")
    func reportsNoMatches() {
        let words = [RankedWord(id: "fuck", family: "fuck", category: .profanity, count: 2)]
        let results = RankingSearchResults(words: words, query: "missing")
        #expect(results.words.isEmpty)
        #expect(results.totalCount == 1)
        #expect(results.status == "Found 0 of 1")
        #expect(results.emptyMessage == "No matching words.")
    }

    @Test("Given an empty selection, when rankings render, then the empty-selection message remains distinct")
    func reportsEmptySelection() {
        let results = RankingSearchResults(words: [], query: "missing")
        #expect(results.status == "Found 0 of 0")
        #expect(results.emptyMessage == "No classified words in this selection.")
    }
}
