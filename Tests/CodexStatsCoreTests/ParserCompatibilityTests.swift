import Foundation
import Testing
@testable import CodexStatsCore

struct ParserCompatibilityTests {
    @Test(
        "Given Codex metadata, tool records and one user message, when indexing with an unknown event, then metadata stays quiet and future types remain unsupported"
    )
    func knownMetadataAndToolRecordsAreIgnored() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let logs = root.appendingPathComponent("logs")
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
        let records = [
            #"{"type":"attachment"}"#,
            #"{"type":"last-prompt"}"#,
            #"{"type":"mode"}"#,
            #"{"type":"custom-title"}"#,
            #"{"type":"reasoning"}"#,
            #"{"type":"function_call"}"#,
            #"{"type":"function_call_output"}"#,
            #"{"record_type":"state"}"#,
            #"{"git":{"branch":"example"},"id":"header","instructions":"synthetic","timestamp":"2026-10-25T12:00:00Z"}"#,
            #"{"id":"user","role":"user","content":"fuck"}"#,
            #"{"record_type":"state","git":{},"id":"user-with-metadata-fields","instructions":"synthetic","timestamp":"2026-10-25T12:00:01Z","role":"user","content":"shit"}"#,
            #"{"type":"future_event"}"#,
            #"{"record_type":"future_state"}"#,
        ]
        try (records.joined(separator: "\n") + "\n").write(
            to: logs.appendingPathComponent("chat.jsonl"), atomically: true, encoding: .utf8)

        let index = try AnalyticsIndex(databaseURL: root.appendingPathComponent("index.sqlite"))
        let result = try await index.refresh(roots: [logs])
        #expect(result.snapshot.messages == 2)
        #expect(result.snapshot.profanityHits == 2)
        #expect(result.snapshot.sources.first?.unsupportedLines == 2)
        #expect(result.snapshot.sources.first?.malformedLines == 0)
    }

    @Test(
        "Given v4 source cursors, when parser v5 refreshes, then only sources with old unsupported lines are reread quietly"
    )
    func v4UpgradeRebuildsOnlyUnsupportedSources() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let logs = root.appendingPathComponent("logs")
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
        let affected = logs.appendingPathComponent("affected.jsonl")
        let unaffected = logs.appendingPathComponent("unaffected.jsonl")
        let affectedText = #"{"type":"attachment"}"# + "\n" + #"{"id":"a","role":"user","content":"fuck"}"# + "\n"
        try affectedText.write(to: affected, atomically: true, encoding: .utf8)
        try (#"{"id":"b","role":"user","content":"shit"}"# + "\n").write(
            to: unaffected, atomically: true, encoding: .utf8)
        let affectedSize = try Data(contentsOf: affected).count
        let index = try AnalyticsIndex(databaseURL: root.appendingPathComponent("index.sqlite"))
        _ = try await index.refresh(roots: [logs])
        let database = try SQLiteDatabase(url: root.appendingPathComponent("index.sqlite"))
        for (url, unsupportedCount) in [(affected, 1), (unaffected, 0)] {
            guard let row = try database.rows("SELECT cursor FROM sources WHERE path=?", [.text(url.path)]).first,
                let cursorJSON = row["cursor"]
            else {
                Issue.record("Missing source cursor for \(url.lastPathComponent)")
                continue
            }
            var cursor = try JSONDecoder().decode(SourceCursor.self, from: Data(cursorJSON.utf8))
            cursor.parserVersion = 4
            cursor.health.unsupportedLines = unsupportedCount
            let encoded = try JSONEncoder().encode(cursor)
            guard let encodedJSON = String(data: encoded, encoding: .utf8) else {
                Issue.record("Could not encode source cursor")
                continue
            }
            try database.execute("UPDATE sources SET cursor=? WHERE path=?", [.text(encodedJSON), .text(url.path)])
        }

        let upgraded = try await index.refresh(roots: [logs])
        #expect(upgraded.bytesRead == affectedSize)
        #expect(upgraded.liveMessages.isEmpty)
        #expect(upgraded.snapshot.messages == 2)
        #expect(upgraded.snapshot.profanityHits == 2)
        #expect(upgraded.snapshot.sources.reduce(0) { $0 + $1.unsupportedLines } == 0)
    }

}
