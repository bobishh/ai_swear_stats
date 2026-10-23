import Foundation

public struct AnalyticsFilter: Sendable, Hashable {
    public var model: String?
    public var thread: String?
    public var since: Date?
    public var until: Date?
    public init(model: String? = nil, thread: String? = nil, since: Date? = nil, until: Date? = nil) {
        self.model = model
        self.thread = thread
        self.since = since
        self.until = until
    }

    func matches(_ fact: MessageFact) -> Bool {
        (model == nil || model == fact.modelID)
            && (thread == nil || thread == fact.threadID)
            && (since == nil || fact.timestamp.map { $0 >= (since ?? .distantPast) } == true)
            && (until == nil || fact.timestamp.map { $0 <= (until ?? .distantFuture) } == true)
    }
}

public struct MessageFact: Codable, Sendable, Identifiable {
    public let id: String
    public let threadID: String
    public var title: String
    public let provider: String
    public var model: String?
    public var effort: String?
    public let timestamp: Date?
    public let project: String?
    public let words: [String: Int]
    public var modelID: String { provider + "/" + (model ?? "Unknown") }
}

public struct RankedWord: Identifiable, Sendable {
    public let id: String
    public let family: String
    public let language: String?
    public let category: LexicalCategory
    public let count: Int
    public var stem: String { family }
    public let displayWord: String?
    public let memberWords: [String]

    public init(
        id: String, family: String, category: LexicalCategory, count: Int, language: String? = nil,
        displayWord: String? = nil, memberWords: [String] = []
    ) {
        self.id = id
        self.family = family
        self.language = language
        self.category = category
        self.count = count
        self.displayWord = displayWord
        self.memberWords = memberWords
    }
}

public struct ModelSummary: Identifiable, Sendable {
    public let id: String
    public let messages: Int
    public let hits: Int
}

public struct ThreadSummary: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let provider: String
    public let messages: Int
    public let profaneMessages: Int
    public let hits: Int
    public let latest: Date?
    public var profaneMessageShare: Double { messages > 0 ? Double(profaneMessages) / Double(messages) : 0 }
}

public struct IntensityPoint: Identifiable, Sendable {
    public let time: Date
    public let hits: Int
    public let duration: TimeInterval
    public init(time: Date, hits: Int, duration: TimeInterval = 60) {
        self.time = time
        self.hits = hits
        self.duration = duration
    }
    public var id: Date { time }
    public var end: Date { time.addingTimeInterval(duration) }
    public var perSecond: Double { Double(hits) / duration }
}

public struct SourceHealth: Codable, Sendable, Identifiable {
    public let path: String
    public var malformedLines = 0
    public var unsupportedLines = 0
    public var error: String?
    public var id: String { path }
}

public struct AnalyticsSnapshot: Sendable {
    public var messages = 0
    public var totalWords = 0
    public var profanityHits = 0
    public var profaneMessages = 0
    public var categories: [LexicalCategory: Int] = [:]
    public var topWords: [RankedWord] = []
    public var topStems: [RankedWord] = []
    @available(*, deprecated, message: "Use topStems")
    public var topFamilies: [RankedWord] {
        get { topStems }
        set { topStems = newValue }
    }
    public var models: [ModelSummary] = []
    public var threads: [ThreadSummary] = []
    public var timeline: [IntensityPoint] = []
    public var sources: [SourceHealth] = []
    public var sourceMessageCounts: [String: Int] = [:]
    public var folderWarnings: [SourceHealth] = []
    public var missingTimestamps = 0
    public var indexedAt: Date?
    public var hitsPerThousandWords: Double {
        totalWords > 0 ? Double(profanityHits) * 1_000 / Double(totalWords) : 0
    }
    public var profaneMessageShare: Double {
        messages > 0 ? Double(profaneMessages) / Double(messages) : 0
    }
    public static let empty = AnalyticsSnapshot()
}

public struct IndexUpdate: Sendable {
    public let snapshot: AnalyticsSnapshot
    public let bytesRead: Int
    public let liveMessages: [MessageFact]
}

public struct IndexProgress: Sendable {
    public let files: Int
    public let total: Int
    public let bytesRead: Int
    public let snapshot: AnalyticsSnapshot?
}

struct ParserContext: Codable {
    var threadID: String
    var title: String = ""
    var provider = "generic"
    var model: String?
    var effort: String?
    var project: String?
    var pendingIDs: [String] = []
    var automated: Bool?
}

struct SourceCursor: Codable {
    var parserVersion: Int?
    var identity: String
    var offset: UInt64
    var size: UInt64
    var modified: Double
    var context: ParserContext
    var health: SourceHealth
}
