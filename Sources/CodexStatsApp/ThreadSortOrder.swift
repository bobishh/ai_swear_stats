import CodexStatsCore
import Foundation

enum ThreadSortOrder: String, CaseIterable, Identifiable {
    case temperature
    case recent

    var id: String { rawValue }
    var title: String { self == .temperature ? "Hottest first" : "Recent activity" }

    func ordered(_ threads: [ThreadSummary]) -> [ThreadSummary] {
        threads.sorted { left, right in
            if self == .temperature {
                let leftHeat = ThreadHeatScale.intensity(share: left.profaneMessageShare, messages: left.messages)
                let rightHeat = ThreadHeatScale.intensity(share: right.profaneMessageShare, messages: right.messages)
                if leftHeat != rightHeat { return leftHeat > rightHeat }
            }
            let leftTime = left.latest ?? .distantPast
            let rightTime = right.latest ?? .distantPast
            return leftTime == rightTime ? left.id < right.id : leftTime > rightTime
        }
    }
}
