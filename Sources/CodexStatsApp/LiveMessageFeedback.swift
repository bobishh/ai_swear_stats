import CodexStatsCore

enum LiveMessageFeedback {
    @MainActor
    static func deliver(
        _ messages: [MessageFact],
        reactToLiveProfanity: ([MessageFact]) -> Void,
        evaluateNotifications: ([MessageFact]) async throws -> Void
    ) async throws {
        guard !messages.isEmpty else { return }
        reactToLiveProfanity(messages)
        try await evaluateNotifications(messages)
    }
}
