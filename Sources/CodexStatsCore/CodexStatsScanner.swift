import Foundation

public final class CodexStatsScanner {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func scan(
        config: CodexStatsConfig,
        now: Date = Date(),
        progress: ((Int, Int) -> Void)? = nil
    ) throws -> CodexStatsSnapshot {
        let regexes = try config.compiledProfanityRegexes()
        var scannedFiles = 0
        var userMessages = 0
        var profanityHits = 0
        var exactMatchCounts: [String: Int] = Dictionary(
            uniqueKeysWithValues: config.exactMatchTokens.map { ($0.lowercased(), 0) }
        )
        var tokenCounts: [String: Int] = [:]
        var rootStats: [CodexRootStats] = []

        let startedAt = now

        for rootURL in config.resolvedRootURLs(fileManager: fileManager) {
            var rootFiles = 0
            var rootMessages = 0
            var rootProfanityHits = 0

            guard let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension == "jsonl" else {
                    continue
                }
                guard config.shouldScan(fileURL: fileURL) else {
                    continue
                }
                rootFiles += 1
                scannedFiles += 1

                let fileResult = scanFile(
                    fileURL: fileURL,
                    regexes: regexes,
                    exactMatchTokens: Set(config.exactMatchTokens.map { $0.lowercased() })
                )

                rootMessages += fileResult.userMessages
                rootProfanityHits += fileResult.profanityHits
                userMessages += fileResult.userMessages
                profanityHits += fileResult.profanityHits
                if scannedFiles == 1 || scannedFiles.isMultiple(of: 10) {
                    progress?(scannedFiles, userMessages)
                }

                for (token, count) in fileResult.tokenCounts {
                    tokenCounts[token, default: 0] += count
                }

                for (token, count) in fileResult.exactMatchCounts {
                    exactMatchCounts[token, default: 0] += count
                }
            }

            rootStats.append(
                CodexRootStats(
                    path: rootURL.path,
                    files: rootFiles,
                    messages: rootMessages,
                    profanityHits: rootProfanityHits
                )
            )
        }

        let topTokens = tokenCounts
            .sorted { lhs, rhs in
                if lhs.value != rhs.value {
                    return lhs.value > rhs.value
                }
                return lhs.key < rhs.key
            }
            .prefix(max(config.topLimit, 0))
            .map { CodexTokenCount(token: $0.key, count: $0.value) }

        progress?(scannedFiles, userMessages)

        return CodexStatsSnapshot(
            scannedFiles: scannedFiles,
            userMessages: userMessages,
            profanityHits: profanityHits,
            exactMatchCounts: exactMatchCounts,
            topTokens: Array(topTokens),
            rootStats: rootStats,
            startedAt: startedAt,
            finishedAt: Date()
        )
    }

    private struct FileScanResult {
        var userMessages: Int = 0
        var profanityHits: Int = 0
        var tokenCounts: [String: Int] = [:]
        var exactMatchCounts: [String: Int] = [:]
    }

    private func scanFile(
        fileURL: URL,
        regexes: [NSRegularExpression],
        exactMatchTokens: Set<String>
    ) -> FileScanResult {
        guard let data = try? Data(contentsOf: fileURL, options: .mappedIfSafe) else {
            return FileScanResult()
        }

        var result = FileScanResult()

        let decoder = JSONDecoder()
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            guard let base = bytes.baseAddress else { return }
            var offset = 0
            while offset < bytes.count {
                let start = base.advanced(by: offset)
                let end = memchr(start, 10, bytes.count - offset).map(UnsafeRawPointer.init)
                    ?? base.advanced(by: bytes.count)
                let length = start.distance(to: end)
                offset += length + 1
                // Decoder finishes before the mapped file buffer leaves this scope.
                let line = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: start), count: length, deallocator: .none)
                guard let payload = extractUserText(from: line, decoder: decoder) else {
                    continue
                }
                result.userMessages += 1

                for token in tokenize(payload) {
                    let lower = token.lowercased()

                    if exactMatchTokens.contains(lower) {
                        result.exactMatchCounts[lower, default: 0] += 1
                    }

                    guard matchesAnyRegex(lower, regexes: regexes) else {
                        continue
                    }

                    result.profanityHits += 1
                    result.tokenCounts[lower, default: 0] += 1
                }
            }
        }

        return result
    }

    private func extractUserText(from data: Data, decoder: JSONDecoder) -> String? {
        if let responseItem = try? decoder.decode(ResponseItemLine.self, from: data),
           responseItem.payload?.role == "user" {
            let contentText = responseItem.payload?.content?
                .compactMap { $0.type == "input_text" ? $0.text : nil }
                .joined(separator: "\n")
            if let contentText, contentText.isEmpty == false {
                return contentText
            }
        }

        if let historyEntry = try? decoder.decode(HistoryEntryLine.self, from: data),
           let text = historyEntry.text,
           text.isEmpty == false {
            return text
        }

        return nil
    }

    private func tokenize(_ text: String) -> [String] {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { $0.isEmpty == false }
    }

    private func matchesAnyRegex(_ token: String, regexes: [NSRegularExpression]) -> Bool {
        let range = NSRange(token.startIndex..<token.endIndex, in: token)
        return regexes.contains { regex in
            regex.firstMatch(in: token, options: [], range: range) != nil
        }
    }
}

private struct ResponseItemLine: Decodable {
    let payload: ResponseItemPayload?
}

private struct ResponseItemPayload: Decodable {
    let role: String?
    let content: [ResponseItemContent]?
}

private struct ResponseItemContent: Decodable {
    let type: String?
    let text: String?
}

private struct HistoryEntryLine: Decodable {
    let text: String?
}
