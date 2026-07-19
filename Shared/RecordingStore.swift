import Foundation

/// Names, lists, and deletes recording files in the app's Documents directory.
/// Filenames sort chronologically because of the yyyyMMdd_HHmmss stamp.
enum RecordingStore {
    static let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    static func newFileURL(prefix: String, ext: String) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let stamp = formatter.string(from: Date())
        var url = directory.appendingPathComponent("\(prefix)_\(stamp).\(ext)")
        // Two captures inside one second must never overwrite each other: evidence.
        var n = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = directory.appendingPathComponent("\(prefix)_\(stamp)_\(n).\(ext)")
            n += 1
        }
        return url
    }

    /// Newest first, thanks to the timestamp in the name.
    static func list(prefix: String) -> [URL] {
        let all = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return all
            .filter { $0.lastPathComponent.hasPrefix(prefix + "_") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    static func delete(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
