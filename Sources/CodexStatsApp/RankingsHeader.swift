import CodexStatsCore
import SwiftUI

struct RankingsHeader: View {
    @Binding var families: Bool
    let categories: [LexicalCategory: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                Text("Words & families").font(.headline).fixedSize()
                Picker("Ranking", selection: $families) {
                    Text("Families").tag(true)
                    Text("Words").tag(false)
                }
                .pickerStyle(.segmented).labelsHidden().frame(width: 180)
                Spacer(minLength: 0)
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
