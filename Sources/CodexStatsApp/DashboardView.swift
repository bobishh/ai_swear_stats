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
                VStack(alignment: .leading, spacing: 14) {
                    header
                    AquaStatusRow(error: state.error)
                    metrics
                    intensity.aquaPanel()
                    rankings.aquaPanel()
                    SourcesView(snapshot: state.snapshot)
                }
                .padding(18)
                .background(AquaScrollChrome())
            }.frame(minWidth: 668)
        }
        .background(AquaPinstripes())
        .foregroundStyle(AquaTheme.ink)
        .font(.system(size: 13))
        .tint(AquaTheme.blue)
        .buttonStyle(AquaButtonStyle())
        .toggleStyle(AquaCheckboxStyle())
        .preferredColorScheme(.light)
        .sheet(isPresented: $state.showFolders) { LogFoldersView(state: state, actions: actions) }
        .sheet(isPresented: $state.showMascotSettings) { MascotSettingsView(state: state, actions: actions) }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let logo = state.mascotLook.image(pose: .squat, index: 0) {
                    Image(nsImage: logo).resizable().interpolation(.none).frame(width: 30, height: 30)
                } else {
                    Image(systemName: "waveform.path").frame(width: 30, height: 30)
                }
                Text("Swear Stats").font(.system(size: 18, weight: .bold))
                    .shadow(color: .white, radius: 0, y: 1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Swear Stats")
            .padding(.vertical, 6)
            Button("All threads") {
                var filter = state.filter
                filter.thread = nil
                actions.filter(filter)
            }.buttonStyle(AquaButtonStyle(accented: state.filter.thread == nil))
            HStack {
                Text("Threads · \(state.threads.count)").font(.caption.weight(.semibold))
                Spacer(minLength: 0)
                ThreadHeatLegend()
            }
            AquaPopUp(
                title: "Sort", selection: $threadSort,
                choices: ThreadSortOrder.allCases.map { AquaChoice(value: $0, title: $0.title) })
            threadList
            HStack(spacing: 6) {
                Button("Log folders…") { state.showFolders = true }
                Button("Mascot…") { state.showMascotSettings = true }
            }
            Toggle(
                "Burst reminders",
                isOn: Binding(get: { state.notificationsEnabled }, set: { actions.notifications($0) })
            )
            .disabled(state.notificationRequestPending)
            notificationStatus
        }
        .padding(12)
        .background(AquaPinstripes())
    }

    private var threadList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(threadSort.ordered(state.threads)) { thread in
                    Button {
                        var filter = state.filter
                        filter.thread = thread.id
                        actions.filter(filter)
                    } label: {
                        ThreadRowView(thread: thread, selected: state.filter.thread == thread.id)
                    }.buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(AquaScrollChrome())
        }
        .background(Color.white)
        .overlay(Rectangle().strokeBorder(AquaTheme.edge, lineWidth: 1))
        .id(threadSort)
    }

    private var notificationStatus: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(state.notificationStatus.isEmpty ? " " : state.notificationStatus)
                .font(.caption).foregroundStyle(.secondary)
                .lineLimit(2).frame(height: 30, alignment: .topLeading)
            Button("Notification Settings…") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                    NSWorkspace.shared.open(url)
                }
            }
            .opacity(state.notificationNeedsSettings ? 1 : 0)
            .disabled(!state.notificationNeedsSettings)
            .accessibilityHidden(!state.notificationNeedsSettings)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Overview").font(.system(size: 21, weight: .bold))
                    .shadow(color: .white, radius: 0, y: 1)
                Spacer()
                SyncIndicatorView(state: state)
            }
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 6) {
                    Text("Model").frame(width: 44, alignment: .leading)
                    AquaPopUp(
                        title: "Model",
                        selection: Binding(
                            get: { state.filter.model ?? "" },
                            set: { model in
                                var filter = state.filter
                                filter.model = model.isEmpty ? nil : model
                                filter.thread = nil
                                actions.filter(filter)
                            }),
                        choices: [AquaChoice(value: "", title: "All models")]
                            + state.models.map { AquaChoice(value: $0.id, title: $0.id) })
                }.frame(width: 220, alignment: .leading)
                HStack(spacing: 6) {
                    Text("Period").frame(width: 44, alignment: .leading)
                    AquaPopUp(
                        title: "Period", selection: Binding(get: { period }, set: { value in applyPeriod(value) }),
                        choices: periodChoices)
                }.frame(width: 220, alignment: .leading)
                HStack(spacing: 8) {
                    Toggle("Sound", isOn: Binding(get: { state.soundEnabled }, set: { actions.sound($0) }))
                        .lineLimit(1).fixedSize(horizontal: true, vertical: false)
                    Button("Preview sound", systemImage: "speaker.wave.2", action: actions.previewSound)
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("Preview sound")
                        .help("Preview the Ouch sound")
                        .disabled(!state.soundEnabled)
                }.frame(width: 128, alignment: .leading)
            }
            DateRangePickerRow(from: dateBinding(isStart: true), to: dateBinding(isStart: false))
        }
        .padding(14)
        .background(AquaTheme.silver)
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(AquaTheme.edge, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var periodChoices: [AquaChoice<Int>] {
        var choices = [
            AquaChoice(value: 0, title: "All time"), AquaChoice(value: 1, title: "24 hours"),
            AquaChoice(value: 7, title: "7 days"), AquaChoice(value: 30, title: "30 days"),
        ]
        if period == -1 { choices.append(AquaChoice(value: -1, title: "Custom range")) }
        return choices
    }

    private var metrics: some View {
        HStack(alignment: .top, spacing: 10) {
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
            Text("Lexical intensity").font(.system(size: 14, weight: .bold))
            Text("Profanities per second · \(timelineBucketDescription) buckets")
                .font(.caption).foregroundStyle(.secondary)
            if state.snapshot.timeline.isEmpty {
                VStack(spacing: 0) {
                    Text(state.isScanning ? "Indexing…" : "No timestamped messages")
                        .foregroundStyle(.secondary).frame(maxWidth: .infinity).frame(height: 170)
                    mascotTrack
                }
            } else {
                VStack(spacing: 0) {
                    Chart(state.snapshot.timeline) { point in
                        RectangleMark(
                            xStart: .value("Start", point.time), xEnd: .value("End", point.end),
                            yStart: .value("Baseline", 0), yEnd: .value("Profanities/s", point.perSecond)
                        ).foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1, green: 0.75, blue: 0.38), Color.orange],
                                startPoint: .top, endPoint: .bottom))
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
                    mascotTrack
                }
            }
            if state.snapshot.missingTimestamps > 0 {
                Text("\(state.snapshot.missingTimestamps) messages without timestamps")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var mascotTrack: some View {
        ZStack(alignment: .bottom) {
            Rectangle().fill(Color.secondary.opacity(0.18)).frame(height: 1)
            ChartMascotView(state: state).opacity(state.desktopBroEnabled ? 0 : 1)
        }
        .padding(.leading, 44)
        .padding(.trailing, 12)
        .frame(height: ChartMascotMotion.laneHeight)
        .allowsHitTesting(false)
    }

    private var timelineBucketDescription: String {
        let seconds = state.snapshot.timeline.first?.duration ?? 60
        if seconds == 60 { return "one-minute" }
        if seconds == 3_600 { return "one-hour" }
        let days = Int(seconds / 86_400)
        return days == 1 ? "one-day" : "\(days)-day"
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
                            Text(rankStems ? (word.displayWord ?? word.family) : word.id)
                                .font(.body.weight(.medium))
                                .frame(width: 120, alignment: .leading)
                                .lineLimit(1).truncationMode(.middle)
                                .help(rankStems ? "Snowball stem: \(word.family)" : "")
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
            Text(value).font(.system(size: 26, weight: .medium)).monospacedDigit()
                .foregroundStyle(Color(red: 0.15, green: 0.24, blue: 0.31))
            Text(title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(LinearGradient(colors: [Color(white: 0.94), .white], startPoint: .top, endPoint: .bottom))
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(AquaTheme.edge, lineWidth: 1))
    }
}

struct DateRangePickerRow: View {
    let from: Binding<Date>
    let to: Binding<Date>

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            datePicker("From", selection: from)
            datePicker("To", selection: to)
            Color.clear.frame(width: 128, height: 0).accessibilityHidden(true)
        }
    }

    private func datePicker(_ title: String, selection: Binding<Date>) -> some View {
        HStack(spacing: 6) {
            Text(title).frame(width: 44, alignment: .leading)
            DatePicker(title, selection: selection, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .accessibilityLabel(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .datePickerStyle(.field).controlSize(.small)
        }
        .frame(width: 220, alignment: .leading)
    }
}

struct SyncIndicatorView: View {
    @ObservedObject var state: DashboardState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.5, paused: !state.isSyncing || reduceMotion)) { timeline in
            let lit =
                state.isSyncing && (reduceMotion || Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2 == 0)
            HStack(spacing: 6) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: lit
                                ? [.white, .green, Color(red: 0.05, green: 0.35, blue: 0.06)]
                                : [Color(white: 0.6), Color(white: 0.3)],
                            center: .topLeading, startRadius: 0, endRadius: 8)
                    )
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text("SYNC")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .frame(width: 34, alignment: .leading)
            }
            .frame(width: 52, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(description)
            .help(description)
        }
        .padding(.horizontal, 7).padding(.vertical, 4)
        .background(Color(white: 0.85), in: RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color(white: 0.6), lineWidth: 1))
        .frame(width: 68, height: 26, alignment: .leading)
    }

    private var description: String {
        if let error = state.error { return "Sync failed: \(error)" }
        guard state.isSyncing else { return "Up to date" }
        guard state.isScanning else { return "Syncing logs" }
        guard state.totalFiles > 0 else { return "Checking log changes" }
        let bytes = ByteCountFormatter.string(fromByteCount: Int64(state.bytesRead), countStyle: .file)
        return "Indexing \(state.files) of \(state.totalFiles) files · \(bytes) read"
    }
}
