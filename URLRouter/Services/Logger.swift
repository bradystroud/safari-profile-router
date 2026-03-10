import Foundation

class Logger: ObservableObject {
    static let shared = Logger()

    static let logFileURL: URL = {
        let logsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs")
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        return logsDir.appendingPathComponent("URLRouter.log")
    }()

    @Published var entries: [LogEntry] = []

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: Level
        let message: String

        enum Level: String {
            case info = "INFO"
            case match = "MATCH"
            case noMatch = "NO_MATCH"
            case error = "ERROR"
            case route = "ROUTE"
        }

        var formatted: String {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return "[\(df.string(from: timestamp))] [\(level.rawValue)] \(message)"
        }
    }

    func log(_ level: LogEntry.Level, _ message: String) {
        let entry = LogEntry(timestamp: Date(), level: level, message: message)
        DispatchQueue.main.async {
            self.entries.append(entry)
            // Keep last 500 entries in memory
            if self.entries.count > 500 {
                self.entries.removeFirst(self.entries.count - 500)
            }
        }
        // Write to file
        let line = entry.formatted + "\n"
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: Self.logFileURL.path) {
                if let handle = try? FileHandle(forWritingTo: Self.logFileURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: Self.logFileURL)
            }
        }
    }

    func clear() {
        entries.removeAll()
        try? "".write(to: Self.logFileURL, atomically: true, encoding: .utf8)
    }
}
