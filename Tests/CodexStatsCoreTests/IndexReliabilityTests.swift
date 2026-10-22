import Foundation
import Testing
@testable import CodexStatsCore

struct IndexReliabilityTests {
    @Test("Given agent-authored user-role prompts, when decoding, then automation cannot inflate human intensity")
    func automatedPrompts() throws {
        let adapter = LogAdapter()
        var codex = ParserContext(threadID: "child")
        _ = try adapter.decode(
            Data(#"{"type":"session_meta","payload":{"id":"child","source":{"subagent":{"spawn":{}}}}}"#.utf8),
            context: &codex)
        let codexEvent = try adapter.decode(
            Data(
                #"{"type":"response_item","payload":{"role":"user","content":[{"type":"input_text","text":"fuck"}]}}"#
                    .utf8), context: &codex)
        guard case .ignored = codexEvent else { Issue.record("Codex subagent prompt counted"); return }
        var claude = ParserContext(threadID: "child")
        let claudeEvent = try adapter.decode(
            Data(#"{"type":"user","isSidechain":true,"message":{"role":"user","content":"fuck"}}"#.utf8),
            context: &claude)
        guard case .ignored = claudeEvent else { Issue.record("Claude sidechain prompt counted"); return }
    }

    @Test("Given a legacy instruction block, when decoding, then generated text never becomes an authored message")
    func legacyInstructions() throws {
        var context = ParserContext(threadID: "thread")
        let data = Data(
            #"{"type":"response_item","payload":{"role":"user","content":[{"type":"input_text","text":"<user_instructions>\nfuck\n</user_instructions>"}]}}"#
                .utf8)
        let event = try LogAdapter().decode(data, context: &context)
        guard case .ignored = event else { Issue.record("Generated instructions were counted"); return }
    }

    @Test("Given a failed SQLite insert, when retried, then the cursor and all message rows roll back together")
    func transactionalRetry() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let logs = root.appendingPathComponent("logs")
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
        let file = logs.appendingPathComponent("chat.jsonl")
        let databaseURL = root.appendingPathComponent("index.sqlite")
        try (#"{"role":"user","id":"1","content":"fuck"}"# + "\n").write(to: file, atomically: true, encoding: .utf8)
        let index = try AnalyticsIndex(databaseURL: databaseURL)
        _ = try await index.refresh(roots: [logs])
        let connection = try SQLiteDatabase(url: databaseURL)
        try connection.execute(
            "CREATE TRIGGER fail_insert BEFORE INSERT ON messages BEGIN SELECT RAISE(ABORT,'simulated failure'); END")
        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data((#"{"role":"user","id":"2","content":"fuck"}"# + "\n").utf8))
        try handle.close()
        let failed = try await index.refresh(roots: [logs])
        #expect(failed.snapshot.messages == 1)
        #expect(failed.snapshot.sources.first?.error != nil)
        try connection.execute("DROP TRIGGER fail_insert")
        let retried = try await index.refresh(roots: [logs])
        #expect(retried.snapshot.messages == 2)
        #expect(retried.snapshot.profanityHits == 2)
        #expect(retried.snapshot.sources.first?.error == nil)
        #expect(try await index.refresh(roots: [logs]).bytesRead == 0)
    }

    @Test("Given legacy preferences, when decoded, then folders persist and regex settings are retired")
    func legacyConfigMigration() throws {
        let data = Data(#"{"rootPaths":["/my/logs"],"intervalSeconds":300,"profanityPatterns":["ignored"]}"#.utf8)
        let config = try JSONDecoder().decode(CodexStatsConfig.self, from: data)
        #expect(config.rootPaths == ["/my/logs"])
        #expect(config.intervalSeconds == 5)
        #expect(config.notificationsEnabled == false)
        #expect(try JSONDecoder().decode(CodexStatsConfig.self, from: JSONEncoder().encode(config)) == config)
    }
}
