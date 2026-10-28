// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "codex_stats",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CodexStatsCore",
            targets: ["CodexStatsCore"]
        ),
        .executable(
            name: "codex_stats_app",
            targets: ["CodexStatsApp"]
        ),
    ],
    targets: [
        .systemLibrary(name: "CSQLite"),
        .target(name: "CSnowball", path: "Sources/CSnowball"),
        .target(
            name: "CodexStatsCore",
            dependencies: ["CSQLite", "CSnowball"],
            path: "Sources/CodexStatsCore",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "CodexStatsApp",
            dependencies: ["CodexStatsCore"],
            path: "Sources/CodexStatsApp",
            resources: [.copy("Resources/Mascot"), .copy("Resources/Brand")]
        ),
        .testTarget(
            name: "CodexStatsAppTests",
            dependencies: ["CodexStatsApp"],
            path: "Tests/CodexStatsAppTests"
        ),
        .testTarget(
            name: "CodexStatsCoreTests",
            dependencies: ["CodexStatsCore"],
            path: "Tests/CodexStatsCoreTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
