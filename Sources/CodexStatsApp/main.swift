import AppKit

if CommandLine.arguments.dropFirst().first == "--check-mascot" {
    guard CommandLine.arguments.count == 3 else {
        print("Usage: codex_stats_app --check-mascot /path/to/folder")
        exit(2)
    }
    do {
        let appearance = try MascotAppearance.load(from: URL(fileURLWithPath: CommandLine.arguments[2]))
        let look = MascotLook(appearance: appearance)
        guard look.isComplete else {
            throw MascotAppearance.InvalidPackage(reason: "PNG decoding failed.")
        }
        print("Valid mascot: \(appearance.name)")
        exit(0)
    } catch {
        print("Invalid mascot: \(error.localizedDescription)")
        exit(1)
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()

application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
