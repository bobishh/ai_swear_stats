import Foundation
import Testing
@testable import CodexStatsCore

struct CodexStatsScannerTests {
    @Test("Given large Unicode tool logs and CRLF, when scanning, then only user messages count")
    func largeUnicodeLogs() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let toolLine = #"{"payload":{"role":"assistant","content":[{"type":"output_text","text":""#
            + String(repeating: "данные 👩🏽‍💻 блять ", count: 200)
            + #""}]}}"#
        let userLine = #"{"payload":{"role":"user","content":[{"type":"input_text","text":"блять"}]}}"#
        let historyLine = #"{"text":"нахуй"}"#
        let text = Array(repeating: toolLine, count: 2_000).joined(separator: "\r\n")
            + "\r\nmalformed\r\n" + userLine + "\r\n" + historyLine
        try text.write(to: root.appendingPathComponent("history.jsonl"), atomically: true, encoding: .utf8)
        let start = ContinuousClock.now
        var progressCounts: [Int] = []
        let result = try CodexStatsScanner().scan(config: CodexStatsConfig(rootPaths: [root.path])) { files, _ in
            progressCounts.append(files)
        }
        print("Unicode log scan: \(start.duration(to: .now))")
        #expect(result.userMessages == 2)
        #expect(result.profanityHits == 2)
        #expect(progressCounts.last == 1)
    }

    @Test("Given profane exact filter and regex filters, when scan runs, then exact count stays separate")
    func givenExactFilterAndRegexFilters_whenScanRuns_thenExactCountStaysSeparate() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sessionRoot = root.appendingPathComponent(".codex/sessions", isDirectory: true)
        try FileManager.default.createDirectory(at: sessionRoot, withIntermediateDirectories: true)

        let fileURL = sessionRoot.appendingPathComponent("rollout-test.jsonl")
        let lines = [
            #"{"type":"response_item","payload":{"role":"user","content":[{"type":"input_text","text":"блядь блять нахуй"}]}}"#,
            #"{"type":"response_item","payload":{"role":"assistant","content":[{"type":"output_text","text":"ignore"}]}}"#
        ].joined(separator: "\n")
        try lines.write(to: fileURL, atomically: true, encoding: .utf8)

        let config = CodexStatsConfig(
            rootPaths: [root.appendingPathComponent(".codex").path],
            includePathFragments: ["/sessions/"],
            excludeBasenames: [],
            exactMatchTokens: ["блядь"],
            profanityPatterns: ["^блять$", "^нахуй$"],
            intervalSeconds: 60,
            topLimit: 10
        )

        let snapshot = try CodexStatsScanner(fileManager: .default).scan(config: config, now: Date(timeIntervalSince1970: 1_000))

        #expect(snapshot.scannedFiles == 1)
        #expect(snapshot.userMessages == 1)
        #expect(snapshot.exactMatchCounts["блядь"] == 1)
        #expect(snapshot.exactMatchTotal == 1)
        #expect(snapshot.profanityHits == 2)
        #expect(snapshot.topTokens == [
            CodexTokenCount(token: "блять", count: 1),
            CodexTokenCount(token: "нахуй", count: 1)
        ])
    }

    @Test("Given clean dialogue, when scan runs, then counts stay empty")
    func givenCleanDialogue_whenScanRuns_thenCountsStayEmpty() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sessionRoot = root.appendingPathComponent(".codex/archived_sessions", isDirectory: true)
        try FileManager.default.createDirectory(at: sessionRoot, withIntermediateDirectories: true)

        let fileURL = sessionRoot.appendingPathComponent("rollout-clean.jsonl")
        let lines = [
            #"{"type":"response_item","payload":{"role":"user","content":[{"type":"input_text","text":"plain text only"}]}}"#
        ].joined(separator: "\n")
        try lines.write(to: fileURL, atomically: true, encoding: .utf8)

        let config = CodexStatsConfig(
            rootPaths: [root.appendingPathComponent(".codex").path],
            includePathFragments: ["/archived_sessions/"],
            excludeBasenames: [],
            exactMatchTokens: ["блядь"],
            profanityPatterns: ["^блять$", "^нахуй$"],
            intervalSeconds: 60,
            topLimit: 10
        )

        let snapshot = try CodexStatsScanner(fileManager: .default).scan(config: config, now: Date(timeIntervalSince1970: 1_000))

        #expect(snapshot.scannedFiles == 1)
        #expect(snapshot.userMessages == 1)
        #expect(snapshot.exactMatchCounts["блядь"] == 0)
        #expect(snapshot.exactMatchTotal == 0)
        #expect(snapshot.profanityHits == 0)
        #expect(snapshot.topTokens.isEmpty)
    }
}
