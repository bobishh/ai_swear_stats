import Foundation

public struct CodexTokenCount: Identifiable, Equatable, Sendable {
    public let token: String
    public let count: Int

    public var id: String { token }
}

public struct CodexRootStats: Identifiable, Equatable, Sendable {
    public let path: String
    public let files: Int
    public let messages: Int
    public let profanityHits: Int

    public var id: String { path }
}

public struct CodexStatsSnapshot: Equatable, Sendable {
    public let scannedFiles: Int
    public let userMessages: Int
    public let profanityHits: Int
    public let exactMatchCounts: [String: Int]
    public let topTokens: [CodexTokenCount]
    public let rootStats: [CodexRootStats]
    public let startedAt: Date
    public let finishedAt: Date

    public var exactMatchTotal: Int {
        exactMatchCounts.values.reduce(0, +)
    }

    public var elapsedSeconds: TimeInterval {
        finishedAt.timeIntervalSince(startedAt)
    }

    public static let empty = CodexStatsSnapshot(
        scannedFiles: 0,
        userMessages: 0,
        profanityHits: 0,
        exactMatchCounts: [:],
        topTokens: [],
        rootStats: [],
        startedAt: .distantPast,
        finishedAt: .distantPast
    )
}

public struct CodexScanErrorSummary: Equatable, Sendable {
    public let message: String
}

public struct CodexStatsScanResult: Equatable, Sendable {
    public let snapshot: CodexStatsSnapshot
    public let error: CodexScanErrorSummary?
}
