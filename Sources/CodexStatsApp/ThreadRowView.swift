import AppKit
import CodexStatsCore
import SwiftUI

struct ThreadRowView: View {
    let thread: ThreadSummary
    let selected: Bool

    private var heat: Double {
        ThreadHeatScale.intensity(share: thread.profaneMessageShare, messages: thread.messages)
    }

    private var tint: Color { ThreadHeatScale.color(heat) }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top, spacing: 8) {
                Text(thread.title).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                Text(thread.profaneMessageShare.formatted(.percent.precision(.fractionLength(0))))
                    .font(.caption.weight(.semibold)).monospacedDigit().fixedSize()
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(tint.opacity(0.16), in: Capsule())
            }
            Text("\(thread.provider) · \(thread.messages) messages · \(thread.hits) hits")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(10).padding(.leading, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08 + 0.07 * heat), in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .leading) {
            Capsule().fill(tint).frame(width: 3).padding(.vertical, 9).padding(.leading, 5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8).strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .help("\(thread.profaneMessages) of \(thread.messages) messages contain profanity.")
        .accessibilityElement(children: .combine)
        .accessibilityValue(selected ? "Selected" : "")
    }
}

extension ThreadHeatScale {
    static func color(_ intensity: Double) -> Color {
        let stops: [NSColor] = [.systemBlue, .systemPurple, .systemOrange, .systemRed]
        let position = min(1, max(0, intensity)) * Double(stops.count - 1)
        let index = min(Int(position), stops.count - 2)
        let fraction = position - Double(index)
        return Color(nsColor: stops[index].blended(withFraction: fraction, of: stops[index + 1]) ?? stops[index])
    }
}

struct ThreadHeatLegend: View {
    var body: some View {
        HStack(spacing: 6) {
            LinearGradient(
                colors: [0.0, 1.0 / 3, 2.0 / 3, 1.0].map(ThreadHeatScale.color),
                startPoint: .leading, endPoint: .trailing
            ).frame(width: 36, height: 5).clipShape(Capsule())
            Text("Profanity").font(.caption2).foregroundStyle(.secondary)
        }
    }
}
