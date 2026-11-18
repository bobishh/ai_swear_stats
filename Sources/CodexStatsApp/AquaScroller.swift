import AppKit
import SwiftUI

@MainActor
final class AquaScroller: NSScroller {
    override class var isCompatibleWithOverlayScrollers: Bool { false }

    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 0), xRadius: 7, yRadius: 7)
        NSGradient(colors: [NSColor(white: 0.74, alpha: 1), .white, NSColor(white: 0.88, alpha: 1)])?
            .draw(in: path, angle: 0)
        NSColor(white: 0.6, alpha: 1).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    override func drawKnob() {
        let knob = rect(for: .knob).insetBy(dx: 2, dy: 1)
        guard knob.height > 0, knob.width > 0 else { return }
        let vertical = bounds.height > bounds.width
        let path = NSBezierPath(roundedRect: knob, xRadius: 6, yRadius: 6)
        let colors: [NSColor] = [
            NSColor(red: 0.16, green: 0.41, blue: 0.79, alpha: 1),
            NSColor(red: 0.35, green: 0.68, blue: 1, alpha: 1),
            NSColor(red: 0.64, green: 0.86, blue: 1, alpha: 1),
            NSColor(red: 0.18, green: 0.53, blue: 0.94, alpha: 1),
        ]
        NSGradient(colors: colors)?.draw(in: path, angle: vertical ? 0 : 90)
        NSColor(red: 0.13, green: 0.35, blue: 0.67, alpha: 1).setStroke()
        path.lineWidth = 0.75
        path.stroke()
        let glint =
            vertical
            ? NSRect(
                x: knob.minX + 2, y: knob.minY + 4, width: max(1, knob.width * 0.25), height: max(0, knob.height - 8))
            : NSRect(
                x: knob.minX + 4, y: knob.minY + 2, width: max(0, knob.width - 8), height: max(1, knob.height * 0.25))
        NSColor.white.withAlphaComponent(0.55).setFill()
        NSBezierPath(roundedRect: glint, xRadius: 3, yRadius: 3).fill()
    }
}

struct AquaScrollChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> AquaScrollAttachment { AquaScrollAttachment() }

    func updateNSView(_ view: AquaScrollAttachment, context: Context) { view.install() }
}

@MainActor
final class AquaScrollAttachment: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        install()
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        install()
    }

    func install() {
        guard let scroll = enclosingScrollView else { return }
        scroll.scrollerStyle = .legacy
        scroll.autohidesScrollers = false
        scroll.hasVerticalScroller = true
        if !(scroll.verticalScroller is AquaScroller) {
            let scroller = AquaScroller()
            scroller.controlSize = .regular
            scroller.scrollerStyle = .legacy
            scroll.verticalScroller = scroller
        }
        scroll.drawsBackground = false
    }
}
