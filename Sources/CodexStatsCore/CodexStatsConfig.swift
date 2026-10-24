import Foundation

/// Preserves existing log-folder settings while migrating the old regex configuration.
public struct CodexStatsConfig: Codable, Equatable, Sendable {
    public var schemaVersion = 2
    public var rootPaths: [String]
    public var intervalSeconds: TimeInterval
    public var notificationsEnabled: Bool
    public var soundEnabled: Bool

    public init(
        rootPaths: [String] = Self.defaultRootPaths, intervalSeconds: TimeInterval = 5,
        notificationsEnabled: Bool = false, soundEnabled: Bool = false
    ) {
        self.rootPaths = rootPaths
        self.intervalSeconds = intervalSeconds
        self.notificationsEnabled = notificationsEnabled
        self.soundEnabled = soundEnabled
    }

    public static let defaultRootPaths = ["~/.codex", "~/.codex-work", "~/.claude/projects"]

    public func resolvedRootURLs() -> [URL] {
        Array(
            Set(
                rootPaths.map {
                    URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath).standardizedFileURL
                        .resolvingSymlinksInPath()
                })
        )
        .sorted { $0.path < $1.path }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rootPaths = try container.decodeIfPresent([String].self, forKey: .rootPaths) ?? Self.defaultRootPaths
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? false
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? false
        intervalSeconds =
            container.contains(.schemaVersion)
            ? try container.decodeIfPresent(Double.self, forKey: .intervalSeconds) ?? 5 : 5
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, rootPaths, intervalSeconds, notificationsEnabled, soundEnabled
    }
}
