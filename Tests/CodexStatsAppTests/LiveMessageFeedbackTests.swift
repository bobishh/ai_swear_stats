import CodexStatsCore
import Foundation
import Testing
@testable import CodexStatsApp

struct LiveMessageFeedbackTests {
    @Test(
        "Given a targeted two-message batch with five profanity hits, when feedback runs then reminder fires and reconciliation does not duplicate it"
    )
    @MainActor
    func targetedMessagesReachSoundAndBurstReminderOnce() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let source = directory.appendingPathComponent("chat.jsonl")
        let now = Date()
        let formatter = ISO8601DateFormatter()
        try (record("baseline", "hello", formatter.string(from: now.addingTimeInterval(-600))) + "\n").write(
            to: source, atomically: true, encoding: .utf8)
        let index = try AnalyticsIndex(databaseURL: directory.appendingPathComponent("index.sqlite"))
        _ = try await index.refresh(roots: [directory])
        let additions =
            [
                record("live-one", "fuck fuck fuck", formatter.string(from: now)),
                record("live-two", "shit shit", formatter.string(from: now)),
            ].joined(separator: "\n") + "\n"
        let handle = try FileHandle(forWritingTo: source)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(("\n" + additions).utf8))
        try handle.close()
        let targeted = try await index.ingestChangedPaths([source], roots: [directory], now: now)
        #expect(targeted.count == 2)
        #expect(targeted.reduce(0) { $0 + $1.words.values.reduce(0, +) } == 5)

        let classifier = try WordClassifier()
        var policy = BurstPolicy()
        var soundBatches = 0
        var notificationBatches = 0
        var reminders = 0
        try await LiveMessageFeedback.deliver(
            targeted,
            playSound: { _ in soundBatches += 1 },
            evaluateNotifications: { messages in
                notificationBatches += 1
                if try policy.evaluate(messages, classifier: classifier, now: now) != nil { reminders += 1 }
            })

        let reconciliation = try await index.refresh(roots: [directory], now: now.addingTimeInterval(1))
        #expect(reconciliation.liveMessages.isEmpty)
        try await LiveMessageFeedback.deliver(
            reconciliation.liveMessages,
            playSound: { _ in soundBatches += 1 },
            evaluateNotifications: { messages in
                notificationBatches += 1
                if try policy.evaluate(messages, classifier: classifier, now: now.addingTimeInterval(1)) != nil {
                    reminders += 1
                }
            })
        #expect(soundBatches == 1)
        #expect(notificationBatches == 1)
        #expect(reminders == 1)
    }

    private func record(_ id: String, _ text: String, _ timestamp: String) -> String {
        "{\"id\":\"\(id)\",\"role\":\"user\",\"content\":\"\(text)\",\"timestamp\":\"\(timestamp)\"}"
    }
}
