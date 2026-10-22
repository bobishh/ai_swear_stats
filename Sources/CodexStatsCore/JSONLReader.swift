import Foundation

struct JSONLReadResult {
    let offset: UInt64
    let bytesRead: Int
}

/// Reads a stable file-size snapshot, committing only newline-terminated records.
struct JSONLReader {
    func read(url: URL, offset: UInt64, size: UInt64, line: (Data, UInt64) throws -> Void) throws -> JSONLReadResult {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        try handle.seek(toOffset: offset)
        var buffer = Data()
        var committed = offset
        var bytesRead = 0
        while UInt64(bytesRead) + offset < size {
            try Task.checkCancellation()
            let count = Int(min(1_048_576, size - offset - UInt64(bytesRead)))
            guard let chunk = try handle.read(upToCount: count), !chunk.isEmpty else { break }
            bytesRead += chunk.count
            buffer.append(chunk)
            let consumed = try consume(buffer, start: committed, line: line)
            buffer.removeFirst(consumed)
            committed += UInt64(consumed)
        }
        return JSONLReadResult(offset: committed, bytesRead: bytesRead)
    }

    private func consume(_ buffer: Data, start: UInt64, line: (Data, UInt64) throws -> Void) throws -> Int {
        try buffer.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            guard let base = bytes.baseAddress else { return 0 }
            var consumed = 0
            while consumed < bytes.count, let newline = memchr(base.advanced(by: consumed), 10, bytes.count - consumed)
            {
                let length = base.advanced(by: consumed).distance(to: UnsafeRawPointer(newline))
                if length > 0 {
                    let data = Data(
                        bytesNoCopy: UnsafeMutableRawPointer(mutating: base.advanced(by: consumed)), count: length,
                        deallocator: .none)
                    try line(data, start + UInt64(consumed))
                }
                consumed += length + 1
            }
            return consumed
        }
    }
}
