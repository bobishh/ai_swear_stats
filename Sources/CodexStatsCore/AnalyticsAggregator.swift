import Foundation

struct AnalyticsAggregator {
    let classifier: WordClassifier

    func build(_ facts: [MessageFact], filter: AnalyticsFilter, sources: [SourceHealth], indexedAt: Date?)
        -> AnalyticsSnapshot
    {
        var result = AnalyticsSnapshot.empty
        result.sources = sources
        result.indexedAt = indexedAt
        var wordCounts: [String: Int] = [:]
        var familyCounts: [String: Int] = [:]
        var familyCategories: [String: LexicalCategory] = [:]
        var modelCounts: [String: (messages: Int, hits: Int)] = [:]
        var threadCounts: [String: ThreadAccumulator] = [:]
        var buckets: [Date: Int] = [:]
        var seen: Set<String> = []
        for fact in facts {
            guard seen.insert(fact.id).inserted else { continue }
            guard filter.matches(fact) else { continue }
            result.messages += 1
            result.totalWords += fact.words.values.reduce(0, +)
            var hits = 0
            for (word, count) in fact.words {
                guard let match = classifier.classifyNormalized(word) else { continue }
                result.categories[match.category, default: 0] += count
                wordCounts[word, default: 0] += count
                familyCounts[match.family, default: 0] += count
                familyCategories[match.family] = match.category
                if match.category == .profanity { hits += count }
            }
            result.profanityHits += hits
            if hits > 0 { result.profaneMessages += 1 }
            let model = modelCounts[fact.modelID, default: (0, 0)]
            modelCounts[fact.modelID] = (model.messages + 1, model.hits + hits)
            let thread = threadCounts[fact.threadID, default: ThreadAccumulator(fact: fact)]
            let latest = [thread.latest, fact.timestamp].compactMap { $0 }.max()
            threadCounts[fact.threadID] = ThreadAccumulator(
                fact: fact, messages: thread.messages + 1, profaneMessages: thread.profaneMessages + (hits > 0 ? 1 : 0),
                hits: thread.hits + hits, latest: latest)
            if let time = fact.timestamp {
                let minute = Date(timeIntervalSince1970: floor(time.timeIntervalSince1970 / 60) * 60)
                buckets[minute, default: 0] += hits
            } else {
                result.missingTimestamps += 1
            }
        }
        result.models = modelCounts.map { ModelSummary(id: $0.key, messages: $0.value.messages, hits: $0.value.hits) }
            .sorted { $0.id < $1.id }
        result.threads = threadCounts.map { key, value in
            ThreadSummary(
                id: key, title: value.fact.title.isEmpty ? key : value.fact.title, provider: value.fact.provider,
                messages: value.messages, profaneMessages: value.profaneMessages, hits: value.hits, latest: value.latest
            )
        }.sorted { ($0.latest ?? .distantPast) > ($1.latest ?? .distantPast) }
        result.topWords = wordCounts.compactMap { word, count in
            classifier.classifyNormalized(word).map {
                RankedWord(id: word, family: $0.family, category: $0.category, count: count)
            }
        }.sorted { $0.count == $1.count ? $0.id < $1.id : $0.count > $1.count }
        result.timeline = timeline(buckets)
        result.topFamilies = familyCounts.map { family, count in
            RankedWord(id: family, family: family, category: familyCategories[family] ?? .profanity, count: count)
        }.sorted { $0.count == $1.count ? $0.id < $1.id : $0.count > $1.count }
        return result
    }

    private func timeline(_ buckets: [Date: Int]) -> [IntensityPoint] {
        guard let first = buckets.keys.min(), let last = buckets.keys.max() else { return [] }
        // Keep the chart bounded to the most recent 24 hours; period totals still cover all matching records.
        var time = max(first, last.addingTimeInterval(-86_340))
        var points: [IntensityPoint] = []
        while time <= last {
            points.append(IntensityPoint(time: time, hits: buckets[time, default: 0]))
            time = time.addingTimeInterval(60)
        }
        return points
    }
}

private struct ThreadAccumulator {
    let fact: MessageFact
    var messages = 0
    var profaneMessages = 0
    var hits = 0
    var latest: Date?
}
