import Foundation

public final class CodexStatsConfigStore {
    public enum LoadSource: Equatable {
        case loaded
        case createdDefault
        case fallbackDefault(error: String)
    }

    public struct LoadedConfig: Equatable {
        public let config: CodexStatsConfig
        public let source: LoadSource
    }

    public let configURL: URL
    private let fileManager: FileManager

    public init(
        applicationSupportRoot: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
            "Library/Application Support")
    ) {
        fileManager = .default
        configURL =
            applicationSupportRoot
            .appendingPathComponent("codex_stats", isDirectory: true)
            .appendingPathComponent("config.json")
    }

    public func load() -> LoadedConfig {
        do {
            if fileManager.fileExists(atPath: configURL.path) {
                let data = try Data(contentsOf: configURL)
                var config = try JSONDecoder().decode(CodexStatsConfig.self, from: data)
                if config.migrate() {
                    try save(config)
                }
                return LoadedConfig(config: config, source: .loaded)
            }

            let defaults = CodexStatsConfig()
            try save(defaults)
            return LoadedConfig(config: defaults, source: .createdDefault)
        } catch {
            let defaults = CodexStatsConfig()
            return LoadedConfig(config: defaults, source: .fallbackDefault(error: error.localizedDescription))
        }
    }

    public func save(_ config: CodexStatsConfig) throws {
        try fileManager.createDirectory(
            at: configURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(config)
        try data.write(to: configURL, options: [.atomic])
    }
}
