import CodexStatsCore
import Foundation

struct DateRangeSelection {
    static func ordered(_ first: Date, _ second: Date) -> ClosedRange<Date> {
        min(first, second)...max(first, second)
    }

    static func updating(
        start: Bool,
        to value: Date,
        currentStart: Date,
        currentEnd: Date
    ) -> ClosedRange<Date> {
        if start { return value...max(value, currentEnd) }
        return min(currentStart, value)...value
    }

    static func applyingPreset(_ days: Int, now: Date, to filter: AnalyticsFilter) -> AnalyticsFilter {
        guard [0, 1, 7, 30].contains(days) else { return filter }
        var updated = filter
        updated.since = days == 0 ? nil : now.addingTimeInterval(-Double(days) * 86_400)
        updated.until = nil
        return updated
    }

    static func applying(_ range: ClosedRange<Date>, to filter: AnalyticsFilter) -> AnalyticsFilter {
        var updated = filter
        updated.since = range.lowerBound
        updated.until = range.upperBound
        return updated
    }
}
