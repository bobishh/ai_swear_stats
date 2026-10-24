import Foundation
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

    @Test(
        "Given the exact Russian tokens хули and хуяли, when classified, then casing normalizes and innocent neighbors stay clear"
    )
    func explicitRussianTokens() throws {
        let classifier = try WordClassifier()
        for word in ["хули", "хуяли", "ХУЛИ", "ХУЯЛИ", "Хуяли"] {
            let match = classifier.classify(word)
            #expect(match?.category == .profanity, "Missing: \(word)")
            #expect(match?.family == "хуй", "Legacy word metadata changed: \(word)")
        }
        for word in ["хулиган", "хулиганство", "хулиганить", "хула"] {
            #expect(classifier.classify(word) == nil, "False positive: \(word)")
        }
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
            #expect(match?.family == "ебать", "Legacy classifier label changed: \(word)")
        }
        for word in ["долбить", "долбеж", "долбежка", "долбоебина", "долбоебизм"] {
            #expect(classifier.classify(word) == nil, "False positive: \(word)")
        }
        for (word, category) in [
            ("хер", LexicalCategory.profanity), ("хера", LexicalCategory.profanity),
            ("хером", LexicalCategory.profanity), ("херня", LexicalCategory.profanity),
            ("cunt", LexicalCategory.profanity), ("bastard", LexicalCategory.insult),
            ("motherfuck", LexicalCategory.profanity), ("bullshit", LexicalCategory.profanity),
            ("puttana", LexicalCategory.insult), ("klootzak", LexicalCategory.insult),
            ("popierdolony", LexicalCategory.insult),
        ] {
            let match = classifier.classify(word)
            #expect(match?.category == category, "Category changed: \(word)")
        }
    }

    @Test(
        "Given curated terms in every advertised language, when classified, then profanity is recognized without substring or neutral-word matches"
    )
    func multilingualPacks() throws {
        let classifier = try WordClassifier()
        let positiveCases: [(String, LexicalCategory)] = [
            ("блять", .profanity), ("fuck", .profanity),
            ("Scheiße", .profanity), ("mierda", .profanity), ("merde", .profanity),
            ("cazzo", .profanity), ("porra", .profanity), ("kut", .profanity), ("kurwa", .profanity),
        ]
        for (word, category) in positiveCases {
            #expect(classifier.classify(word)?.category == category, "Missing multilingual term: \(word)")
        }
        #expect(classifier.classify("SCHEISSE", language: "de")?.language == "de")
        #expect(classifier.classify("merde", language: "de") == nil)
        #expect(classifier.classify("connard", language: "fr")?.category == .insult)
        #expect(classifier.classify("kacke", language: "de")?.category == .vulgarity)
        #expect(classifier.classify("puta", language: "es")?.category == .profanity)
        #expect(classifier.classify("MERDES", language: "fr")?.family == "merde")
        #expect(classifier.classify("VOLLpfosten", language: "de")?.category == .insult)
        #expect(classifier.classify("cabrón", language: "es")?.category == .insult)
        #expect(classifier.classify("caca", language: "es")?.category == .vulgarity)
        #expect(classifier.classify("coglione", language: "it")?.category == .insult)
        #expect(classifier.classify("piscio", language: "it")?.category == .vulgarity)
        #expect(classifier.classify("vadia", language: "pt")?.category == .insult)
        #expect(classifier.classify("bosta", language: "pt")?.category == .vulgarity)
        #expect(classifier.classify("hufter", language: "nl")?.category == .insult)
        #expect(classifier.classify("schijt", language: "nl")?.category == .vulgarity)
        #expect(classifier.classify("skurwysyn", language: "pl")?.category == .insult)
        #expect(classifier.classify("gówno", language: "pl")?.category == .vulgarity)
        for word in [
            "gay", "vagina", "penis", "vulva", "asphalt", "classic", "assistant", "Scunthorpe",
            "schiesser", "scopare", "eikel", "corno", "troia", "culo", "foda-se",
        ] {
            #expect(classifier.classify(word) == nil, "False positive: \(word)")
        }
        #expect(classifier.supportedLanguages == ["en", "ru", "de", "es", "fr", "it", "pt", "nl", "pl"])
        #expect(classifier.packEntryCounts == ["de": 27, "es": 19, "fr": 29, "it": 24, "pt": 20, "nl": 24, "pl": 35])
        #expect(
            classifier.sourceCandidateCounts == ["de": 23, "es": 13, "fr": 21, "it": 22, "pt": 12, "nl": 24, "pl": 18])
        #expect(classifier.sourceRevision == "5faf2ba42d7b1c0977169ec3611df25a3c08eb13")
        #expect(classifier.sourceLicense == "CC-BY-4.0")
        #expect(classifier.classify("puta") == nil, "Cross-language category conflict must stay unresolved")
        #expect(classifier.classify("puta", language: "es")?.category == .profanity)
        #expect(classifier.classify("puta", language: "pt")?.category == .insult)

        let overriding = try WordClassifier(extraWords: ["mierda": "fuck"])
        #expect(overriding.classify("mierda")?.family == "fuck")
        #expect(overriding.classify("mierda", language: "es")?.family == "fuck")
    }

    @Test(
        "Given bundled language packs, when validating their manifest, then source forms, normalized keys, and exclusions agree"
    )
    func packIntegrity() throws {
        let url = try #require(ResourceBundle.bundle.url(forResource: "lexicon", withExtension: "json"))
        let lexicon = try JSONDecoder().decode(TestLexicon.self, from: Data(contentsOf: url))
        #expect(lexicon.version == 5)
        #expect(lexicon.sources.count == 1)
        #expect(lexicon.sources.first?.id == "LDNOOBW")
        #expect(
            lexicon.sources.first?.url
                == "https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words")
        #expect(lexicon.sources.first?.license == "CC-BY-4.0")
        #expect(lexicon.sources.first?.revision == "5faf2ba42d7b1c0977169ec3611df25a3c08eb13")

        let exclusions = Set(lexicon.exceptions.map(normalize))
        #expect(Set(lexicon.packs.map(\.language)).count == lexicon.packs.count)
        for pack in lexicon.packs {
            var seen = Set<String>()
            for entry in pack.entries {
                let forms = entry.forms.map(normalize)
                let sourceForms = entry.sourceForms.map(normalize)
                #expect(!forms.isEmpty)
                #expect(Set(forms).count == forms.count, "Duplicate normalized forms in \(pack.language)")
                #expect(Set(sourceForms).count == sourceForms.count, "Duplicate source forms in \(pack.language)")
                #expect(sourceForms.allSatisfy(Set(forms).contains), "Source form missing from accepted forms")
                #expect(forms.allSatisfy({ !$0.isEmpty && !$0.contains(where: \.isWhitespace) }))
                #expect(forms.allSatisfy({ !exclusions.contains($0) }), "Excluded form in \(pack.language)")
                for form in forms {
                    #expect(seen.insert(form).inserted, "Duplicate pack key \(form) in \(pack.language)")
                }
            }
        }
    }

    @Test("Given a WordMatch serialized before language metadata, when decoded, then it remains compatible")
    func oldMatchCodingCompatibility() throws {
        let data = Data(#"{"word":"fuck","family":"fuck","category":"profanity","method":"dictionary"}"#.utf8)
        let match = try JSONDecoder().decode(WordMatch.self, from: data)
        #expect(match.language == nil)
    }

    private func normalize(_ word: String) -> String {
        word.precomposedStringWithCanonicalMapping.lowercased().replacingOccurrences(of: "ё", with: "е")
    }
}

private struct TestLexicon: Decodable {
    let version: Int
    let exceptions: [String]
    let sources: [Source]
    let packs: [Pack]

    struct Source: Decodable {
        let id: String
        let url: String
        let revision: String
        let license: String
    }

    struct Pack: Decodable {
        let language: String
        let entries: [Entry]
    }

    struct Entry: Decodable {
        let family: String
        let category: LexicalCategory
        let forms: [String]
        let sourceForms: [String]
    }
}
