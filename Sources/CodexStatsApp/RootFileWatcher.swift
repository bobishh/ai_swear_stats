import CoreServices
import Foundation

struct RootFileChange: Sendable {
    let paths: [URL]
    let requiresFullScan: Bool
}

@MainActor
final class RootFileWatcher {
    static let eventName = Notification.Name("RootFileWatcherDidChange")

    private var stream: FSEventStreamRef?
    private var rootPaths: [String] = []

    func watch(_ roots: [URL]) {
        let normalized = roots.map { $0.standardizedFileURL.resolvingSymlinksInPath() }
            .filter { url in
                var isDirectory = ObjCBool(false)
                return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                    && isDirectory.boolValue && FileManager.default.isReadableFile(atPath: url.path)
            }
            .map(\.path)
            .sorted()
        guard normalized != rootPaths else { return }
        stop()
        guard !normalized.isEmpty else { return }
        var context = FSEventStreamContext()
        let callback: FSEventStreamCallback = { _, _, count, eventPaths, eventFlags, _ in
            let rawPaths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as NSArray
            let paths = rawPaths.compactMap { value -> String? in
                if let path = value as? String { return path }
                if let url = value as? URL { return url.path }
                return nil
            }
            let flags = UnsafeBufferPointer(start: eventFlags, count: Int(count))
            let requiresFullScan = flags.contains {
                $0
                    & (UInt32(kFSEventStreamEventFlagMustScanSubDirs) | UInt32(kFSEventStreamEventFlagUserDropped)
                        | UInt32(kFSEventStreamEventFlagKernelDropped) | UInt32(kFSEventStreamEventFlagRootChanged))
                    != 0
            }
            NotificationCenter.default.post(
                name: RootFileWatcher.eventName,
                object: RootFileChange(
                    paths: paths.map { URL(fileURLWithPath: $0) }, requiresFullScan: requiresFullScan))
        }
        let watched = normalized as CFArray
        guard
            let newStream = FSEventStreamCreate(
                kCFAllocatorDefault, callback, &context, watched, FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                0.15,
                FSEventStreamCreateFlags(
                    kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer
                        | kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagWatchRoot))
        else { return }
        FSEventStreamSetDispatchQueue(newStream, DispatchQueue.main)
        guard FSEventStreamStart(newStream) else {
            FSEventStreamInvalidate(newStream)
            FSEventStreamRelease(newStream)
            return
        }
        stream = newStream
        rootPaths = normalized
    }

    func stop() {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
        rootPaths = []
    }
}
