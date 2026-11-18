import AppKit
import SwiftUI

enum AquaTheme {
    static let ink = Color(red: 0.12, green: 0.16, blue: 0.22)
    static let blue = Color(red: 0.10, green: 0.38, blue: 0.77)
    static let edge = Color(red: 0.55, green: 0.59, blue: 0.65)
    static let silver = LinearGradient(
        colors: [.white, Color(white: 0.94), Color(white: 0.82)], startPoint: .top, endPoint: .bottom)
}

struct AquaPinstripes: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(white: 0.96)))
            for y in stride(from: 0.0, to: size.height, by: 4) {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.white))
                context.fill(
                    Path(CGRect(x: 0, y: y + 2, width: size.width, height: 1)),
                    with: .color(Color(white: 0.91)))
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct AquaBezel: View {
    var accented = false
    var pressed = false
    var radius: CGFloat = 7

    private var colors: [Color] {
        if accented {
            return [
                Color(red: 0.86, green: 0.95, blue: 1), Color(red: 0.32, green: 0.66, blue: 1),
                Color(red: 0.12, green: 0.45, blue: 0.91), Color(red: 0.49, green: 0.79, blue: 1),
            ]
        }
        return [.white, Color(white: 0.98), Color(white: 0.83), Color(white: 0.95)]
    }

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: max(1, radius - 2))
                    .fill(.white.opacity(accented ? 0.65 : 0.8))
                    .padding(.horizontal, 3).padding(.top, 2).frame(height: 9)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(accented ? AquaTheme.blue : AquaTheme.edge, lineWidth: 1)
            }
            .overlay(pressed ? Color.black.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .shadow(color: .black.opacity(0.12), radius: 0, y: 1)
    }
}

struct AquaButtonStyle: ButtonStyle {
    var accented = false
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AquaTheme.ink)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .frame(minHeight: 26)
            .background(AquaBezel(accented: accented, pressed: configuration.isPressed, radius: 13))
            .opacity(enabled ? 1 : 0.5)
            .contentShape(Capsule())
    }
}

struct AquaChoice<Value: Hashable> {
    let value: Value
    let title: String
}

struct AquaPopUp<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let choices: [AquaChoice<Value>]

    var body: some View {
        AquaNativePopUp(title: title, selection: $selection, choices: choices).frame(height: 26)
    }
}

private struct AquaNativePopUp<Value: Hashable>: NSViewRepresentable {
    let title: String
    @Binding var selection: Value
    let choices: [AquaChoice<Value>]
    @Environment(\.isEnabled) private var enabled

    func makeCoordinator() -> AquaPopUpCoordinator { AquaPopUpCoordinator() }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.cell = AquaPopUpCell(textCell: "", pullsDown: false)
        button.font = .systemFont(ofSize: 12)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.target = context.coordinator
        button.action = #selector(AquaPopUpCoordinator.changed(_:))
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        let titles = choices.map(\.title)
        if button.itemTitles != titles {
            button.removeAllItems()
            button.addItems(withTitles: titles)
        }
        if let index = choices.firstIndex(where: { $0.value == selection }) { button.selectItem(at: index) }
        button.isEnabled = enabled
        button.setAccessibilityLabel(title)
        button.cell?.lineBreakMode = .byTruncatingMiddle
        button.cell?.usesSingleLineMode = true
        context.coordinator.onChange = { index in
            guard choices.indices.contains(index) else { return }
            selection = choices[index].value
        }
    }
}

@MainActor
private final class AquaPopUpCoordinator: NSObject {
    var onChange: (Int) -> Void = { _ in }

    @objc func changed(_ sender: NSPopUpButton) { onChange(sender.indexOfSelectedItem) }
}

@MainActor
private final class AquaPopUpCell: NSPopUpButtonCell {
    override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {
        let rect = frame.insetBy(dx: 1, dy: 1)
        let outline = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
        NSGradient(colors: [.white, NSColor(white: 0.98, alpha: 1), NSColor(white: 0.83, alpha: 1), .white])?
            .draw(in: outline, angle: -90)
        NSGraphicsContext.saveGraphicsState()
        outline.addClip()
        let arrow = NSRect(x: rect.maxX - 17, y: rect.minY, width: 17, height: rect.height)
        let blue = [
            NSColor(red: 0.86, green: 0.95, blue: 1, alpha: 1),
            NSColor(red: 0.35, green: 0.67, blue: 1, alpha: 1),
            NSColor(red: 0.12, green: 0.45, blue: 0.91, alpha: 1),
            NSColor(red: 0.49, green: 0.79, blue: 1, alpha: 1),
        ]
        NSGradient(colors: blue)?.draw(in: arrow, angle: -90)
        NSGraphicsContext.restoreGraphicsState()
        drawArrows(in: arrow)
        NSColor(white: 0.57, alpha: 1).setStroke()
        outline.lineWidth = 0.75
        outline.stroke()
    }

    private func drawArrows(in rect: NSRect) {
        let x = rect.midX
        let y = rect.midY
        let arrows = NSBezierPath()
        arrows.move(to: NSPoint(x: x - 2.5, y: y - 2))
        arrows.line(to: NSPoint(x: x + 2.5, y: y - 2))
        arrows.line(to: NSPoint(x: x, y: y - 5))
        arrows.close()
        arrows.move(to: NSPoint(x: x - 2.5, y: y + 2))
        arrows.line(to: NSPoint(x: x + 2.5, y: y + 2))
        arrows.line(to: NSPoint(x: x, y: y + 5))
        arrows.close()
        NSColor(red: 0.1, green: 0.2, blue: 0.36, alpha: 1).setFill()
        arrows.fill()
    }
}

struct AquaCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    AquaBezel(accented: configuration.isOn, radius: 3)
                    if configuration.isOn {
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                            .accessibilityHidden(true)
                    }
                }.frame(width: 15, height: 15)
                configuration.label
            }.foregroundStyle(AquaTheme.ink).font(.system(size: 12))
        }
        .buttonStyle(.plain)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
    }
}

struct AquaStatusRow: View {
    let error: String?

    var body: some View {
        HStack(spacing: 6) {
            if let error {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.orange)
                Text(error).lineLimit(1).truncationMode(.middle).textSelection(.enabled).help(error)
            }
            Spacer(minLength: 0)
        }
        .font(.caption).foregroundStyle(AquaTheme.ink)
        .frame(height: 22)
        .accessibilityHidden(error == nil)
    }
}

struct AquaPanelModifier: ViewModifier {
    var padding: CGFloat = 14

    func body(content: Content) -> some View {
        content.padding(padding)
            .background(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 4).strokeBorder(AquaTheme.edge.opacity(0.8), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .shadow(color: .white, radius: 0, y: 1)
    }
}

extension View {
    func aquaPanel(padding: CGFloat = 14) -> some View { modifier(AquaPanelModifier(padding: padding)) }

    func aquaTextWell() -> some View {
        padding(.horizontal, 7).padding(.vertical, 5)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(AquaTheme.edge, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
