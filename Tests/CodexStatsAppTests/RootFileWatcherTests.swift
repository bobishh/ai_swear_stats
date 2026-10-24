import CodexStatsCore
import Foundation
import Testing
@testable import CodexStatsApp

struct RootFileWatcherTests {
    @Test(
        "Given a completed scan and recursive watcher, when a log appends profanity, then targeted ingestion returns it without waiting for reconciliation"
    )
    @MainActor
    func recursiveChangeReachesIndex() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let source = directory.appendingPathComponent("chat.jsonl")
        try (#"{"id":"old","role":"user","content":"hello","timestamp":"2026-10-24T12:00:00Z"}"# + "\n").write(
            to: source, atomically: true, encoding: .utf8)
        let index = try AnalyticsIndex(databaseURL: directory.appendingPathComponent("index.sqlite"))
        _ = try await index.refresh(roots: [directory])
        let watcher = RootFileWatcher()
        defer { watcher.stop() }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        watcher.watch([directory])
        try await Task.sleep(for: .milliseconds(300))
        let writeStarted = Date()

        try await confirmation("rapid changed messages all reach the index", expectedCount: 4) { confirm in
            let observer = NotificationCenter.default.addObserver(
                forName: RootFileWatcher.eventName, object: nil, queue: .main
            ) { notification in
                guard let change = notification.object as? RootFileChange,
                    change.paths.contains(where: { $0.lastPathComponent == source.lastPathComponent })
                else { return }
                Task { @MainActor in
                    do {
                        let live = try await index.ingestChangedPaths(Set(change.paths), roots: [directory])
                        for message in live where message.words["fuck"] != nil {
                            print("SYNTHETIC_FILE_EVENT_INGEST_SECONDS=\(Date().timeIntervalSince(writeStarted))")
                            confirm()
                        }
                    } catch { Issue.record(error) }
                }
            }
            for number in 0..<4 {
                let message =
                    "{\"id\":\"live-\(number)\",\"role\":\"user\",\"content\":\"fuck\",\"timestamp\":\"\(timestamp)\"}\n"
                try message.appendToFile(source)
                try await Task.sleep(for: .milliseconds(60))
            }
            try await Task.sleep(for: .seconds(3))
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

private extension String {
    func appendToFile(_ url: URL) throws {
        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(utf8))
        try handle.close()
    }
}
