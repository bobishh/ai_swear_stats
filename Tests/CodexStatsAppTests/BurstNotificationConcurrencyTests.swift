import CodexStatsCore
import Foundation
import Testing
@testable import CodexStatsApp

struct BurstNotificationConcurrencyTests {
    @Test(
        "Given two overlapping notification batches with five combined hits, when each updates burst state atomically, then one reminder fires and replay remains quiet"
    )
    func overlappingBatchesPreserveBurstState() async throws {
        let databaseURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let index = try AnalyticsIndex(databaseURL: databaseURL)
        let now = Date()
        let first = try fact("first", hits: 3, time: now)
        let second = try fact("second", hits: 2, time: now)

        async let firstReminder = index.evaluateBurstMessages([first], now: now)
        async let secondReminder = index.evaluateBurstMessages([second], now: now)
        let reminders = [try await firstReminder, try await secondReminder].compactMap { $0 }
        #expect(reminders.count == 1)

        let reopened = try AnalyticsIndex(databaseURL: databaseURL)
        #expect(try await reopened.evaluateBurstMessages([first, second], now: now.addingTimeInterval(1)) == nil)
    }

    private func fact(_ id: String, hits: Int, time: Date) throws -> MessageFact {
        let data = try JSONSerialization.data(withJSONObject: [
            "id": id, "threadID": "thread", "title": "test", "provider": "generic", "model": NSNull(),
            "effort": NSNull(), "timestamp": time.timeIntervalSinceReferenceDate, "project": NSNull(),
            "words": ["fuck": hits],
        ])
        return try JSONDecoder().decode(MessageFact.self, from: data)
    }
}
