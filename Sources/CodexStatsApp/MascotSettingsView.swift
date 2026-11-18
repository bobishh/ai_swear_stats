import AppKit
import SwiftUI

struct MascotSettingsView: View {
    @ObservedObject var state: DashboardState
    let actions: DashboardActions
    @State private var showInstructions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 20) {
                if let image = state.mascotLook.image(pose: .squat, index: 0) {
                    Image(nsImage: image).resizable().interpolation(.none)
                        .frame(width: 112, height: 122).accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mascot").font(.title2.bold())
                    Text(state.mascotLook.appearance.name).font(.headline)
                    Toggle(
                        "Show on desktop",
                        isOn: Binding(get: { state.desktopBroEnabled }, set: { actions.desktopMascot($0) })
                    ).toggleStyle(AquaCheckboxStyle())
                    HStack {
                        Button("Use folder…", action: chooseFolder)
                        Button("Built-in") { state.resetMascot() }
                    }
                }
                Spacer(minLength: 0)
            }.aquaPanel()
            Text("Create your own character with an agent, then choose its sprite folder.")
                .font(.callout)
            HStack {
                Button("Copy agent instructions", action: copyInstructions)
                Button("Export starter…", action: exportStarter)
                Button("Reload") { perform { try state.selectMascot(from: state.mascotLook.appearance.root) } }
            }
            DisclosureGroup("Agent instructions", isExpanded: $showInstructions) {
                ScrollView {
                    Text(agentInstructions).font(.system(size: 11, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled).padding(8)
                        .background(AquaScrollChrome())
                }.frame(height: 150).aquaTextWell()
            }
            AquaStatusRow(error: state.mascotAppearanceError)
            HStack {
                Button("Show folder") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: state.mascotLook.appearance.root.path)
                }
                Spacer()
                Button("Done") { state.showMascotSettings = false }.keyboardShortcut(.defaultAction)
                    .buttonStyle(AquaButtonStyle(accented: true))
            }
        }
        .padding(20).frame(width: 590)
        .background(AquaPinstripes())
        .foregroundStyle(AquaTheme.ink).preferredColorScheme(.light)
        .buttonStyle(AquaButtonStyle())
    }

    private var agentInstructions: String {
        let file = MascotAppearance.bundled.root.appendingPathComponent("agent-instructions.txt")
        return (try? String(contentsOf: file, encoding: .utf8)) ?? "Export a starter folder and edit its PNG frames."
    }

    private func copyInstructions() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(agentInstructions, forType: .string)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose mascot folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let folder = panel.url else { return }
        perform { try state.selectMascot(from: folder) }
    }

    private func exportStarter() {
        let panel = NSSavePanel()
        panel.title = "Export mascot starter folder"
        panel.nameFieldStringValue = "My Mascot"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let folder = panel.url else { return }
        perform {
            try FileManager.default.copyItem(at: MascotAppearance.bundled.root, to: folder)
            try state.selectMascot(from: folder)
        }
    }

    private func perform(_ operation: () throws -> Void) {
        do { try operation() } catch { state.mascotAppearanceError = error.localizedDescription }
    }
}
