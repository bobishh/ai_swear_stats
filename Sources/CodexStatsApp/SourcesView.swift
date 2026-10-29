import AppKit
import CodexStatsCore
import SwiftUI

struct SourcesView: View {
    let snapshot: AnalyticsSnapshot
    @State var expanded = false

    private var issues: [SourceHealth] { snapshot.sources.filter(\.hasIssues) }

    @ViewBuilder
    var body: some View {
        if !issues.isEmpty || !snapshot.folderWarnings.isEmpty {
            DisclosureGroup(isExpanded: $expanded) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(snapshot.folderWarnings) { folder in
                        Label(
                            "Folder: \(folder.path) · \(folder.error ?? "Unavailable")",
                            systemImage: "folder.badge.questionmark"
                        )
                        .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                    if !issues.isEmpty {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(issues.sorted(by: { $0.path < $1.path })) { source in
                                    SourceFileRow(
                                        source: source,
                                        messages: snapshot.sourceMessageCounts[source.path, default: 0])
                                    Divider()
                                }
                            }
                        }
                        .frame(height: min(300, CGFloat(issues.count) * 85))
                    }
                }
                .padding(.top, 8)
            } label: {
                Label(
                    "Source issues · \(issues.count + snapshot.folderWarnings.count)",
                    systemImage: "exclamationmark.triangle")
            }
        }
    }
}

private struct SourceFileRow: View {
    let source: SourceHealth
    let messages: Int
    private var url: URL { URL(fileURLWithPath: source.path) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(url.lastPathComponent).font(.callout.weight(.medium)).lineLimit(1).truncationMode(.middle)
                Text(url.deletingLastPathComponent().path).font(.caption).foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.middle)
                Text(status).font(.caption).foregroundStyle(source.hasIssues ? Color.orange : Color.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled).help(source.path)
            Text("\(messages) messages").font(.caption).monospacedDigit().fixedSize()
            Button("Finder", systemImage: "folder") { reveal() }.help("Show source location in Finder")
        }
        .contextMenu {
            Button("Copy path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(source.path, forType: .string)
            }
        }
    }

    private var status: String {
        var parts: [String] = []
        if let error = source.error { parts.append(error) }
        if source.malformedLines > 0 { parts.append("\(source.malformedLines) malformed records") }
        if source.unsupportedLines > 0 { parts.append("\(source.unsupportedLines) unsupported records") }
        return parts.isEmpty ? "Indexed" : parts.joined(separator: " · ")
    }

    private func reveal() {
        var location = url
        while !FileManager.default.fileExists(atPath: location.path), location.path != "/" {
            location.deleteLastPathComponent()
        }
        NSWorkspace.shared.activateFileViewerSelecting([location])
    }
}

extension SourceHealth {
    var hasIssues: Bool { error != nil || malformedLines > 0 || unsupportedLines > 0 }
}
