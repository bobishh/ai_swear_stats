import Foundation
import Testing
@testable import CodexStatsCore

struct CodexStatsConfigStoreTests {
    @Test("Given missing config file, when store loads, then default config is created")
    func givenMissingConfig_whenStoreLoads_thenDefaultConfigIsCreated() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = CodexStatsConfigStore(applicationSupportRoot: root)

        let loaded = store.load()

        #expect(loaded.source == .createdDefault)
        #expect(FileManager.default.fileExists(atPath: store.configURL.path))
        #expect(loaded.config.rootPaths == CodexStatsConfig.defaultRootPaths)
        #expect(!loaded.config.soundEnabled)
    }

    @Test("Given sound preference, when the config saves and reloads, then the toggle state persists")
    func soundPreferencePersists() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = CodexStatsConfigStore(applicationSupportRoot: root)
        var config = store.load().config
        config.soundEnabled = true

        try store.save(config)

        #expect(store.load().config.soundEnabled)
    }

    @Test("Given a v2 config, when it loads, then Codex Work sessions are added once and the migration persists")
    func codexWorkSessionsAreMigrated() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = CodexStatsConfigStore(applicationSupportRoot: root)
        try FileManager.default.createDirectory(
            at: store.configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(
            #"{"schemaVersion":2,"rootPaths":["~/.codex"],"intervalSeconds":5,"notificationsEnabled":false,"soundEnabled":false}"#
                .utf8
        ).write(to: store.configURL)

        let migrated = store.load().config

        #expect(migrated.schemaVersion == CodexStatsConfig.currentSchemaVersion)
        #expect(migrated.rootPaths == ["~/.codex", CodexStatsConfig.codexWorkRootPath])
        #expect(store.load().config.rootPaths == migrated.rootPaths)
    }

    @Test("Given broken config file, when store loads, then defaults stay available")
    func givenBrokenConfig_whenStoreLoads_thenDefaultsStayAvailable() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = CodexStatsConfigStore(applicationSupportRoot: root)
        try FileManager.default.createDirectory(
            at: store.configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{ nope".utf8).write(to: store.configURL)

        let loaded = store.load()

        #expect(loaded.config.rootPaths == CodexStatsConfig.defaultRootPaths)
        #expect(
            {
                if case .fallbackDefault = loaded.source {
                    return true
                }
                return false
            }())
    }
}
