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

    @Test("Given Russian declensions of долбоеб, when classified, then each form counts as profanity")
    func dolboebDeclensions() throws {
        let classifier = try WordClassifier()
        for word in [
            "долбоеб", "долбоёб", "долбоеба", "долбоебу", "долбоебом", "долбоебе", "долбоебы", "долбоебов", "долбоебам",
            "долбоебами", "долбоебах", "ДОЛБОЁБАМИ",
        ] {
            let match = classifier.classify(word)
            #expect(match?.category == .profanity, "Missing: \(word)")
            #expect(match?.family == "ебать", "Wrong family: \(word)")
        }
        for word in ["долбить", "долбеж", "долбежка"] {
            #expect(classifier.classify(word) == nil, "False positive: \(word)")
        }
    }
}
