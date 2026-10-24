import Foundation

enum ParsedEvent {
    case message(id: String?, text: String, timestamp: Date?, model: String?, pending: Bool)
    case model(String, String?)
    case metadata
    case ignored
    case unsupported
}

/// Converts supported JSONL representations to canonical user-message events.
struct LogAdapter {
    static let version = 4
    private let decoder = JSONDecoder()

    func decode(_ data: Data, context: inout ParserContext) throws -> ParsedEvent {
        let row = try decoder.decode(LogRecord.self, from: data)
        if row.type == "session_meta", let payload = row.payload {
            context.provider = "codex"
            context.threadID = payload.id ?? context.threadID
            context.project = payload.cwd
            context.title = payload.title ?? context.title
            context.automated = payload.source?.automated ?? false
            return .metadata
        }
        if context.automated == true || row.isSidechain == true { return .ignored }
        if row.type == "turn_context" {
            context.provider = "codex"
            if let model = row.payload?.model { return .model(model, row.payload?.effort) }
            return .metadata
        }
        if row.type == "response_item" {
            context.provider = "codex"
            guard row.payload?.role == "user" else { return .ignored }
            return userEvent(
                id: row.payload?.id, content: row.payload?.content, time: row.timestamp, model: nil, pending: true)
        }
        if row.type == "realtime_item" {
            context.provider = "codex"
            guard row.payload?.type == "transcript_segment", row.payload?.role == "user", let text = row.payload?.text
            else { return .ignored }
            return .message(
                id: row.payload?.id, text: text, timestamp: row.timestamp?.date, model: context.model, pending: false)
        }
        return remainingEvent(row, context: &context)
    }

    private func remainingEvent(_ row: LogRecord, context: inout ParserContext) -> ParsedEvent {
        if let message = row.message {
            context.provider = "claude"
            context.threadID = row.sessionID ?? context.threadID
            context.project = row.cwd ?? context.project
            if message.role == "assistant", let model = message.model, !model.isEmpty, !model.hasPrefix("<") {
                return .model(model, nil)
            }
            guard row.type == "user", message.role == "user", row.isMeta != true else { return .ignored }
            return userEvent(id: row.uuid, content: message.content, time: row.timestamp, model: nil, pending: true)
        }
        if let role = row.role {
            context.provider = row.provider ?? "generic"
            context.threadID = row.threadID ?? row.sessionID ?? context.threadID
            context.project = row.cwd ?? row.projectPath ?? context.project
            context.title = row.title ?? context.title
            guard role == "user" else { return .ignored }
            return userEvent(
                id: row.id, content: row.content ?? row.text.map(TextContent.init), time: row.timestamp,
                model: row.model, pending: false)
        }
        // Event mirrors, compaction history, metadata, and tool outputs are never author input.
        let knownTypes: Set<String> = [
            "event_msg", "world_state", "compacted", "token_usage_record", "inter_agent_communication_metadata",
            "summary", "system", "progress", "file-history-snapshot", "queue-operation",
        ]
        if row.type == nil, row.role == nil, row.text != nil { return .ignored }
        return row.type.map { knownTypes.contains($0) ? .ignored : .unsupported } ?? .unsupported
    }

    private func userEvent(id: String?, content: TextContent?, time: LogTime?, model: String?, pending: Bool)
        -> ParsedEvent
    {
        let text = (content?.blocks ?? []).filter { !UserTextFilter.isGenerated($0) }.joined(separator: "\n")
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .ignored }
        return .message(id: id, text: text, timestamp: time?.date, model: model, pending: pending)
    }
}

private enum UserTextFilter {
    static func isGenerated(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return [
            "# AGENTS.md instructions", "<user_instructions>", "<environment_context>",
            "<external_codex_apps_open_page>", "<inter_agent", "<realtime_delegation>",
            "<turn_aborted>", "This session is being continued from a previous conversation",
            "## Referenced ChatGPT conversation:", "<recommended_plugins>",
        ].contains { trimmed.hasPrefix($0) }
    }
}

private struct LogRecord: Decodable {
    let type: String?
    let id: String?
    let uuid: String?
    let role: String?
    let provider: String?
    let model: String?
    let title: String?
    let cwd: String?
    let text: String?
    let isMeta: Bool?
    let isSidechain: Bool?
    let timestamp: LogTime?
    let content: TextContent?
    let payload: Body?
    let message: Body?
    let sessionID: String?
    let threadID: String?
    let projectPath: String?

    enum CodingKeys: String, CodingKey {
        case type, id, uuid, role, provider, model, title, cwd, text, isMeta, isSidechain, timestamp, content, payload,
            message
        case sessionID = "sessionId"
        case threadID = "thread_id"
        case projectPath = "project_path"
    }
}

private struct Body: Decodable {
    let type: String?
    let id: String?
    let role: String?
    let model: String?
    let effort: String?
    let cwd: String?
    let title: String?
    let text: String?
    let content: TextContent?
    let source: LogSource?
}

private struct LogSource: Decodable {
    let automated: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            automated = text == "subagent"
        } else {
            let keyed = try decoder.container(keyedBy: Keys.self)
            automated = keyed.contains(.subagent)
        }
    }

    private enum Keys: String, CodingKey { case subagent }
}

private struct TextContent: Decodable {
    let blocks: [String]
    init(_ text: String) { blocks = [text] }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            blocks = [text]
        } else {
            blocks = try container.decode([TextBlock].self).compactMap { block in
                ["text", "input_text"].contains(block.type ?? "text") ? block.text : nil
            }
        }
    }
}

private struct TextBlock: Decodable {
    let type: String?
    let text: String?
}

private enum LogTime: Decodable {
    case text(String)
    case number(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else {
            self = .text(try container.decode(String.self))
        }
    }

    var date: Date? {
        switch self {
        case .number(let value): return Date(timeIntervalSince1970: value > 10_000_000_000 ? value / 1_000 : value)
        case .text(let value):
            return (try? Date(value, strategy: .iso8601))
                ?? (try? Date(value, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
        }
    }
}
