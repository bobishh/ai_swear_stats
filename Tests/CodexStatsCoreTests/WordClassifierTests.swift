import Testing
@testable import CodexStatsCore

struct WordClassifierTests {
    @Test("Given lexical families, when classifying inflections and lookalikes, then only supported forms match")
    func morphology() throws {
        let classifier = try WordClassifier()
        for word in ["блять", "блядь", "заебали", "хуйню", "ПИЗДЕЦ", "fucking", "motherfucker", "бл*ть"] {
            #expect(classifier.classify(word)?.category == .profanity, "Missing: \(word)")
        }
        for word in ["страхуй", "подстрахуй", "рубля", "Scunthorpe", "assistant", "assignment", "хлеб", "неизвестно"] {
            #expect(classifier.classify(word) == nil, "False positive: \(word)")
        }
        #expect(classifier.classify("мудак")?.category == .insult)
        #expect(classifier.classify("говно")?.category == .vulgarity)
        #expect(classifier.words(in: "бл*ть, fuck! fuck")["fuck"] == 2)
    }
}
