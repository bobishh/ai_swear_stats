import Foundation
import Testing
@testable import CodexStatsApp

struct MascotAppearanceTests {
    @Test("Given the editable built-in package, when loaded, then all actions declare PNG frames and a foot anchor")
    func builtInPackageLoads() throws {
        let appearance = try MascotAppearance.load(from: MascotAppearance.bundled.root)
        #expect(appearance.manifest.canvas.footX == 96)
        #expect(appearance.manifest.canvas.footY == 204)
        #expect(ChartMascotMotion.Pose.allCases.allSatisfy { appearance.clip($0)?.frames.isEmpty == false })
    }

    @Test("Given a package pointing outside its folder, when selected, then import rejects it")
    func rejectsTraversal() throws {
        try withManifest { root, manifest in
            var changed = manifest
            var clips = try #require(manifest["clips"] as? [String: Any])
            clips["walk-right"] = ["frameDuration": 0.12, "frames": ["../outside.png", "../outside.png"]]
            changed["clips"] = clips
            try JSONSerialization.data(withJSONObject: changed).write(to: root.appendingPathComponent("manifest.json"))
            #expect(throws: (any Error).self) { try MascotAppearance.load(from: root) }
        }
    }

    @Test("Given locally edited frame metadata, when loaded, then playback uses the package's frame count")
    func frameCountsComeFromManifest() throws {
        try withManifest { root, manifest in
            var changed = manifest
            var clips = try #require(manifest["clips"] as? [String: Any])
            clips["walk-right"] = ["frameDuration": 0.2, "frames": ["walk-right/00.png", "walk-right/01.png"]]
            changed["clips"] = clips
            try JSONSerialization.data(withJSONObject: changed).write(to: root.appendingPathComponent("manifest.json"))
            let appearance = try MascotAppearance.load(from: root)
            #expect(ChartMascotMotion.frameCount(for: .walkRight, appearance: appearance) == 2)
        }
    }

    @Test("Given an active bottle queue, when a broken appearance is selected, then both the look and cycle survive")
    @MainActor
    func failedSelectionPreservesCycleAndLook() throws {
        let suite = "swear-stats-appearance-test-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let state = DashboardState(defaults: defaults)
        let now = Date()
        state.mascotCycle.receive(hits: 5, at: now)
        let before = state.mascotCycle.snapshot(at: now)
        let look = state.mascotLook
        #expect(throws: (any Error).self) {
            try state.selectMascot(from: URL(fileURLWithPath: "/missing-mascot"))
        }
        #expect(state.mascotLook === look)
        #expect(state.mascotCycle.snapshot(at: now) == before)
        try state.selectMascot(from: MascotAppearance.bundled.root)
        #expect(state.mascotCycle.snapshot(at: now) == before)
        let restored = DashboardState(defaults: defaults)
        #expect(restored.mascotLook.appearance.root == state.mascotLook.appearance.root)
    }

    @Test("Given incomplete or incompatible animation metadata, when selected, then import rejects it")
    func rejectsIncompletePackage() throws {
        try withManifest { root, manifest in
            var changed = manifest
            changed["formatVersion"] = 999
            changed["clips"] = [:]
            try JSONSerialization.data(withJSONObject: changed).write(to: root.appendingPathComponent("manifest.json"))
            #expect(throws: (any Error).self) { try MascotAppearance.load(from: root) }
        }
    }

    private func withManifest(_ body: (URL, [String: Any]) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.copyItem(at: MascotAppearance.bundled.root, to: root)
        defer { try? FileManager.default.removeItem(at: root) }
        let data = try Data(contentsOf: MascotAppearance.bundled.root.appendingPathComponent("manifest.json"))
        let manifest = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        try body(root, manifest)
    }
}
