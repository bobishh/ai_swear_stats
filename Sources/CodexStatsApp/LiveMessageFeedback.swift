import CodexStatsCore

enum LiveMessageFeedback {
    @MainActor
    static func deliver(
        _ messages: [MessageFact],
        playSound: ([MessageFact]) -> Void,
        evaluateNotifications: ([MessageFact]) async throws -> Void
    ) async throws {
        guard !messages.isEmpty else { return }
        playSound(messages)
        try await evaluateNotifications(messages)
    }
}
