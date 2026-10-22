import Foundation

/// Tracks only live ingestion events; archive imports never enter this policy.
public struct BurstPolicy: Codable, Sendable {
    public var threshold = 5
    public var minimumMessages = 2
    public var windowSeconds: TimeInterval = 120
    public var cooldownSeconds: TimeInterval = 900
    private var samples: [Sample] = []
    private var lastAlert: Date?
    private var armed = true
    private var templateIndex = 0

    public init() {}

    public mutating func evaluate(_ messages: [MessageFact], classifier: WordClassifier, now: Date = Date()) throws
        -> String?
    {
        samples.removeAll { $0.time < now.addingTimeInterval(-windowSeconds) }
        if samples.reduce(0, { $0 + $1.hits }) < threshold { armed = true }
        for message in messages {
            guard let time = message.timestamp, time >= now.addingTimeInterval(-windowSeconds), time <= now,
                !samples.contains(where: { $0.id == message.id })
            else { continue }
            let hits = message.words.reduce(0) { sum, pair in
                sum + (classifier.classify(pair.key)?.category == .profanity ? pair.value : 0)
            }
            if hits > 0 { samples.append(Sample(id: message.id, time: time, hits: hits)) }
        }
        guard armed, samples.count >= minimumMessages, samples.reduce(0, { $0 + $1.hits }) >= threshold,
            lastAlert.map({ now.timeIntervalSince($0) >= cooldownSeconds }) ?? true
        else { return nil }
        guard let url = ResourceBundle.bundle.url(forResource: "alerts", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let templates = try JSONDecoder().decode([String].self, from: Data(contentsOf: url))
        guard !templates.isEmpty else { return nil }
        let message = templates[templateIndex % templates.count]
        templateIndex += 1
        lastAlert = now
        armed = false
        return message
    }

    private struct Sample: Codable, Sendable {
        let id: String
        let time: Date
        let hits: Int
    }
}
