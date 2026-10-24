import Foundation
import Testing
@testable import CodexStatsCore

struct ParserCompatibilityTests {
    @Test(
        "Given cached facts from an older parser, when refreshing, then only the proven compatible v3 cursor skips rereading"
    )
    func parserUpgradeSkipsOnlyCompatibleVersion() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let logs = root.appendingPathComponent("logs")
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
        let source = logs.appendingPathComponent("safe.jsonl")
        let databaseURL = root.appendingPathComponent("index.sqlite")
        try (#"{"id":"safe","role":"user","content":"shit"}"# + "\n").write(
            to: source, atomically: true, encoding: .utf8)
        let sourceSize = try Data(contentsOf: source).count
        let index = try AnalyticsIndex(databaseURL: databaseURL)
        _ = try await index.refresh(roots: [logs])
        let database = try SQLiteDatabase(url: databaseURL)

        func setParserVersion(_ version: Int) throws {
            guard let row = try database.rows("SELECT cursor FROM sources WHERE path=?", [.text(source.path)]).first,
                let cursorJSON = row["cursor"]
            else {
                Issue.record("Missing source cursor")
                return
            }
            var cursor = try JSONDecoder().decode(SourceCursor.self, from: Data(cursorJSON.utf8))
            cursor.parserVersion = version
            let encoded = try JSONEncoder().encode(cursor)
            guard let encodedJSON = String(data: encoded, encoding: .utf8) else {
                Issue.record("Could not encode source cursor")
                return
            }
            try database.execute("UPDATE sources SET cursor=? WHERE path=?", [.text(encodedJSON), .text(source.path)])
        }

        try setParserVersion(2)
        let olderVersion = try await index.refresh(roots: [logs])
        #expect(olderVersion.bytesRead == sourceSize)

        try setParserVersion(3)
        let compatibleVersion = try await index.refresh(roots: [logs])
        #expect(compatibleVersion.bytesRead == 0)
    }
}
