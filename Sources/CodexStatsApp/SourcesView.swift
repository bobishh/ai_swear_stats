import AppKit
import CodexStatsCore
import SwiftUI

struct SourcesView: View {
    let snapshot: AnalyticsSnapshot
    @State var expanded = false
    @State private var onlyIssues = false
    @State private var search = ""

    private var issues: [SourceHealth] { snapshot.sources.filter(\.hasIssues) }
    private var visibleSources: [SourceHealth] {
        snapshot.sources.filter {
            (!onlyIssues || $0.hasIssues) && (search.isEmpty || $0.path.localizedCaseInsensitiveContains(search))
        }.sorted {
            $0.hasIssues == $1.hasIssues ? $0.path < $1.path : $0.hasIssues
        }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(snapshot.folderWarnings) { folder in
                    Label(
                        "Folder: \(folder.path) · \(folder.error ?? "Unavailable")",
                        systemImage: "folder.badge.questionmark"
                    )
                    .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                }
                HStack {
                    Picker("Show", selection: $onlyIssues) {
                        Text("All files (\(snapshot.sources.count))").tag(false)
                        Text("Issues (\(issues.count))").tag(true)
                    }.frame(maxWidth: 240)
                    TextField("Filter files…", text: $search).textFieldStyle(.roundedBorder).frame(maxWidth: 280)
                }
                Text(
                    "\(snapshot.sources.count - issues.count) without issues · \(issues.count) with issues · \(visibleSources.count) shown"
                )
                .font(.caption).foregroundStyle(.secondary)
                if visibleSources.isEmpty {
                    Text("No files match this selection.").foregroundStyle(.secondary).padding(.vertical)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(visibleSources) { source in
                                SourceFileRow(
                                    source: source, messages: snapshot.sourceMessageCounts[source.path, default: 0])
                                Divider()
                            }
                        }
                    }.frame(height: min(300, CGFloat(visibleSources.count) * 85))
                }
            }.padding(.top, 8)
        } label: {
            Text(
                "Sources · \(snapshot.sources.count) \(snapshot.sources.count == 1 ? "file" : "files") · \(issues.count) with issues"
            )
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
