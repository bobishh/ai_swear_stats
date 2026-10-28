import AppKit
import Foundation

@MainActor
enum AppResources {
    private static let packagedBundle: Bundle? = {
        guard let resourcesURL = Bundle.main.resourceURL else { return nil }
        return Bundle(url: resourcesURL.appendingPathComponent("codex_stats_CodexStatsApp.bundle"))
    }()
    static let sidebarLogo = image(named: "swear-stats", subdirectory: "Brand")

    static func image(named name: String, subdirectory: String) -> NSImage? {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: subdirectory)
                ?? packagedBundle?.url(forResource: name, withExtension: "png", subdirectory: subdirectory)
                ?? Bundle.module.url(forResource: name, withExtension: "png", subdirectory: subdirectory)
        else { return nil }
        return NSImage(contentsOf: url)
    }
}
