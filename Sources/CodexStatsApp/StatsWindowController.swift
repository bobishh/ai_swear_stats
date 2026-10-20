import AppKit
import SwiftUI
import CodexStatsCore

@MainActor
final class DashboardState: ObservableObject {
    @Published var snapshot = CodexStatsSnapshot.empty
    @Published var isScanning = false
    @Published var error: String?
    @Published var roots: [String] = []
    @Published var scannedFiles = 0
    @Published var scannedMessages = 0
}

@MainActor
final class StatsWindowController: NSWindowController {
    let state = DashboardState()

    init(onRefresh: @escaping () -> Void, onOpenConfig: @escaping () -> Void) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Codex Stats"
        window.minSize = NSSize(width: 520, height: 480)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.contentView = NSHostingView(rootView: DashboardView(
            state: state, onRefresh: onRefresh, onOpenConfig: onOpenConfig
        ))
        window.center()
    }

    required init?(coder: NSCoder) { nil }

    func update(snapshot: CodexStatsSnapshot, isScanning: Bool, error: String?, roots: [String]) {
        state.snapshot = snapshot
        state.isScanning = isScanning
        state.error = error
        state.roots = roots
    }
}

private struct DashboardView: View {
    @ObservedObject var state: DashboardState
    let onRefresh: () -> Void
    let onOpenConfig: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Матюкометр").font(.largeTitle.bold())
                    Text("Мат в твоих сообщениях Codex").foregroundStyle(.secondary)
                }
                Spacer()
                Button("Обновить", action: onRefresh)
                    .disabled(state.isScanning)
                    .keyboardShortcut("r")
            }

            if state.isScanning {
                HStack(spacing: 12) {
                    ProgressView().controlSize(.small)
                    Text("Обработано файлов: \(state.scannedFiles) · сообщений: \(state.scannedMessages)")
                        .font(.callout)
                }
            } else if state.snapshot.finishedAt != .distantPast {
                Text("Обновлено: \(state.snapshot.finishedAt.formatted(date: .omitted, time: .standard))")
                    .font(.callout).foregroundStyle(.secondary)
            }

            if let error = state.error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red).textSelection(.enabled)
            }

            HStack(spacing: 32) {
                metric("Матюков", value: state.snapshot.profanityHits)
                metric("Сообщений", value: state.snapshot.userMessages)
                metric("Файлов", value: state.snapshot.scannedFiles)
            }

            Text("Топ матюков").font(.title2.bold())
            if state.snapshot.topTokens.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: state.isScanning ? "hourglass" : "text.magnifyingglass")
                        .font(.largeTitle).foregroundStyle(.secondary)
                    Text(state.isScanning ? "Топ появится после подсчёта" : "Совпадений пока нет")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(state.snapshot.topTokens.enumerated()), id: \.element.id) { index, entry in
                            HStack {
                                Text("\(index + 1)").foregroundStyle(.secondary).frame(width: 28)
                                Text(entry.token).font(.title3.weight(.medium))
                                Spacer()
                                Text(entry.count.formatted()).font(.title3.monospacedDigit())
                            }
                            .padding(12)
                            .background(index.isMultiple(of: 2) ? Color.primary.opacity(0.04) : Color.clear)
                        }
                    }
                }
                .textSelection(.enabled)
            }

            Divider()
            HStack(alignment: .top) {
                Text(state.roots.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                Spacer()
                Button("Настройки…", action: onOpenConfig)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func metric(_ title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(state.snapshot.finishedAt == .distantPast ? "—" : value.formatted())
                .font(.system(size: 30, weight: .semibold, design: .rounded)).monospacedDigit()
            Text(title).font(.callout).foregroundStyle(.secondary)
        }
    }
}
