import Foundation

/// Serializes durable source ingestion independently of the main actor.
public actor AnalyticsIndex {
    private let excludedSourceNames: Set<String> = ["session_index.jsonl", "transcription-history.jsonl"]
    private let database: SQLiteDatabase
    private let classifier: WordClassifier
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var activeRoots: [URL]?
    private var lastRefreshRootPaths: Set<String>?
    private var lastRefreshAt: Date?
    private var discovered: Set<String>?
    private var folderWarnings: [SourceHealth] = []
    private var cachedFacts: [(source: String, fact: MessageFact)]?
    private var cachedRealtimeDelegationSources: Set<String>?
    private var hasRefreshed = false
    private var snapshots: [SnapshotKey: AnalyticsSnapshot] = [:]
    private var lastIndexedAt: Date?

    public init(databaseURL: URL, classifier: WordClassifier? = nil) throws {
        database = try SQLiteDatabase(url: databaseURL)
        self.classifier = try classifier ?? WordClassifier()
    }

    public func snapshot(filter: AnalyticsFilter = AnalyticsFilter(), roots: [URL]? = nil) throws -> AnalyticsSnapshot {
        let roots = roots ?? activeRoots
        let key = SnapshotKey(filter: filter, roots: roots?.map(\.path).sorted())
        if var cached = snapshots[key] {
            cached.indexedAt = lastIndexedAt ?? cached.indexedAt
            return cached
        }
        let sources = try sourceCursors().filter { belongs($0.key, to: roots) }
        let paths = Set(sources.keys)
        if cachedFacts == nil {
            cachedFacts = try database.rows("SELECT source,fact FROM messages").compactMap { row in
                guard let source = row["source"], let json = row["fact"] else { return nil }
                return (source, try decoder.decode(MessageFact.self, from: Data(json.utf8)))
            }
        }
        let selected = (cachedFacts ?? []).filter { paths.contains($0.source) && filter.matches($0.fact) }
        let facts = selected.map(\.fact)
        let selectedPaths = filter == AnalyticsFilter() ? paths : Set(selected.map(\.source))
        let health =
            sources.filter { selectedPaths.contains($0.key) }.map { path, cursor in
                var health = cursor.health
                if let discovered, !discovered.contains(path), health.error == nil {
                    health.error = "Source unavailable; showing cached data"
                }
                return health
            }.sorted { $0.path < $1.path }
        let indexedAt = try database.rows("SELECT value FROM settings WHERE key='indexed_at'").first?["value"].flatMap(
            Double.init
        ).map(Date.init(timeIntervalSince1970:))
        var result = AnalyticsAggregator(classifier: classifier).build(
            facts, filter: filter, sources: health, indexedAt: indexedAt)
        for record in selected { result.sourceMessageCounts[record.source, default: 0] += 1 }
        result.folderWarnings = filter == AnalyticsFilter() ? folderWarnings : []
        if snapshots.count >= 16 { snapshots.removeAll() }
        snapshots[key] = result
        return result
    }

    public func refresh(roots: [URL], now: Date = Date(), progress: (@Sendable (IndexProgress) -> Void)? = nil) throws
        -> IndexUpdate
    {
        let resolvedRoots = roots.map { $0.standardizedFileURL.resolvingSymlinksInPath() }
        let rootPaths = Set(resolvedRoots.map(\.path))
        let rootsUnchanged = lastRefreshRootPaths == rootPaths
        activeRoots = resolvedRoots
        let previousWarnings = folderWarnings.map { $0.path + ($0.error ?? "") }
        let files = discover(roots)
        let paths = Set(files.map(\.path))
        if discovered != paths || previousWarnings != folderWarnings.map({ $0.path + ($0.error ?? "") }) {
            snapshots.removeAll()
        }
        discovered = paths
        let cursors = try sourceCursors()
        // Parser v3 already tokenized every wrapper marker, so v3→v4 can identify the affected
        // sources from stored facts. Other parser transitions may have different semantics and
        // must use the normal rebuild path.
        var parserUpgradeCandidates = Set<String>()
        if LogAdapter.version == 4, cursors.values.contains(where: { $0.parserVersion == 3 }) {
            if cachedRealtimeDelegationSources == nil {
                cachedRealtimeDelegationSources = try realtimeDelegationSources()
            }
            parserUpgradeCandidates = cachedRealtimeDelegationSources ?? []
        }
        var bytesRead = 0
        var live: [MessageFact] = []
        var changedSinceProgress = false
        for (number, url) in files.enumerated() {
            try Task.checkCancellation()
            do {
                var previous = cursors[url.path]
                if LogAdapter.version == 4, var cursor = previous, cursor.parserVersion == 3,
                    !parserUpgradeCandidates.contains(url.path)
                {
                    cursor.parserVersion = LogAdapter.version
                    try save(cursor, path: url.path)
                    previous = cursor
                }
                let result = try ingest(
                    url: url, previous: previous, now: now,
                    allowLive: hasRefreshed && rootsUnchanged, previousRefreshAt: lastRefreshAt)
                bytesRead += result.bytesRead
                changedSinceProgress = changedSinceProgress || result.bytesRead > 0
                live.append(contentsOf: result.live)
            } catch is CancellationError { throw CancellationError() } catch {
                var cursor = cursors[url.path] ?? freshCursor(url: url)
                cursor.health.error = error.localizedDescription
                try save(cursor, path: url.path)
            }
            let publishPartial = changedSinceProgress && (number + 1).isMultiple(of: 100)
            let partial = publishPartial ? try snapshot() : nil
            if publishPartial { changedSinceProgress = false }
            progress?(IndexProgress(files: number + 1, total: files.count, bytesRead: bytesRead, snapshot: partial))
        }
        try database.execute(
            "INSERT OR REPLACE INTO settings(key,value) VALUES('indexed_at',?)",
            [.text(String(now.timeIntervalSince1970))])
        lastIndexedAt = now
        let result = try IndexUpdate(snapshot: snapshot(), bytesRead: bytesRead, liveMessages: live)
        lastRefreshRootPaths = rootPaths
        lastRefreshAt = now
        hasRefreshed = true
        return result
    }

    public func ingestChangedPaths(
        _ urls: Set<URL>, roots: [URL], now: Date = Date(), allowLive: Bool = true
    ) throws -> [MessageFact] {
        let resolvedRoots = roots.map { $0.standardizedFileURL.resolvingSymlinksInPath() }
        let rootPaths = Set(resolvedRoots.map(\.path))
        guard hasRefreshed, lastRefreshRootPaths == rootPaths else { return [] }
        activeRoots = resolvedRoots
        var live: [MessageFact] = []
        for url in urls.map({ $0.standardizedFileURL.resolvingSymlinksInPath() }).sorted(by: { $0.path < $1.path }) {
            guard isIndexableSource(url), belongs(url.path, to: resolvedRoots) else { continue }
            do {
                let previous = try sourceCursor(path: url.path)
                let result = try ingest(
                    url: url, previous: previous, now: now, allowLive: allowLive,
                    previousRefreshAt: lastRefreshAt)
                live.append(contentsOf: result.live)
            } catch is CancellationError { throw CancellationError() } catch {
                var cursor = (try? sourceCursor(path: url.path)) ?? freshCursor(url: url)
                cursor.health.error = error.localizedDescription
                try save(cursor, path: url.path)
            }
        }
        try database.execute(
            "INSERT OR REPLACE INTO settings(key,value) VALUES('indexed_at',?)",
            [.text(String(now.timeIntervalSince1970))])
        lastIndexedAt = now
        return live
    }

    public func loadBurstState() throws -> BurstPolicy {
        if let json = try database.rows("SELECT value FROM settings WHERE key='burst'").first?["value"] {
            return try decoder.decode(BurstPolicy.self, from: Data(json.utf8))
        }
        return BurstPolicy()
    }

    public func saveBurstState(_ state: BurstPolicy) throws {
        try database.execute("INSERT OR REPLACE INTO settings(key,value) VALUES('burst',?)", [.text(try json(state))])
    }

    public func evaluateBurstMessages(_ messages: [MessageFact], now: Date = Date()) throws -> String? {
        var policy = try loadBurstState()
        let reminder = try policy.evaluate(messages, classifier: classifier, now: now)
        try saveBurstState(policy)
        return reminder
    }

    private func ingest(
        url: URL, previous: SourceCursor?, now: Date, allowLive: Bool, previousRefreshAt: Date?
    ) throws -> (
        bytesRead: Int, live: [MessageFact]
    ) {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
        let modified = (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
        let createdAfterRefresh =
            (attributes[.creationDate] as? Date).map { createdAt in
                previousRefreshAt.map { createdAt >= $0 } ?? false
            } ?? false
        let newSource = allowLive && previous == nil && createdAfterRefresh
        let identity = "\(attributes[.systemNumber] ?? 0):\(attributes[.systemFileNumber] ?? 0)"
        if let previous, previous.parserVersion == LogAdapter.version, previous.identity == identity,
            previous.size == size, previous.modified == modified,
            previous.health.error == nil
        {
            return (0, [])
        }
        let appending =
            previous.map { $0.parserVersion == LogAdapter.version && $0.identity == identity && size > $0.size }
            ?? false
        var cursor = appending ? (previous ?? freshCursor(url: url)) : freshCursor(url: url)
        cursor.identity = identity
        cursor.size = size
        cursor.modified = modified
        cursor.health.error = nil
        cachedFacts = nil
        return try database.transaction {
            if !appending { try database.execute("DELETE FROM sources WHERE path=?", [.text(url.path)]) }
            try save(cursor, path: url.path)
            var live: [MessageFact] = []
            let adapter = LogAdapter()
            let result = try JSONLReader().read(url: url, offset: cursor.offset, size: size) { data, offset in
                let event: ParsedEvent
                do { event = try adapter.decode(data, context: &cursor.context) } catch {
                    cursor.health.malformedLines += 1; return
                }
                switch event {
                case .message(let id, let text, let time, let model, let pending):
                    if cursor.context.title.isEmpty {
                        cursor.context.title = String(text.prefix(80)).replacingOccurrences(of: "\n", with: " ")
                    }
                    let fact = makeFact(
                        id: id, text: text, time: time, model: model, pending: pending, context: cursor.context,
                        url: url, offset: offset)
                    let existing =
                        try database.rows(
                            "SELECT id FROM messages WHERE id=? LIMIT 1", [.text(fact.id)]
                        ).isEmpty == false
                    try store(fact, source: url.path)
                    if pending, !cursor.context.pendingIDs.contains(fact.id) {
                        cursor.context.pendingIDs.append(fact.id)
                    }
                    if allowLive, appending || newSource, previous?.health.error == nil, !existing, let time,
                        time <= now.addingTimeInterval(5),
                        time >= now.addingTimeInterval(-120)
                    {
                        live.append(fact)
                    }
                case .model(let model, let effort):
                    try attributePending(cursor.context.pendingIDs, source: url.path, model: model, effort: effort)
                    cursor.context.pendingIDs = []
                    cursor.context.model = model
                    cursor.context.effort = effort
                case .unsupported: cursor.health.unsupportedLines += 1
                case .metadata, .ignored: break
                }
            }
            cursor.offset = result.offset
            try save(cursor, path: url.path)
            return (result.bytesRead, live)
        }
    }

    private func makeFact(
        id: String?, text: String, time: Date?, model: String?, pending: Bool, context: ParserContext, url: URL,
        offset: UInt64
    ) -> MessageFact {
        let identifier = context.provider + ":" + context.threadID + ":" + (id ?? url.path + ":" + String(offset))
        return MessageFact(
            id: identifier, threadID: context.provider + ":" + context.threadID,
            title: context.title.isEmpty
                ? String(text.prefix(80)).replacingOccurrences(of: "\n", with: " ") : context.title,
            provider: context.provider, model: model ?? (pending ? nil : context.model), effort: context.effort,
            timestamp: time, project: context.project, words: classifier.words(in: text))
    }

    private func attributePending(_ ids: [String], source: String, model: String, effort: String?) throws {
        for id in ids {
            guard
                let json = try database.rows(
                    "SELECT fact FROM messages WHERE source=? AND id=?", [.text(source), .text(id)]
                ).first?["fact"]
            else { continue }
            var fact = try decoder.decode(MessageFact.self, from: Data(json.utf8))
            fact.model = model
            fact.effort = effort
            try store(fact, source: source)
        }
    }

    private func store(_ fact: MessageFact, source: String) throws {
        try database.execute(
            "INSERT OR REPLACE INTO messages(source,id,fact) VALUES(?,?,?)",
            [.text(source), .text(fact.id), .text(try json(fact))])
    }

    private func save(_ cursor: SourceCursor, path: String) throws {
        snapshots.removeAll()
        try database.execute(
            "INSERT INTO sources(path,cursor) VALUES(?,?) ON CONFLICT(path) DO UPDATE SET cursor=excluded.cursor",
            [.text(path), .text(try json(cursor))])
    }

    private func sourceCursors() throws -> [String: SourceCursor] {
        var cursors: [String: SourceCursor] = [:]
        for row in try database.rows("SELECT path,cursor FROM sources") {
            if let path = row["path"], let json = row["cursor"] {
                cursors[path] = try decoder.decode(SourceCursor.self, from: Data(json.utf8))
            }
        }
        return cursors
    }

    private func realtimeDelegationSources() throws -> Set<String> {
        // Parser v3 stored every token in each fact, including both marker tokens from this wrapper.
        // Their absence proves that the source cannot contain a counted delegation wrapper.
        Set(
            try database.rows(
                "SELECT DISTINCT source FROM messages WHERE instr(fact,'\"realtime\"')>0 AND instr(fact,'\"delegation\"')>0"
            ).compactMap { $0["source"] })
    }

    private func sourceCursor(path: String) throws -> SourceCursor? {
        guard let json = try database.rows("SELECT cursor FROM sources WHERE path=?", [.text(path)]).first?["cursor"]
        else { return nil }
        return try decoder.decode(SourceCursor.self, from: Data(json.utf8))
    }

    private func freshCursor(url: URL) -> SourceCursor {
        SourceCursor(
            parserVersion: LogAdapter.version, identity: "", offset: 0, size: 0, modified: 0,
            context: ParserContext(threadID: url.path),
            health: SourceHealth(path: url.path))
    }

    private func discover(_ roots: [URL]) -> [URL] {
        var files: Set<URL> = []
        folderWarnings = []
        for root in roots {
            guard FileManager.default.isReadableFile(atPath: root.path),
                let enumerator = FileManager.default.enumerator(
                    at: root, includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants], errorHandler: { _, _ in false })
            else {
                folderWarnings.append(SourceHealth(path: root.path, error: "Folder unavailable; showing cached data"))
                continue
            }
            for case let url as URL in enumerator where isIndexableSource(url) {
                files.insert(url.standardizedFileURL.resolvingSymlinksInPath())
            }
        }
        return files.sorted { $0.path < $1.path }
    }

    private func isIndexableSource(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "jsonl" && !excludedSourceNames.contains(url.lastPathComponent)
            && (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
    }

    private func belongs(_ path: String, to roots: [URL]?) -> Bool {
        guard let roots else { return true }
        return roots.contains { path == $0.path || path.hasPrefix($0.path + "/") }
    }

    private func json<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try encoder.encode(value), as: UTF8.self)
    }
}

private struct SnapshotKey: Hashable {
    let filter: AnalyticsFilter
    let roots: [String]?
}
