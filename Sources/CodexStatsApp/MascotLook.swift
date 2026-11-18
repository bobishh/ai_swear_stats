import AppKit

@MainActor
final class MascotLook {
    static let builtIn = MascotLook(appearance: .bundled)
    let appearance: MascotAppearance
    private let frames: [String: [NSImage?]]

    init(appearance: MascotAppearance) {
        self.appearance = appearance
        frames = appearance.manifest.clips.mapValues { clip in
            clip.frames.map { NSImage(contentsOf: appearance.root.appendingPathComponent($0)) }
        }
    }

    var isComplete: Bool {
        ChartMascotMotion.Pose.allCases.allSatisfy { pose in
            guard let clip = frames[pose.rawValue], !clip.isEmpty else { return false }
            return clip.allSatisfy { $0 != nil }
        }
    }

    func image(pose: ChartMascotMotion.Pose, index: Int) -> NSImage? {
        guard let clip = frames[pose.rawValue], clip.indices.contains(index) else { return nil }
        return clip[index]
    }
}
