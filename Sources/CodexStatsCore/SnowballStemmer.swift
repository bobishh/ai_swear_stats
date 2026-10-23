import CSnowball
import Foundation

enum SnowballStemmer {
    static func stem(_ word: String, language: String) -> String? {
        let input = Array(word.utf8)
        guard !input.isEmpty else { return nil }
        var output = [CChar](repeating: 0, count: input.count + 1)
        let length = language.withCString { languagePointer in
            word.withCString { inputPointer in
                output.withUnsafeMutableBufferPointer { buffer in
                    csnowball_stem(languagePointer, inputPointer, buffer.baseAddress, buffer.count)
                }
            }
        }
        guard length >= 0 else { return nil }
        return String(decoding: output.prefix(Int(length)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}
