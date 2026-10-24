import Foundation
import Testing
@testable import CodexStatsCore

struct AnalyticsAcceptanceTests {
    @Test(
        "Given a scanned source, when a filesystem event reports an appended profane message, then it is ingested live before reconciliation"
    )
    func changedPathIngestsAppendedMessageImmediately() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write("chat.jsonl", lines: [generic(id: "old", text: "hello")])
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        _ = try await index.refresh(roots: [fixture.logs])
        let source = fixture.logs.appendingPathComponent("chat.jsonl")
        try fixture.append("chat.jsonl", text: generic(id: "live", text: "fuck") + "\n")
        let live = try await index.ingestChangedPaths([source], roots: [fixture.logs])
        #expect(live.count == 1)
        #expect(live.first?.words.keys.sorted() == ["fuck"])
        #expect(try await index.ingestChangedPaths([source], roots: [fixture.logs]).isEmpty)
        #expect(try await index.snapshot().messages == 2)
    }

    @Test(
        "Given a completed baseline, when a new source gets a changed-file event, then fresh messages are returned and root changes stay quiet"
    )
    func changedPathNewSourceAndRootChange() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write("baseline.jsonl", lines: [generic(id: "old", text: "hello")])
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        _ = try await index.refresh(roots: [fixture.logs])

        try fixture.write("new.jsonl", lines: [generic(id: "new", text: "fuck")])
        let newSource = fixture.logs.appendingPathComponent("new.jsonl")
        let live = try await index.ingestChangedPaths([newSource], roots: [fixture.logs])
        #expect(live.count == 1)
        #expect(live.first?.words.keys.sorted() == ["fuck"])

        try fixture.write("session_index.jsonl", lines: [generic(id: "excluded", text: "fuck")])
        let excludedSource = fixture.logs.appendingPathComponent("session_index.jsonl")
        #expect(try await index.ingestChangedPaths([excludedSource], roots: [fixture.logs]).isEmpty)

        let switchedRootResult = try await index.ingestChangedPaths([newSource], roots: [fixture.root])
        #expect(switchedRootResult.isEmpty)
    }

    @Test(
        "Given realtime user and assistant segments plus generated delegation wrappers, when indexed, then only canonical user speech counts"
    )
    func realtimeDelegationWrappersAreIgnored() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write(
            "realtime.jsonl",
            lines: [
                #"{"type":"realtime_item","timestamp":"2026-10-24T12:00:00Z","payload":{"id":"user-1","type":"transcript_segment","role":"user","text":"fuck"}}"#,
                #"{"type":"realtime_item","timestamp":"2026-10-24T12:00:01Z","payload":{"id":"assistant-1","type":"transcript_segment","role":"assistant","text":"shit"}}"#,
                #"{"type":"response_item","payload":{"id":"delegate-1","role":"user","content":[{"type":"input_text","text":"<realtime_delegation>\n<input>fuck</input>\n<transcript_delta>user: fuck\nassistant: shit</transcript_delta>\n</realtime_delegation>"}]}}"#,
                #"{"type":"response_item","payload":{"id":"delegate-2","role":"user","content":[{"type":"input_text","text":" <realtime_delegation>\n<input>fuck</input>\n<transcript_delta>user: fuck\nassistant: shit</transcript_delta>\n</realtime_delegation>\ntail_flush"}]}}"#,
                #"{"type":"response_item","payload":{"id":"quote-1","role":"user","content":[{"type":"input_text","text":"I am quoting <realtime_delegation> as text: fuck"}]}}"#,
            ])
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        let result = try await index.refresh(roots: [fixture.logs])
        #expect(result.snapshot.messages == 2)
        #expect(result.snapshot.profanityHits == 2)
        #expect(result.liveMessages.isEmpty)
    }

    @Test(
        "Given stored legacy delegation tokens, when upgrading the parser, then only candidate sources reread and archive stays quiet"
    )
    func parserUpgradeRebuildsOnlyDelegationSources() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write(
            "realtime.jsonl",
            lines: [
                #"{"type":"realtime_item","timestamp":"2026-10-24T12:00:00Z","payload":{"id":"user-1","type":"transcript_segment","role":"user","text":"fuck"}}"#,
                #"{"type":"response_item","payload":{"id":"delegate-1","role":"user","content":[{"type":"input_text","text":"<realtime_delegation>\n<input>fuck</input>\n<transcript_delta>assistant: shit</transcript_delta>\n</realtime_delegation>"}]}}"#,
            ])
        try fixture.write("unrelated.jsonl", lines: [generic(id: "safe", text: "shit")])
        let candidateURL = fixture.logs.appendingPathComponent("realtime.jsonl")
            .standardizedFileURL.resolvingSymlinksInPath()
        let candidateSize = try Data(contentsOf: candidateURL).count
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        _ = try await index.refresh(roots: [fixture.logs])

        let database = try SQLiteDatabase(url: fixture.database)
        for row in try database.rows("SELECT path,cursor FROM sources") {
            guard let path = row["path"], let cursorJSON = row["cursor"] else {
                Issue.record("Missing source cursor")
                continue
            }
            var cursor = try JSONDecoder().decode(SourceCursor.self, from: Data(cursorJSON.utf8))
            cursor.parserVersion = 3
            let encoded = try JSONEncoder().encode(cursor)
            guard let encodedJSON = String(data: encoded, encoding: .utf8) else {
                Issue.record("Could not encode source cursor")
                continue
            }
            try database.execute("UPDATE sources SET cursor=? WHERE path=?", [.text(encodedJSON), .text(path)])
        }
        let staleFact = try JSONSerialization.data(withJSONObject: [
            "id": "legacy-wrapper", "threadID": "codex:legacy", "title": "legacy", "provider": "codex",
            "model": NSNull(), "effort": NSNull(), "timestamp": NSNull(), "project": NSNull(),
            "words": ["fuck": 1, "realtime": 1, "delegation": 1, "shit": 2],
        ])
        guard let staleJSON = String(data: staleFact, encoding: .utf8) else {
            Issue.record("Could not encode stale synthetic fact")
            return
        }
        try database.execute(
            "INSERT OR REPLACE INTO messages(source,id,fact) VALUES(?,?,?)",
            [.text(candidateURL.path), .text("codex:legacy:wrapper"), .text(staleJSON)])

        let upgraded = try await index.refresh(roots: [fixture.logs])
        #expect(upgraded.bytesRead == candidateSize)
        #expect(upgraded.liveMessages.isEmpty)
        #expect(upgraded.snapshot.messages == 2)
        #expect(upgraded.snapshot.profanityHits == 2)
    }

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
        let replayed = try await index.refresh(roots: [fixture.logs])
        #expect(replayed.snapshot.messages == 2)
        #expect(replayed.liveMessages.isEmpty)
        try fixture.write("chat.jsonl", lines: [generic(id: "3", text: "hello")])
        let rebuilt = try await index.refresh(roots: [fixture.logs])
        #expect(rebuilt.snapshot.messages == 1)
        #expect(rebuilt.snapshot.profanityHits == 0)
        #expect(rebuilt.liveMessages.isEmpty)
    }

    @Test("Given a stable attached root, when a new file gets a fresh profane message, then it is live once")
    func newSourceFileContainsLiveMessage() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write("baseline.jsonl", lines: [generic(id: "baseline", text: "hello")])
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        let baseline = Date().addingTimeInterval(-5)
        #expect(try await index.refresh(roots: [fixture.logs], now: baseline).liveMessages.isEmpty)

        try fixture.write("new-thread.jsonl", lines: [generic(id: "new", text: "fuck")])
        let result = try await index.refresh(roots: [fixture.logs], now: Date())

        #expect(result.liveMessages.count == 1)
        #expect(result.liveMessages.first?.words == ["fuck": 1])
    }

    @Test("Given a new attached folder with recent history, when imported, then it stays quiet")
    func attachedFolderImportStaysQuiet() async throws {
        let fixture = try LogFixture()
        defer { fixture.remove() }
        try fixture.write("baseline.jsonl", lines: [generic(id: "baseline", text: "hello")])
        let index = try AnalyticsIndex(databaseURL: fixture.database)
        let baseline = Date().addingTimeInterval(-5)
        #expect(try await index.refresh(roots: [fixture.logs], now: baseline).liveMessages.isEmpty)

        let attached = fixture.root.appendingPathComponent("attached", isDirectory: true)
        try FileManager.default.createDirectory(at: attached, withIntermediateDirectories: true)
        try fixture.append("baseline.jsonl", text: generic(id: "new-in-baseline", text: "fuck") + "\n")
        try generic(id: "archive", text: "fuck")
            .appending("\n")
            .write(to: attached.appendingPathComponent("archive.jsonl"), atomically: true, encoding: .utf8)
        let result = try await index.refresh(roots: [fixture.logs, attached], now: Date())

        #expect(result.snapshot.profanityHits == 2)
        #expect(result.liveMessages.isEmpty)
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
        try fixture.write(
            "chat.jsonl", lines: [generic(id: "1", text: "toaster долбоёб Scheiße хули хуяли хулиган хула")])
        let first = try AnalyticsIndex(databaseURL: fixture.database)
        #expect(try await first.refresh(roots: [fixture.logs]).snapshot.profanityHits == 4)
        let classifier = try WordClassifier(extraWords: ["toaster": "fuck"])
        let changed = try AnalyticsIndex(databaseURL: fixture.database, classifier: classifier)
        let result = try await changed.refresh(roots: [fixture.logs])
        #expect(result.bytesRead == 0)
        #expect(result.liveMessages.isEmpty)
        #expect(result.snapshot.profanityHits == 5)
        #expect(result.snapshot.topStems.contains { $0.stem == "долбоеб" && $0.language == "ru" && $0.count == 1 })
        #expect(result.snapshot.topStems.contains { $0.stem == "scheiss" && $0.language == "de" && $0.count == 1 })
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
