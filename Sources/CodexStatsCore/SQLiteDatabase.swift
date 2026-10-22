import CSQLite
import Foundation

enum SQLValue {
    case text(String)
    case integer(Int64)
}

struct IndexDatabaseError: LocalizedError {
    let detail: String
    var errorDescription: String? { "Analytics index: " + detail }
}

/// Access is confined to the owning AnalyticsIndex actor.
final class SQLiteDatabase {
    private var handle: OpaquePointer?

    init(url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard
            sqlite3_open_v2(url.path, &handle, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil)
                == SQLITE_OK
        else {
            let error = failure()
            sqlite3_close(handle)
            throw error
        }
        sqlite3_busy_timeout(handle, 5_000)
        try execute("PRAGMA journal_mode=WAL")
        try execute("PRAGMA foreign_keys=ON")
        try execute("CREATE TABLE IF NOT EXISTS sources(path TEXT PRIMARY KEY, cursor TEXT NOT NULL)")
        try execute(
            "CREATE TABLE IF NOT EXISTS messages(source TEXT NOT NULL REFERENCES sources(path) ON DELETE CASCADE, id TEXT NOT NULL, fact TEXT NOT NULL, PRIMARY KEY(source,id))"
        )
        try execute("CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)")
        try execute("CREATE INDEX IF NOT EXISTS messages_by_id ON messages(id)")
    }

    deinit { sqlite3_close(handle) }

    func execute(_ sql: String, _ values: [SQLValue] = []) throws {
        let statement = try prepare(sql, values)
        defer { sqlite3_finalize(statement) }
        var result = sqlite3_step(statement)
        while result == SQLITE_ROW { result = sqlite3_step(statement) }
        guard result == SQLITE_DONE else { throw failure() }
    }

    func rows(_ sql: String, _ values: [SQLValue] = []) throws -> [[String: String]] {
        let statement = try prepare(sql, values)
        defer { sqlite3_finalize(statement) }
        var rows: [[String: String]] = []
        var result = sqlite3_step(statement)
        while result == SQLITE_ROW {
            var row: [String: String] = [:]
            for index in 0..<sqlite3_column_count(statement) {
                if let name = sqlite3_column_name(statement, index), let value = sqlite3_column_text(statement, index) {
                    row[String(cString: name)] = String(cString: value)
                }
            }
            rows.append(row)
            result = sqlite3_step(statement)
        }
        guard result == SQLITE_DONE else { throw failure() }
        return rows
    }

    func transaction<T>(_ operation: () throws -> T) throws -> T {
        try execute("BEGIN IMMEDIATE")
        do {
            let result = try operation()
            try execute("COMMIT")
            return result
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func prepare(_ sql: String, _ values: [SQLValue]) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK, let statement else { throw failure() }
        for (offset, value) in values.enumerated() {
            let position = Int32(offset + 1)
            let result: Int32
            switch value {
            case .integer(let integer): result = sqlite3_bind_int64(statement, position, integer)
            case .text(let text):
                result = text.withCString { pointer in
                    sqlite3_bind_text(
                        statement, position, pointer, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                }
            }
            guard result == SQLITE_OK else {
                sqlite3_finalize(statement)
                throw failure()
            }
        }
        return statement
    }

    private func failure() -> IndexDatabaseError {
        IndexDatabaseError(detail: handle.map { String(cString: sqlite3_errmsg($0)) } ?? "Could not open database")
    }
}
