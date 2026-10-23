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
        var stemCounts: [StemIdentity: Int] = [:]
        var stemWordCounts: [StemIdentity: [String: Int]] = [:]
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
                let identity = classifier.stemIdentity(for: match)
                stemCounts[identity, default: 0] += count
                stemWordCounts[identity, default: [:]][word, default: 0] += count
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
                RankedWord(
                    id: word, family: classifier.stemIdentity(for: $0).stem, category: $0.category, count: count,
                    language: $0.language)
            }
        }.sorted { $0.count == $1.count ? $0.id < $1.id : $0.count > $1.count }
        result.timeline = timeline(buckets)
        result.topStems = stemCounts.map { identity, count in
            let memberCounts = stemWordCounts[identity, default: [:]]
            let members = memberCounts.keys.sorted()
            let displayWord = memberCounts.keys.sorted {
                let leftCount = memberCounts[$0, default: 0]
                let rightCount = memberCounts[$1, default: 0]
                return leftCount == rightCount ? $0 < $1 : leftCount > rightCount
            }.first
            return RankedWord(
                id: identity.id, family: identity.stem, category: identity.category, count: count,
                language: identity.language, displayWord: displayWord, memberWords: members)
        }.sorted { $0.count == $1.count ? $0.id < $1.id : $0.count > $1.count }
        return result
    }

    private func timeline(_ buckets: [Date: Int]) -> [IntensityPoint] {
        guard let first = buckets.keys.min(), let last = buckets.keys.max() else { return [] }
        let duration = bucketDuration(first: first, last: last)
        func start(_ time: Date) -> Date {
            Date(timeIntervalSince1970: floor(time.timeIntervalSince1970 / duration) * duration)
        }
        var counts: [Date: Int] = [:]
        for (time, hits) in buckets { counts[start(time), default: 0] += hits }
        var time = start(first)
        let end = start(last)
        var points: [IntensityPoint] = []
        while time <= end {
            points.append(IntensityPoint(time: time, hits: counts[time, default: 0], duration: duration))
            time = time.addingTimeInterval(duration)
        }
        return points
    }

    private func bucketDuration(first: Date, last: Date) -> TimeInterval {
        let maximumPoints = 1_440.0
        for duration in [60.0, 3_600.0, 86_400.0] {
            let count = floor(last.timeIntervalSince1970 / duration) - floor(first.timeIntervalSince1970 / duration) + 1
            if count <= maximumPoints { return duration }
        }
        // Coarsen exceptionally long histories rather than dropping their oldest records.
        return ceil(last.timeIntervalSince(first) / 86_400 / (maximumPoints - 1)) * 86_400
    }
}

private struct ThreadAccumulator {
    let fact: MessageFact
    var messages = 0
    var profaneMessages = 0
    var hits = 0
    var latest: Date?
}
