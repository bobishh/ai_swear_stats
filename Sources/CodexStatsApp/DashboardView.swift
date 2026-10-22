import Charts
import CodexStatsCore
import SwiftUI

struct DashboardView: View {
    @ObservedObject var state: DashboardState
    let actions: DashboardActions
    @State private var period = 0
    @State private var rankFamilies = true
    @AppStorage("threadSortOrder") private var threadSort = ThreadSortOrder.temperature

    var body: some View {
        HSplitView {
            sidebar.frame(minWidth: 210, idealWidth: 245, maxWidth: 320)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    status
                    metrics
                    intensity
                    rankings
                    sourceStatus
                }.padding(24)
            }.frame(minWidth: 640)
        }
        .sheet(isPresented: $state.showFolders) { LogFoldersView(state: state, actions: actions) }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Swear Stats", systemImage: "waveform.path").font(.title2.bold()).padding(.top, 12)
            Text("Local AI conversation analytics").font(.caption).foregroundStyle(.secondary)
            Button("All threads") {
                var filter = state.filter
                filter.thread = nil
                actions.filter(filter)
            }.buttonStyle(.bordered)
            Text("THREADS · \(state.threads.count)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Picker("Sort", selection: $threadSort) {
                ForEach(ThreadSortOrder.allCases) { order in
                    Text(order.title).tag(order)
                }
            }
            ThreadHeatLegend()
            List {
                ForEach(threadSort.ordered(state.threads)) { thread in
                    Button {
                        var filter = state.filter
                        filter.thread = thread.id
                        actions.filter(filter)
                    } label: {
                        ThreadRowView(thread: thread, selected: state.filter.thread == thread.id)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                    .listRowBackground(Color.clear)
                }
            }.listStyle(.sidebar).id(threadSort)
            Button("Log folders…", systemImage: "folder.badge.plus") { state.showFolders = true }
            Toggle(
                "Burst reminders",
                isOn: Binding(get: { state.notificationsEnabled }, set: { actions.notifications($0) })
            )
            .toggleStyle(.switch).controlSize(.small)
            .disabled(state.notificationRequestPending)
            Text(state.notificationStatus).font(.caption).foregroundStyle(.secondary)
            if state.notificationNeedsSettings {
                Button("Notification Settings…") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }.padding(14)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Watch your language.").font(.largeTitle.bold())
                    Text("Across your AI conversations. Everything stays on this Mac.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Refresh", systemImage: "arrow.clockwise", action: actions.refresh)
                    .disabled(state.isScanning).keyboardShortcut("r")
            }
            HStack {
                Picker(
                    "Model",
                    selection: Binding(
                        get: { state.filter.model ?? "" },
                        set: { model in
                            var filter = state.filter
                            filter.model = model.isEmpty ? nil : model
                            filter.thread = nil
                            actions.filter(filter)
                        })
                ) {
                    Text("All models").tag("")
                    ForEach(state.models) { Text($0.id).tag($0.id) }
                }.frame(maxWidth: 360)
                Picker("Period", selection: $period) {
                    Text("All time").tag(0)
                    Text("24 hours").tag(1)
                    Text("7 days").tag(7)
                    Text("30 days").tag(30)
                }.frame(width: 190)
                    .onChange(of: period) { value in
                        var filter = state.filter
                        filter.since = value == 0 ? nil : Date().addingTimeInterval(-Double(value) * 86_400)
                        actions.filter(filter)
                    }
            }
        }
    }

    @ViewBuilder private var status: some View {
        if state.isScanning {
            HStack(spacing: 10) {
                ProgressView().controlSize(.small)
                Text(
                    state.totalFiles == 0
                        ? "Checking log changes…"
                        : "Indexing \(state.files)/\(state.totalFiles) files · \(ByteCountFormatter.string(fromByteCount: Int64(state.bytesRead), countStyle: .file)) read"
                )
            }.font(.callout)
        } else {
            Text(
                "Last refresh read \(ByteCountFormatter.string(fromByteCount: Int64(state.bytesRead), countStyle: .file)) from logs. Unchanged files are skipped."
            )
            .font(.caption).foregroundStyle(.secondary)
        }
        if let error = state.error {
            Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red).textSelection(.enabled)
        }
    }

    private var metrics: some View {
        HStack(alignment: .top, spacing: 24) {
            metric("Profanities", value: state.snapshot.profanityHits.formatted())
            metric("Messages", value: state.snapshot.messages.formatted())
            metric(
                "Per 1,000 words",
                value: state.snapshot.hitsPerThousandWords.formatted(.number.precision(.fractionLength(1))))
            metric(
                "Profane messages",
                value: state.snapshot.profaneMessageShare.formatted(.percent.precision(.fractionLength(1))))
        }
    }

    private var intensity: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lexical intensity").font(.headline)
            Text("Profanities per second · one-minute buckets · most recent 24h of selected data")
                .font(.caption).foregroundStyle(.secondary)
            if state.snapshot.timeline.isEmpty {
                Text(
                    state.isScanning
                        ? "Time series will appear as logs are indexed." : "No timestamped messages in this selection."
                )
                .foregroundStyle(.secondary).frame(maxWidth: .infinity).frame(height: 150)
            } else {
                Chart(state.snapshot.timeline) { point in
                    BarMark(x: .value("Time", point.time, unit: .minute), y: .value("Profanities/s", point.perSecond))
                        .foregroundStyle(Color.orange)
                }.frame(height: 170).chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) }
            }
            if state.snapshot.missingTimestamps > 0 {
                Text("\(state.snapshot.missingTimestamps) messages have no timestamp and are excluded from the chart.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var rankings: some View {
        VStack(alignment: .leading, spacing: 10) {
            RankingsHeader(families: $rankFamilies, categories: state.snapshot.categories)
            if state.snapshot.topWords.isEmpty {
                Text("No classified words in this selection.").foregroundStyle(.secondary).padding(.vertical)
            }
            ForEach(Array((rankFamilies ? state.snapshot.topFamilies : state.snapshot.topWords).prefix(15))) { word in
                HStack {
                    Text(word.id).font(.body.weight(.medium)).frame(width: 120, alignment: .leading)
                    Text(word.family).foregroundStyle(.secondary)
                    Spacer()
                    Text(word.category.rawValue).font(.caption).foregroundStyle(.secondary)
                    Text(word.count.formatted()).monospacedDigit().frame(width: 70, alignment: .trailing)
                }
                Divider()
            }
        }.textSelection(.enabled)
    }

    private var sourceStatus: some View {
        DisclosureGroup(
            "Sources · \(state.snapshot.sources.count) \(state.snapshot.sources.count == 1 ? "file" : "files") in selection"
        ) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(
                    state.snapshot.sources.filter {
                        $0.error != nil || $0.malformedLines > 0 || $0.unsupportedLines > 0
                    }
                ) { source in
                    Text(
                        "\(source.path): \(source.error ?? "\(source.malformedLines) malformed, \(source.unsupportedLines) unsupported records")"
                    )
                    .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                }
                Text("Supported: Codex, Claude Code, generic JSONL. Missing models are labeled Unknown.")
                    .font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).font(.system(size: 28, weight: .semibold, design: .rounded)).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
