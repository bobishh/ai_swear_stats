import Foundation
import Testing
@testable import CodexStatsCore

struct UnreadableSubtreeTests {
    @Test(
        "Given an unreadable child directory before a valid source, when indexing the root, then later sources remain indexed and the directory error is visible"
    )
    func unreadableChildDirectoryDoesNotStopDiscovery() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let logs = root.appendingPathComponent("logs")
        let blocked = logs.appendingPathComponent("a-blocked", isDirectory: true)
        try FileManager.default.createDirectory(at: blocked, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: blocked.path) }

        let source = logs.appendingPathComponent("z.jsonl")
        try (#"{"id":"visible","thread_id":"thread","role":"user","content":"hello"}"# + "\n").write(
            to: source, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: blocked.path)
        guard !FileManager.default.isReadableFile(atPath: blocked.path) else { return }

        let index = try AnalyticsIndex(databaseURL: root.appendingPathComponent("index.sqlite"))
        let result = try await index.refresh(roots: [logs])
        #expect(result.snapshot.messages == 1)
        #expect(result.snapshot.sources.map(\.path) == [source.path])
        #expect(
            result.snapshot.folderWarnings.contains {
                URL(fileURLWithPath: $0.path).lastPathComponent == blocked.lastPathComponent && $0.error != nil
            })
    }
}
