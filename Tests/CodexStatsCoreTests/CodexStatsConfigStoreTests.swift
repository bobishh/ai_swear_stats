import Foundation
import Testing
@testable import CodexStatsCore

struct CodexStatsConfigStoreTests {
    @Test("Given missing config file, when store loads, then default config is created")
    func givenMissingConfig_whenStoreLoads_thenDefaultConfigIsCreated() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = CodexStatsConfigStore(applicationSupportRoot: root)

        let loaded = store.load()

        #expect(loaded.source == .createdDefault)
        #expect(FileManager.default.fileExists(atPath: store.configURL.path))
        #expect(loaded.config.rootPaths == CodexStatsConfig.defaultRootPaths)
    }

    @Test("Given broken config file, when store loads, then defaults stay available")
    func givenBrokenConfig_whenStoreLoads_thenDefaultsStayAvailable() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = CodexStatsConfigStore(applicationSupportRoot: root)
        try FileManager.default.createDirectory(at: store.configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{ nope".utf8).write(to: store.configURL)

        let loaded = store.load()

        #expect(loaded.config.rootPaths == CodexStatsConfig.defaultRootPaths)
        #expect({
            if case .fallbackDefault = loaded.source {
                return true
            }
            return false
        }())
    }
}
