import Testing
@testable import CodexStatsApp

struct ThreadHeatScaleTests {
    @Test("Given equal percentages, when comparing short and established threads, then short samples stay cooler")
    func sampleWeight() {
        let short = ThreadHeatScale.intensity(share: 0.2, messages: 2)
        let long = ThreadHeatScale.intensity(share: 0.2, messages: 200)
        #expect(short < 0.02)
        #expect(long > 0.18)
        #expect(short < long)
    }

    @Test("Given equal thread sizes, when profanity percentage rises, then heat rises within a bounded scale")
    func percentageWeight() {
        let cool = ThreadHeatScale.intensity(share: 0.1, messages: 100)
        let warm = ThreadHeatScale.intensity(share: 0.5, messages: 100)
        let hot = ThreadHeatScale.intensity(share: 1, messages: 100)
        #expect(0 < cool && cool < warm && warm < hot && hot <= 1)
        #expect(ThreadHeatScale.intensity(share: 1, messages: 0) == 0)
        #expect(ThreadHeatScale.intensity(share: 1, messages: -1) == 0)
        #expect(ThreadHeatScale.intensity(share: -1, messages: 100) == 0)
    }
}
