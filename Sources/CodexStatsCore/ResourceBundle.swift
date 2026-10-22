import Foundation

enum ResourceBundle {
    // Packaged macOS apps seal resources under Contents/Resources; SwiftPM tests use Bundle.module.
    static let bundle: Bundle = {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("codex_stats_CodexStatsCore.bundle"),
            let bundle = Bundle(url: url)
        {
            return bundle
        }
        return Bundle.module
    }()
}
