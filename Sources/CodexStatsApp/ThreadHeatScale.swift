import Foundation

enum ThreadHeatScale {
    static func intensity(share: Double, messages: Int) -> Double {
        guard messages > 0 else { return 0 }
        // Twenty quiet prior messages temper small samples without changing the displayed percentage.
        let sampleWeight = Double(messages) / (Double(messages) + 20)
        return min(1, max(0, share)) * sampleWeight
    }
}
