import Foundation

public struct CodexStatsConfig: Codable, Equatable, Sendable {
    public var rootPaths: [String]
    public var includePathFragments: [String]
    public var excludeBasenames: [String]
    public var exactMatchTokens: [String]
    public var profanityPatterns: [String]
    public var intervalSeconds: TimeInterval
    public var topLimit: Int

    public init(
        rootPaths: [String] = Self.defaultRootPaths,
        includePathFragments: [String] = Self.defaultIncludePathFragments,
        excludeBasenames: [String] = Self.defaultExcludeBasenames,
        exactMatchTokens: [String] = Self.defaultExactMatchTokens,
        profanityPatterns: [String] = Self.defaultProfanityPatterns,
        intervalSeconds: TimeInterval = 300,
        topLimit: Int = 10
    ) {
        self.rootPaths = rootPaths
        self.includePathFragments = includePathFragments
        self.excludeBasenames = excludeBasenames
        self.exactMatchTokens = exactMatchTokens
        self.profanityPatterns = profanityPatterns
        self.intervalSeconds = intervalSeconds
        self.topLimit = topLimit
    }

    public static let defaultRootPaths = [
        "~/.codex",
        "~/.codex-work"
    ]

    public static let defaultIncludePathFragments = [
        "/sessions/",
        "/archived_sessions/",
        "/history.jsonl",
        "/session_index.jsonl"
    ]

    public static let defaultExcludeBasenames = [
        "transcription-history.jsonl"
    ]

    public static let defaultExactMatchTokens = [
        "блядь"
    ]

    public static let defaultProfanityPatterns = [
        "^блять$",
        "^блят[а-яё]*$",
        "^нахуй$",
        "^хуй[а-яё]*$",
        "^хуя[а-яё]*$",
        "^пизд[а-яё]*$",
        "^заеб[а-яё]*$",
        "^проеб[а-яё]*$",
        "^отъеб[а-яё]*$",
        "^объеб[а-яё]*$",
        "^мудак$",
        "^пидор[а-яё]*$",
        "^сук[а-яё]*$",
        "^хер[а-яё]*$",
        "^говн[а-яё]*$",
        "^дерьм[а-яё]*$"
    ]

    public func resolvedRootURLs(fileManager: FileManager = .default) -> [URL] {
        rootPaths.compactMap { rootPath in
            let expanded = NSString(string: rootPath).expandingTildeInPath
            let url = URL(fileURLWithPath: expanded)
            guard fileManager.fileExists(atPath: url.path) else {
                return nil
            }
            return url
        }
    }

    public func shouldScan(fileURL: URL) -> Bool {
        let path = fileURL.standardizedFileURL.path
        let basename = fileURL.lastPathComponent

        guard excludeBasenames.contains(basename) == false else {
            return false
        }

        return includePathFragments.contains { path.contains($0) }
    }

    public func compiledProfanityRegexes() throws -> [NSRegularExpression] {
        try profanityPatterns.map { pattern in
            try NSRegularExpression(pattern: pattern, options: [])
        }
    }
}
