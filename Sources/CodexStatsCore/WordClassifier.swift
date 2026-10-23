import Foundation

public enum LexicalCategory: String, Codable, CaseIterable, Sendable {
    case profanity, insult, vulgarity
}

public struct WordMatch: Codable, Equatable, Sendable {
    public let word: String
    public let family: String
    public let category: LexicalCategory
    public let method: String
    public let language: String?
}

/// Classifies complete words using a finite lexicon generated from explicit morphology rules.
public struct WordClassifier: Sendable {
    public let version: Int
    private let matches: [String: WordMatch]
    private let exceptions: Set<String>
    private let languageMatches: [String: [String: WordMatch]]
    private let ambiguousWords: Set<String>
    private let stemByLanguage: [String: [String: String]]

    var supportedLanguages: Set<String> {
        Set(matches.values.compactMap(\.language)).union(
            languageMatches.values.flatMap(\.values).compactMap(\.language))
    }
    var packEntryCounts: [String: Int] { languageMatches.mapValues(\.count) }
    var sourceCandidateCounts: [String: Int] {
        Dictionary(
            uniqueKeysWithValues: lexiconPacks.map { ($0.language, $0.entries.reduce(0) { $0 + $1.sourceForms.count }) }
        )
    }
    private let lexiconPacks: [Lexicon.Pack]
    var sourceRevision: String { lexiconSourceRevision }
    var sourceLicense: String { lexiconSourceLicense }
    private let lexiconSourceRevision: String
    private let lexiconSourceLicense: String

    public init(extraWords: [String: String] = [:]) throws {
        let lexicon = try Self.loadLexicon()
        let source = try Self.validateSource(lexicon.sources)
        try Self.validatePacks(lexicon.packs, exceptions: lexicon.exceptions)
        let index = Self.buildIndex(lexicon, extraWords: extraWords)
        let stems = Self.buildStemIndex(index)
        version = lexicon.version
        exceptions = Set(lexicon.exceptions)
        matches = index.matches
        languageMatches = index.byLanguage
        ambiguousWords = index.ambiguous
        stemByLanguage = stems
        lexiconPacks = lexicon.packs
        lexiconSourceRevision = source.revision
        lexiconSourceLicense = source.license
    }

    private static func loadLexicon() throws -> Lexicon {
        guard let url = ResourceBundle.bundle.url(forResource: "lexicon", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(Lexicon.self, from: Data(contentsOf: url))
    }

    private static func validateSource(_ sources: [Lexicon.Source]) throws -> Lexicon.Source {
        guard sources.count == 1,
            let source = sources.first,
            source.id == "LDNOOBW",
            source.revision.count == 40,
            source.revision.allSatisfy({ $0.isHexDigit }),
            source.url == "https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words",
            source.license == "CC-BY-4.0"
        else { throw CocoaError(.fileReadCorruptFile) }
        return source
    }

    private static func validatePacks(_ packs: [Lexicon.Pack], exceptions: [String]) throws {
        let exclusions = Set(exceptions.map(normalizeLexiconWord))
        var languages = Set<String>()
        for pack in packs {
            guard languages.insert(pack.language).inserted else { throw CocoaError(.fileReadCorruptFile) }
            try validatePack(pack, exclusions: exclusions)
        }
    }

    private static func validatePack(_ pack: Lexicon.Pack, exclusions: Set<String>) throws {
        var seenForms = Set<String>()
        for entry in pack.entries {
            guard !entry.family.isEmpty, !entry.forms.isEmpty, !entry.sourceForms.isEmpty else {
                throw CocoaError(.fileReadCorruptFile)
            }
            try validateEntry(entry, exclusions: exclusions, seenForms: &seenForms)
        }
    }

    private static func validateEntry(
        _ entry: Lexicon.Entry, exclusions: Set<String>, seenForms: inout Set<String>
    ) throws {
        let normalizedForms = entry.forms.map(normalizeLexiconWord)
        let forms = Set(normalizedForms)
        let sourceForms = entry.sourceForms.map(normalizeLexiconWord)
        guard forms.count == normalizedForms.count,
            Set(sourceForms).count == sourceForms.count,
            sourceForms.allSatisfy({ forms.contains($0) })
        else { throw CocoaError(.fileReadCorruptFile) }
        for form in forms {
            let scalarsAreLetters = form.unicodeScalars.allSatisfy {
                CharacterSet.letters.contains($0) || CharacterSet.nonBaseCharacters.contains($0)
            }
            guard !form.isEmpty,
                scalarsAreLetters,
                !exclusions.contains(form),
                seenForms.insert(form).inserted
            else { throw CocoaError(.fileReadCorruptFile) }
        }
    }

    private static func buildIndex(_ lexicon: Lexicon, extraWords: [String: String]) -> LexiconIndex {
        let customWords = Set(extraWords.keys.map(normalizeLexiconWord))
        var index = LexiconIndex(customWords: customWords)
        var categories: [String: LexicalCategory] = [:]
        var familyLanguages: [String: String?] = [:]
        for rule in lexicon.families {
            categories[rule.family] = rule.category
            familyLanguages[rule.family] = rule.language
        }
        index.addFamilies(lexicon.families)
        index.addWords(
            lexicon.words, extraWords: extraWords, masked: lexicon.masked,
            categories: categories, familyLanguages: familyLanguages)
        index.addPacks(lexicon.packs)
        return index
    }

    public func classify(_ word: String) -> WordMatch? {
        classify(word, requestedLanguage: nil)
    }

    public func classify(_ word: String, language: String) -> WordMatch? {
        classify(word, requestedLanguage: language)
    }

    private func classify(_ word: String, requestedLanguage: String?) -> WordMatch? {
        let normalized = normalizeLexiconWord(word)
        guard !exceptions.contains(normalized) else { return nil }
        if let language = requestedLanguage {
            return languageMatches[language]?[normalized]
                ?? classifyNormalized(normalized).flatMap {
                    $0.language == nil || $0.language == language ? $0 : nil
                }
        }
        guard !ambiguousWords.contains(normalized) else { return nil }
        return classifyNormalized(normalized)
    }

    func classifyNormalized(_ word: String) -> WordMatch? {
        guard !exceptions.contains(word) else { return nil }
        return matches[word]
    }

    func stemIdentity(for match: WordMatch) -> StemIdentity {
        let word = normalizeLexiconWord(match.word)
        let stem = match.language.flatMap { stemByLanguage[$0]?[word] } ?? word
        return StemIdentity(stem: stem, language: match.language, category: match.category)
    }

    private static func buildStemIndex(_ index: LexiconIndex) -> [String: [String: String]] {
        var wordsByLanguage = index.byLanguage
        for match in index.matches.values {
            guard let language = match.language else { continue }
            wordsByLanguage[language, default: [:]][match.word] = match
        }
        return wordsByLanguage.mapValues { words in
            Dictionary(
                uniqueKeysWithValues: words.keys.map { word in
                    (word, SnowballStemmer.stem(word, language: words[word]?.language ?? "") ?? word)
                })
        }
    }

    /// Preserves supported masking characters inside lexical tokens.
    public func words(in text: String) -> [String: Int] {
        var result: [String: Int] = [:]
        var token = ""
        for scalar in normalizeLexiconWord(text).unicodeScalars {
            if CharacterSet.letters.contains(scalar) || CharacterSet.nonBaseCharacters.contains(scalar)
                || scalar == "*" || scalar == "@"
            {
                token.unicodeScalars.append(scalar)
            } else if !token.isEmpty {
                if token.unicodeScalars.contains(where: CharacterSet.letters.contains) {
                    result[token, default: 0] += 1
                }
                token = ""
            }
        }
        if token.unicodeScalars.contains(where: CharacterSet.letters.contains) { result[token, default: 0] += 1 }
        return result
    }

}

struct StemIdentity: Hashable, Sendable {
    let stem: String
    let language: String?
    let category: LexicalCategory

    var id: String { "\(language ?? "undetermined")|\(category.rawValue)|\(stem)" }
}

private func normalizeLexiconWord(_ text: String) -> String {
    text.precomposedStringWithCanonicalMapping.lowercased().replacingOccurrences(of: "ё", with: "е")
}

private struct LexiconIndex {
    var matches: [String: WordMatch] = [:]
    var byLanguage: [String: [String: WordMatch]] = [:]
    var ambiguous = Set<String>()
    let customWords: Set<String>

    mutating func addFamilies(_ families: [Lexicon.Family]) {
        for rule in families {
            for prefix in rule.prefixes {
                for stem in rule.stems {
                    for ending in rule.endings {
                        let word = prefix + stem + ending
                        matches[word] = WordMatch(
                            word: word, family: rule.family, category: rule.category, method: "morphology",
                            language: rule.language)
                    }
                }
            }
        }
    }

    mutating func addWords(
        _ words: [String: String], extraWords: [String: String], masked: [String: String],
        categories: [String: LexicalCategory], familyLanguages: [String: String?]
    ) {
        addDictionary(
            words.merging(extraWords) { _, new in new }, method: "dictionary", categories: categories,
            familyLanguages: familyLanguages)
        addDictionary(masked, method: "masked", categories: categories, familyLanguages: familyLanguages)
    }

    private mutating func addDictionary(
        _ words: [String: String], method: String, categories: [String: LexicalCategory],
        familyLanguages: [String: String?]
    ) {
        for (word, family) in words {
            let language = customWords.contains(normalizeLexiconWord(word)) ? nil : familyLanguages[family] ?? nil
            matches[word] = WordMatch(
                word: word, family: family, category: categories[family] ?? .profanity, method: method,
                language: language)
        }
    }

    mutating func addPacks(_ packs: [Lexicon.Pack]) {
        for pack in packs {
            for entry in pack.entries {
                for word in entry.forms {
                    let normalized = normalizeLexiconWord(word)
                    guard !customWords.contains(normalized) else { continue }
                    register(
                        WordMatch(
                            word: normalized, family: entry.family, category: entry.category, method: "curated",
                            language: pack.language), in: pack.language)
                }
            }
        }
    }

    private mutating func register(_ match: WordMatch, in language: String) {
        byLanguage[language, default: [:]][match.word] = match
        guard !ambiguous.contains(match.word) else { return }
        guard let existing = matches[match.word] else {
            matches[match.word] = match
            return
        }
        guard existing.category == match.category, existing.family == match.family else {
            matches.removeValue(forKey: match.word)
            ambiguous.insert(match.word)
            return
        }
        guard existing.language != match.language else { return }
        matches[match.word] = WordMatch(
            word: match.word, family: match.family, category: match.category, method: "curated", language: nil)
    }
}

private struct Lexicon: Decodable {
    let version: Int
    let families: [Family]
    let words: [String: String]
    let masked: [String: String]
    let exceptions: [String]
    let packs: [Pack]
    let sources: [Source]

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

    struct Family: Decodable {
        let family: String
        let category: LexicalCategory
        let stems: [String]
        let prefixes: [String]
        let endings: [String]
        let language: String?
    }
}
