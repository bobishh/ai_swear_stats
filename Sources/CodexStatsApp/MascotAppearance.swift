import Foundation

struct MascotAppearance: Sendable {
    struct Canvas: Codable, Sendable {
        let width: Int
        let height: Int
        let footX: Int
        let footY: Int
    }

    struct Clip: Codable, Sendable {
        let frames: [String]
        let frameDuration: Double
        let releaseFrame: Int?
    }

    struct Manifest: Codable, Sendable {
        let formatVersion: Int
        let name: String
        let canvas: Canvas
        let clips: [String: Clip]
    }

    struct InvalidPackage: LocalizedError {
        let reason: String
        var errorDescription: String? { reason }
    }

    let root: URL
    let manifest: Manifest
    var name: String { manifest.name }

    static let bundled: MascotAppearance = {
        let root = (Bundle.module.resourceURL ?? URL(fileURLWithPath: "/missing-resources"))
            .appendingPathComponent("Mascot")
        if let loaded = try? load(from: root) { return loaded }
        return MascotAppearance(
            root: root,
            manifest: Manifest(
                formatVersion: 1, name: "Bodya", canvas: Canvas(width: 192, height: 208, footX: 96, footY: 204),
                clips: [:]))
    }()

    static func load(from root: URL) throws -> MascotAppearance {
        let root = root.resolvingSymlinksInPath().standardizedFileURL
        let manifestURL = root.appendingPathComponent("manifest.json")
        try checkFile(manifestURL, maximumBytes: 65_536)
        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(Manifest.self, from: data)
        guard manifest.formatVersion == 1 else { throw invalid("Unsupported mascot format version.") }
        guard !manifest.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, manifest.name.count <= 60 else {
            throw invalid("Give this mascot a name of 1–60 characters.")
        }
        let canvas = manifest.canvas
        guard canvas.width == 192, canvas.height == 208, canvas.footX == 96, canvas.footY == 204 else {
            throw invalid("Frames must be 192 × 208 with the feet anchored at (96, 204).")
        }
        for pose in ChartMascotMotion.Pose.allCases {
            guard let clip = manifest.clips[pose.rawValue], (2...32).contains(clip.frames.count),
                clip.frameDuration.isFinite, (0.04...1).contains(clip.frameDuration)
            else { throw invalid("Missing or invalid animation: \(pose.rawValue).") }
            if pose == .throwBottle {
                guard let release = clip.releaseFrame, clip.frames.indices.contains(release) else {
                    throw invalid("The throw animation needs a valid releaseFrame.")
                }
            }
            for path in clip.frames { try checkFrame(path, in: root) }
        }
        try checkActionTiming(manifest)
        return MascotAppearance(root: root, manifest: manifest)
    }

    func clip(_ pose: ChartMascotMotion.Pose) -> Clip? { manifest.clips[pose.rawValue] }

    private static func checkFrame(_ path: String, in root: URL) throws {
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        guard !path.hasPrefix("/"), !path.contains("\\"), (1...3).contains(parts.count),
            parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }), path.hasSuffix(".png")
        else { throw invalid("Frame paths must point to PNG files inside this folder.") }
        let file = root.appendingPathComponent(path).standardizedFileURL
        guard file.resolvingSymlinksInPath().path == file.path else {
            throw invalid("Symbolic links are not supported in mascot packages.")
        }
        try checkFile(file, maximumBytes: 2_097_152)
        let header = [UInt8](try Data(contentsOf: file).prefix(26))
        guard header.count == 26, Array(header.prefix(8)) == [137, 80, 78, 71, 13, 10, 26, 10],
            integer(header, at: 16) == 192, integer(header, at: 20) == 208, header[25] == 6
        else { throw invalid("\(path) must be a 192 × 208 RGBA PNG.") }
    }

    private static func checkFile(_ url: URL, maximumBytes: Int) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard attributes[.type] as? FileAttributeType == .typeRegular,
            let size = attributes[.size] as? Int, size > 0, size <= maximumBytes
        else { throw invalid("\(url.lastPathComponent) is missing, oversized, or not a regular file.") }
    }

    private static func integer(_ bytes: [UInt8], at index: Int) -> Int {
        bytes[index..<index + 4].reduce(0) { $0 * 256 + Int($1) }
    }

    private static func checkActionTiming(_ manifest: Manifest) throws {
        guard let drink = manifest.clips["drink"], let throwing = manifest.clips["throw"],
            let release = throwing.releaseFrame
        else { throw invalid("Missing bottle animations.") }
        let throwStart = Double(drink.frames.count) * drink.frameDuration + 1
        let clipEnd = throwStart + Double(throwing.frames.count) * throwing.frameDuration
        let landing = throwStart + Double(release) * throwing.frameDuration + 0.6
        guard max(clipEnd, landing) <= MascotCycle.Timing.freshDrinkSceneDuration else {
            throw invalid("Drink, pause, throw and landing must fit the 4.8-second bottle cycle.")
        }
    }

    private static func invalid(_ reason: String) -> InvalidPackage { InvalidPackage(reason: reason) }
}
