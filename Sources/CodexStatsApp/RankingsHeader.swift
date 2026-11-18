import CodexStatsCore
import SwiftUI

struct RankingSearchResults {
    let words: [RankedWord]
    let totalCount: Int

    init(words: [RankedWord], query: String) {
        totalCount = words.count
        let searchText = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if searchText.isEmpty {
            self.words = words
        } else {
            self.words = words.filter {
                $0.id.localizedStandardContains(searchText)
                    || $0.family.localizedStandardContains(searchText)
                    || $0.memberWords.contains { $0.localizedStandardContains(searchText) }
            }
        }
    }

    var status: String { "Found \(words.count) of \(totalCount)" }

    var emptyMessage: String? {
        guard words.isEmpty else { return nil }
        return totalCount == 0 ? "No classified words in this selection." : "No matching words."
    }
}

struct RankingsHeader: View {
    @Binding var stems: Bool
    @Binding var search: String
    let resultStatus: String
    let categories: [LexicalCategory: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                Text("Words & families").font(.system(size: 14, weight: .bold)).fixedSize()
                HStack(spacing: 4) {
                    Button("Families") { stems = true }
                        .buttonStyle(AquaButtonStyle(accented: stems))
                        .accessibilityValue(stems ? "Selected" : "")
                    Button("Words") { stems = false }
                        .buttonStyle(AquaButtonStyle(accented: !stems))
                        .accessibilityValue(stems ? "" : "Selected")
                }.frame(width: 180)
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                TextField("Search words or families", text: $search)
                    .textFieldStyle(.plain).aquaTextWell()
                    .accessibilityIdentifier("rankingSearch")
                Text(resultStatus).font(.caption).foregroundStyle(.secondary).fixedSize()
            }
            HStack(spacing: 16) {
                ForEach(LexicalCategory.allCases, id: \.self) { category in
                    Text("\(category.rawValue): \(categories[category, default: 0].formatted())")
                        .font(.caption).foregroundStyle(.secondary).fixedSize()
                }
            }
        }
    }
}
