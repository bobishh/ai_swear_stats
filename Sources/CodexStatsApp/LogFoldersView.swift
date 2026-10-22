import SwiftUI

struct LogFoldersView: View {
    @ObservedObject var state: DashboardState
    let actions: DashboardActions

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Attached log folders").font(.title2.bold())
            Text("Add folders containing Codex, Claude Code, or generic JSONL logs. Subfolders are included.")
                .foregroundStyle(.secondary)
            if state.roots.isEmpty { Text("No folders attached yet.") }
            ForEach(state.roots, id: \.self) { path in
                HStack {
                    Text(path).textSelection(.enabled).lineLimit(2)
                    Spacer()
                    Button("Remove") { actions.removeFolder(path) }
                }
            }
            Divider()
            HStack {
                Button("Add log folder…", action: actions.addFolder)
                Button("Configuration…", action: actions.openConfig)
                Spacer()
                Button("Done") { state.showFolders = false }.keyboardShortcut(.defaultAction)
            }
        }.padding(24).frame(width: 600)
    }
}
