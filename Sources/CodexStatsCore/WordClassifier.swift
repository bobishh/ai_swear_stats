import Foundation

public enum LexicalCategory: String, Codable, CaseIterable, Sendable {
    case profanity, insult, vulgarity
}

public struct WordMatch: Codable, Equatable, Sendable {
    public let word: String
    public let family: String
    public let category: LexicalCategory
    public let method: String
}

/// Classifies complete words using a finite lexicon generated from explicit morphology rules.
public struct WordClassifier: Sendable {
    public let version: Int
    private let matches: [String: WordMatch]
    private let exceptions: Set<String>

    public init(extraWords: [String: String] = [:]) throws {
        guard let url = ResourceBundle.bundle.url(forResource: "lexicon", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let lexicon = try JSONDecoder().decode(Lexicon.self, from: Data(contentsOf: url))
        version = lexicon.version
        exceptions = Set(lexicon.exceptions)
        var entries: [String: WordMatch] = [:]
        var categories: [String: LexicalCategory] = [:]
        for rule in lexicon.families {
            categories[rule.family] = rule.category
            for prefix in rule.prefixes {
                for stem in rule.stems {
                    for ending in rule.endings {
                        let word = prefix + stem + ending
                        entries[word] = WordMatch(
                            word: word, family: rule.family, category: rule.category, method: "morphology")
                    }
                }
            }
        }
        for (method, words) in [
            ("dictionary", lexicon.words.merging(extraWords) { _, new in new }), ("masked", lexicon.masked),
        ] {
            for (word, family) in words {
                entries[word] = WordMatch(
                    word: word, family: family, category: categories[family] ?? .profanity, method: method)
            }
        }
        matches = entries
    }

    public func classify(_ word: String) -> WordMatch? {
        classifyNormalized(normalize(word))
    }

    func classifyNormalized(_ word: String) -> WordMatch? {
        guard !exceptions.contains(word) else { return nil }
        return matches[word]
    }

    /// Preserves supported masking characters inside lexical tokens.
    public func words(in text: String) -> [String: Int] {
        var result: [String: Int] = [:]
        var token = ""
        for scalar in normalize(text).unicodeScalars {
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

    private func normalize(_ text: String) -> String {
        text.precomposedStringWithCanonicalMapping.lowercased().replacingOccurrences(of: "ё", with: "е")
    }
}

private struct Lexicon: Decodable {
    let version: Int
    let families: [Family]
    let words: [String: String]
    let masked: [String: String]
    let exceptions: [String]

    struct Family: Decodable {
        let family: String
        let category: LexicalCategory
        let stems: [String]
        let prefixes: [String]
        let endings: [String]
    }
}
