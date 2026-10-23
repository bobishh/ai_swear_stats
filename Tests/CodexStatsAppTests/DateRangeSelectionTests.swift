import Foundation
import CodexStatsCore
import Testing
@testable import CodexStatsApp

struct DateRangeSelectionTests {
    @Test("Given a reverse chart drag, when dates are selected, then controls receive an ordered range")
    func reverseDragUpdatesControls() {
        let start = Date(timeIntervalSince1970: 100)
        let end = Date(timeIntervalSince1970: 300)
        let range = DateRangeSelection.ordered(end, start)
        #expect(range.lowerBound == start)
        #expect(range.upperBound == end)
    }

    @Test("Given date controls, when either endpoint crosses the other, then the range collapses at that date")
    func dateControlsStayOrdered() {
        let start = Date(timeIntervalSince1970: 100)
        let end = Date(timeIntervalSince1970: 300)
        let laterStart = Date(timeIntervalSince1970: 400)
        let earlierEnd = Date(timeIntervalSince1970: 50)
        let fromEdit = DateRangeSelection.updating(
            start: true, to: laterStart, currentStart: start, currentEnd: end)
        let toEdit = DateRangeSelection.updating(
            start: false, to: earlierEnd, currentStart: start, currentEnd: end)
        #expect(fromEdit.lowerBound == laterStart)
        #expect(fromEdit.upperBound == laterStart)
        #expect(toEdit.lowerBound == earlierEnd)
        #expect(toEdit.upperBound == earlierEnd)
    }

    @Test(
        "Given a selected model and thread, when applying a quick period, then identity filters remain and bounds reset"
    )
    func presetPreservesIdentityAndClearsUpperBound() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        var filter = AnalyticsFilter(
            model: "codex/model-a", thread: "thread-a",
            since: Date(timeIntervalSince1970: 10), until: Date(timeIntervalSince1970: 20))
        let updated = DateRangeSelection.applyingPreset(7, now: now, to: filter)
        #expect(updated.model == filter.model)
        #expect(updated.thread == filter.thread)
        #expect(updated.since == now.addingTimeInterval(-7 * 86_400))
        #expect(updated.until == nil)
        filter = DateRangeSelection.applyingPreset(0, now: now, to: updated)
        #expect(filter.since == nil)
        #expect(filter.until == nil)
        #expect(filter.thread == "thread-a")
    }

    @Test("Given a custom date range, when applying it, then identity filters remain and reversed dates are ordered")
    func manualRangePreservesIdentity() {
        let earlier = Date(timeIntervalSince1970: 100)
        let later = Date(timeIntervalSince1970: 300)
        let filter = AnalyticsFilter(model: "claude/model-b", thread: "thread-b")
        let updated = DateRangeSelection.applying(DateRangeSelection.ordered(later, earlier), to: filter)
        #expect(updated.model == "claude/model-b")
        #expect(updated.thread == "thread-b")
        #expect(updated.since == earlier)
        #expect(updated.until == later)
    }

    @Test("Given the Custom range picker item, when selected, then applying that unsupported preset changes nothing")
    func customPickerValueIsNoop() {
        let filter = AnalyticsFilter(model: "codex/model-a", thread: "thread-a", since: Date(timeIntervalSince1970: 50))
        #expect(DateRangeSelection.applyingPreset(-1, now: Date(), to: filter) == filter)
    }
}
