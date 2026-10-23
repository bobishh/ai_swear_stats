import Charts
import CodexStatsCore
import SwiftUI

struct DashboardView: View {
    @ObservedObject var state: DashboardState
    let actions: DashboardActions
    @State private var dragRange: ClosedRange<Date>?
    @State private var period = 0
    @AppStorage("rankingFamilies") private var rankStems = false
    @State private var rankingSearch = ""
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
                    SourcesView(snapshot: state.snapshot)
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
            HStack(alignment: .center, spacing: 12) {
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
                }.frame(maxWidth: 300)
                Picker(
                    "Period",
                    selection: Binding(get: { period }, set: { value in applyPeriod(value) })
                ) {
                    Text("All time").tag(0)
                    Text("24 hours").tag(1)
                    Text("7 days").tag(7)
                    Text("30 days").tag(30)
                    if period == -1 { Text("Custom range").tag(-1) }
                }.frame(width: 190)
            }
            DateRangePickerRow(from: dateBinding(isStart: true), to: dateBinding(isStart: false))
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
            Text("Profanities per second · \(timelineBucketDescription) buckets · \(selectedRangeLabel)")
                .font(.caption).foregroundStyle(.secondary)
            if state.snapshot.timeline.isEmpty {
                Text(
                    state.isScanning
                        ? "Time series will appear as logs are indexed." : "No timestamped messages in this selection."
                )
                .foregroundStyle(.secondary).frame(maxWidth: .infinity).frame(height: 150)
            } else {
                Chart(state.snapshot.timeline) { point in
                    BarMark(
                        xStart: .value("Start", point.time), xEnd: .value("End", point.end),
                        y: .value("Profanities/s", point.perSecond)
                    ).foregroundStyle(Color.orange)
                }
                .frame(height: 170)
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        let plotFrame = geometry[proxy.plotAreaFrame]
                        ZStack(alignment: .topLeading) {
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 4)
                                        .onChanged { value in
                                            dragRange = dateRange(value, proxy: proxy, geometry: geometry)
                                        }
                                        .onEnded { value in
                                            defer { dragRange = nil }
                                            guard let range = dateRange(value, proxy: proxy, geometry: geometry),
                                                range.upperBound.timeIntervalSince(range.lowerBound) >= 60
                                            else { return }
                                            period = -1
                                            actions.filter(DateRangeSelection.applying(range, to: state.filter))
                                        })
                            if let dragRange,
                                let start = proxy.position(forX: dragRange.lowerBound),
                                let end = proxy.position(forX: dragRange.upperBound)
                            {
                                Rectangle()
                                    .fill(Color.accentColor.opacity(0.18))
                                    .frame(width: abs(end - start), height: plotFrame.height)
                                    .offset(x: plotFrame.minX + min(start, end), y: plotFrame.minY)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
            }
            if state.snapshot.missingTimestamps > 0 {
                Text("\(state.snapshot.missingTimestamps) messages have no timestamp and are excluded from the chart.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var timelineBucketDescription: String {
        let seconds = state.snapshot.timeline.first?.duration ?? 60
        if seconds == 60 { return "one-minute" }
        if seconds == 3_600 { return "one-hour" }
        let days = Int(seconds / 86_400)
        return days == 1 ? "one-day" : "\(days)-day"
    }

    private var periodSelection: Int {
        period
    }

    private var selectedRangeLabel: String {
        if let dragRange {
            return
                "\(dragRange.lowerBound.formatted(date: .abbreviated, time: .shortened)) – \(dragRange.upperBound.formatted(date: .abbreviated, time: .shortened))"
        }
        if let since = state.filter.since, let until = state.filter.until {
            return
                "\(since.formatted(date: .abbreviated, time: .shortened)) – \(until.formatted(date: .abbreviated, time: .shortened))"
        }
        switch periodSelection {
        case 1: return "last 24 hours"
        case 7: return "last 7 days"
        case 30: return "last 30 days"
        default: return "full selected history"
        }
    }

    private func applyPeriod(_ value: Int) {
        guard [0, 1, 7, 30].contains(value) else { return }
        period = value
        actions.filter(DateRangeSelection.applyingPreset(value, now: Date(), to: state.filter))
    }

    private func dateBinding(isStart: Bool) -> Binding<Date> {
        Binding(
            get: {
                if let dragRange { return isStart ? dragRange.lowerBound : dragRange.upperBound }
                let selected = isStart ? state.filter.since : state.filter.until
                return selected ?? (isStart ? state.snapshot.timeline.first?.time : state.snapshot.timeline.last?.end)
                    ?? Date()
            },
            set: { value in
                let filter = state.filter
                let from = filter.since ?? state.snapshot.timeline.first?.time ?? value
                let to = filter.until ?? state.snapshot.timeline.last?.end ?? value
                let range = DateRangeSelection.updating(
                    start: isStart, to: value, currentStart: from, currentEnd: to)
                period = -1
                actions.filter(DateRangeSelection.applying(range, to: filter))
            })
    }

    private func dateRange(_ value: DragGesture.Value, proxy: ChartProxy, geometry: GeometryProxy) -> ClosedRange<Date>?
    {
        let frame = geometry[proxy.plotAreaFrame]
        guard frame.width > 0 else { return nil }
        func date(at x: CGFloat) -> Date? {
            let clamped = min(max(x - frame.minX, 0), frame.width)
            return proxy.value(atX: clamped)
        }
        guard let first = date(at: value.startLocation.x), let last = date(at: value.location.x) else { return nil }
        return DateRangeSelection.ordered(first, last)
    }

    private var rankings: some View {
        let source = rankStems ? state.snapshot.topStems : state.snapshot.topWords
        let results = RankingSearchResults(words: source, query: rankingSearch)
        return VStack(alignment: .leading, spacing: 10) {
            RankingsHeader(
                stems: $rankStems, search: $rankingSearch, resultStatus: results.status,
                categories: state.snapshot.categories)
            if let emptyMessage = results.emptyMessage {
                Text(emptyMessage).foregroundStyle(.secondary).padding(.vertical)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(results.words) { word in
                        HStack {
                            Text(rankStems ? word.family : word.id).font(.body.weight(.medium))
                                .frame(width: 120, alignment: .leading)
                            Text(word.language ?? "Language undetermined").foregroundStyle(.secondary)
                            Spacer()
                            Text(word.category.rawValue).font(.caption).foregroundStyle(.secondary)
                            Text(word.count.formatted()).monospacedDigit().frame(width: 70, alignment: .trailing)
                        }
                        Divider()
                    }
                }
            }
        }.textSelection(.enabled)
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).font(.system(size: 28, weight: .semibold, design: .rounded)).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DateRangePickerRow: View {
    let from: Binding<Date>
    let to: Binding<Date>

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            DatePicker("From", selection: from, displayedComponents: [.date, .hourAndMinute])
            DatePicker("To", selection: to, displayedComponents: [.date, .hourAndMinute])
        }
    }
}
