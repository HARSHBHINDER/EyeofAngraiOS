import Foundation

enum RecordingStore {
    static let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    private static let stampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func newFileURL(prefix: String, ext: String) -> URL {
        let stamp = stampFormatter.string(from: Date())
        var url = directory.appendingPathComponent("\(prefix)_\(stamp).\(ext)")
        // Two captures inside one second must never overwrite each other: evidence.
        var n = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = directory.appendingPathComponent("\(prefix)_\(stamp)_\(n).\(ext)")
            n += 1
        }
        return url
    }

    static func list(prefix: String) -> [URL] {
        let all = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return all
            .filter { $0.lastPathComponent.hasPrefix(prefix + "_") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    static func delete(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    static func size(of url: URL) -> Int64 {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { Int64($0) } ?? 0
    }

    static var usedBytes: Int64 {
        let all = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return all.reduce(0) { $0 + size(of: $1) }
    }

    static var freeBytes: Int64 {
        (try? directory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            .volumeAvailableCapacityForImportantUsage) ?? 0
    }

    static func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
