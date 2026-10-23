import Foundation
import Testing
@testable import CodexStatsCore

struct AnalyticsAcceptanceTests {
    @Test(
        "Given a selected date interval, when filtering analytics, then metrics and navigation include only messages inside it"
    )
    func selectedDateInterval() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write(
            "range.jsonl",
            lines: [
                #"{"id":"before","thread_id":"before","role":"user","content":"fuck","timestamp":"2026-10-20T23:59:00Z"}"#,
                #"{"id":"inside","thread_id":"inside","role":"user","content":"fuck fuck","timestamp":"2026-10-21T12:00:00Z"}"#,
                #"{"id":"after","thread_id":"after","role":"user","content":"fuck fuck fuck","timestamp":"2026-10-22T00:01:00Z"}"#,
            ])
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        _ = try await index.refresh(roots: [fixture.logs])
        let filter = AnalyticsFilter(
            since: Date(timeIntervalSince1970: 1_792_584_000),
            until: Date(timeIntervalSince1970: 1_792_627_200))
        let selected = try await index.snapshot(filter: filter)
        #expect(selected.messages == 1)
        #expect(selected.profanityHits == 2)
        #expect(selected.threads.map(\.id) == ["generic:inside"])
    }

    @Test("Given a missing folder, when listing source files, then folder warnings do not inflate file counts")
    func sourceFilesExcludeFolders() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write("chat.jsonl", lines: [generic(id: "1", text: "hello"), generic(id: "2", text: "fuck")])
        let missing = fixture.root.appendingPathComponent("missing")
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        let result = try await index.refresh(roots: [fixture.logs, missing])
        #expect(result.snapshot.sources.count == 1)
        #expect(result.snapshot.sources.first?.path == fixture.logs.appendingPathComponent("chat.jsonl").path)
        #expect(result.snapshot.sourceMessageCounts[fixture.logs.appendingPathComponent("chat.jsonl").path] == 2)
        #expect(result.snapshot.folderWarnings.map(\.path) == [missing.path])
        let reopened = try AnalyticsIndex(databaseURL: fixture.database)
        #expect(try await reopened.snapshot().sourceMessageCounts.values.reduce(0, +) == 2)
    }

    @Test("Given unrelated source files, when filtering a thread, model or period, then diagnostics follow selection")
    func scopedSources() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write(
            "a.jsonl",
            lines: [
                #"{"id":"a","thread_id":"a","role":"user","content":"fuck","model":"a","timestamp":"2026-10-21T10:00:00Z"}"#
            ])
        try fixture.write(
            "b.jsonl",
            lines: [
                "broken",
                #"{"id":"b","thread_id":"b","role":"user","content":"hello","model":"b","timestamp":"2026-10-20T10:00:00Z"}"#,
            ])
        try fixture.write("empty.jsonl", lines: ["{}"])
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        #expect(try await index.refresh(roots: [fixture.logs]).snapshot.sources.count == 3)
        let filters = [
            AnalyticsFilter(thread: "generic:a"), AnalyticsFilter(model: "generic/a"),
            AnalyticsFilter(since: Date(timeIntervalSince1970: 1_792_540_800)),
        ]
        for filter in filters {
            let snapshot = try await index.snapshot(filter: filter)
            #expect(snapshot.messages == 1)
            #expect(snapshot.sourceMessageCounts.values.reduce(0, +) == 1)
            #expect(snapshot.sources.map { URL(fileURLWithPath: $0.path).lastPathComponent } == ["a.jsonl"])
        }
        #expect(try await index.snapshot(filter: AnalyticsFilter(thread: "missing")).sources.isEmpty)
        let selected = try await index.snapshot(filter: AnalyticsFilter(thread: "generic:b"))
        #expect(selected.sources.count == 1)
        #expect(selected.sources.first?.malformedLines == 1)
        #expect(try await index.snapshot().sources.count == 3)
    }

    @Test("Given mixed AI logs, when refreshed and reopened, then overall and per-model counts persist")
    func mixedProviders() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write(
            "codex.jsonl",
            lines: [
                #"{"type":"session_meta","payload":{"id":"codex-thread","cwd":"/project"}}"#,
                #"{"timestamp":"2026-10-21T10:00:00Z","type":"response_item","payload":{"id":"c1","role":"user","content":[{"type":"input_text","text":"блять нахуй"}]}}"#,
                #"{"type":"turn_context","payload":{"model":"model-a","effort":"high"}}"#,
                #"{"type":"event_msg","payload":{"type":"item_completed","item":{"type":"UserMessage","id":"mirror","content":[{"text":"блять нахуй"}]}}}"#,
                ##"{"type":"response_item","payload":{"role":"user","content":[{"type":"input_text","text":"# AGENTS.md instructions\nблять"}]}}"##,
            ])
        try fixture.write(
            "claude.jsonl",
            lines: [
                #"{"type":"user","sessionId":"claude-thread","uuid":"u1","timestamp":"2026-10-21T10:02:00Z","message":{"role":"user","content":"fucking hell"}}"#,
                #"{"type":"assistant","sessionId":"claude-thread","message":{"role":"assistant","model":"model-b","content":[{"type":"text","text":"fuck"}]}}"#,
            ])
        try fixture.write(
            "generic.jsonl",
            lines: [
                #"{"id":"g1","thread_id":"generic-thread","role":"user","content":"hello","model":"model-c","provider":"custom","timestamp":"2026-10-21T10:00:00Z"}"#
            ])
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        let result = try await index.refresh(roots: [fixture.logs])
        #expect(result.snapshot.messages == 3)
        #expect(result.snapshot.profanityHits == 3)
        #expect(result.snapshot.models.count == 3)
        #expect(result.snapshot.timeline.count == 3)
        #expect(result.snapshot.timeline[1].hits == 0)
        #expect(result.liveMessages.isEmpty)
        let selected = try await index.snapshot(filter: AnalyticsFilter(model: "codex/model-a"))
        #expect(selected.messages == 1)
        #expect(selected.profanityHits == 2)
        #expect(selected.timeline.count == 1)
        let reopened = try AnalyticsIndex(databaseURL: fixture.database)
        #expect(try await reopened.snapshot().messages == 3)
        let unchanged = try await reopened.refresh(roots: [fixture.logs])
        #expect(unchanged.bytesRead == 0)
        #expect(unchanged.snapshot.messages == 3)
    }

    @Test("Given recent appends while closed, when reopening, then backlog is indexed without live alerts")
    func restartSuppressesBacklog() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write("chat.jsonl", lines: [generic(id: "1", text: "fuck")])
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        _ = try await index.refresh(roots: [fixture.logs])
        try fixture.append("chat.jsonl", text: generic(id: "2", text: "fuck fuck fuck") + "\n")
        let reopened = try AnalyticsIndex(databaseURL: fixture.database)
        let result = try await reopened.refresh(roots: [fixture.logs])
        #expect(result.snapshot.messages == 2)
        #expect(result.liveMessages.isEmpty)
    }

    @Test("Given an indexed file, when a partial line is completed and replayed, then only its tail counts once")
    func incrementalTail() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write("chat.jsonl", lines: [generic(id: "1", text: "fuck")])
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        _ = try await index.refresh(roots: [fixture.logs])
        let line = generic(id: "2", text: "fuck fuck fuck fuck")
        let split = line.index(line.startIndex, offsetBy: line.count / 2)
        try fixture.append("chat.jsonl", text: String(line[..<split]))
        #expect(try await index.refresh(roots: [fixture.logs]).snapshot.messages == 1)
        try fixture.append("chat.jsonl", text: String(line[split...]) + "\n")
        let appended = try await index.refresh(roots: [fixture.logs])
        #expect(appended.snapshot.messages == 2)
        #expect(appended.snapshot.profanityHits == 5)
        #expect(appended.bytesRead < 1_024)
        #expect(appended.liveMessages.count == 1)
        try fixture.append("chat.jsonl", text: line + "\n")
        #expect(try await index.refresh(roots: [fixture.logs]).snapshot.messages == 2)
        try fixture.write("chat.jsonl", lines: [generic(id: "3", text: "hello")])
        let rebuilt = try await index.refresh(roots: [fixture.logs])
        #expect(rebuilt.snapshot.messages == 1)
        #expect(rebuilt.snapshot.profanityHits == 0)
        #expect(rebuilt.liveMessages.isEmpty)
    }

    @Test("Given a prompt split from its context, when the model arrives later, then attribution updates once")
    func modelAcrossBatches() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write(
            "chat.jsonl",
            lines: [
                #"{"type":"response_item","payload":{"id":"1","role":"user","content":[{"type":"input_text","text":"блять"}]}}"#
            ])
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        _ = try await index.refresh(roots: [fixture.logs])
        try fixture.append("chat.jsonl", text: #"{"type":"turn_context","payload":{"model":"later"}}"# + "\n")
        let result = try await index.refresh(roots: [fixture.logs])
        #expect(result.snapshot.messages == 1)
        #expect(result.snapshot.models.first?.id == "codex/later")
    }

    @Test("Given a classifier update, when logs are unchanged, then word facts reclassify without source reads")
    func reclassification() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write("chat.jsonl", lines: [generic(id: "1", text: "toaster долбоёб Scheiße")])
        let first = try AnalyticsIndex(databaseURL: fixture.database)
        #expect(try await first.refresh(roots: [fixture.logs]).snapshot.profanityHits == 2)
        let classifier = try WordClassifier(extraWords: ["toaster": "fuck"])
        let changed = try AnalyticsIndex(databaseURL: fixture.database, classifier: classifier)
        let result = try await changed.refresh(roots: [fixture.logs])
        #expect(result.bytesRead == 0)
        #expect(result.snapshot.profanityHits == 3)
    }

    @Test("Given malformed and unknown records, when indexing, then health is visible and valid rows survive")
    func sourceHealth() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write("history.jsonl", lines: ["broken", "{}", generic(id: "1", text: "hello")])
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        let result = try await index.refresh(roots: [fixture.logs])
        #expect(result.snapshot.messages == 1)
        #expect(result.snapshot.sources.first?.malformedLines == 1)
        #expect(result.snapshot.sources.first?.unsupportedLines == 1)
    }

    private func generic(id: String, text: String) -> String {
        let time = ISO8601DateFormatter().string(from: Date())
        return "{\"id\":\"\(id)\",\"role\":\"user\",\"content\":\"\(text)\",\"timestamp\":\"\(time)\"}"
    }
}

private struct LogFixture {
    let root: URL
    let logs: URL
    let database: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        logs = root.appendingPathComponent("logs")
        database = root.appendingPathComponent("index.sqlite")
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
    }

    func write(_ name: String, lines: [String]) throws {
        try (lines.joined(separator: "\n") + "\n").write(
            to: logs.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }

    func append(_ name: String, text: String) throws {
        let handle = try FileHandle(forWritingTo: logs.appendingPathComponent(name))
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(text.utf8))
    }

    func remove() { try? FileManager.default.removeItem(at: root) }
}
