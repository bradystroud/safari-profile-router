import SwiftUI

struct LogView: View {
    @ObservedObject var logger = Logger.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(logger.entries.count) log entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("File: ~/Library/Logs/URLRouter.log")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
                Spacer()
                Button("Clear") {
                    logger.clear()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if logger.entries.isEmpty {
                VStack {
                    Spacer()
                    Text("No log entries yet")
                        .foregroundColor(.secondary)
                    Text("Open a URL to see routing logs here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    List(logger.entries) { entry in
                        LogEntryRow(entry: entry)
                            .id(entry.id)
                    }
                    .onChange(of: logger.entries.count) {
                        if let last = logger.entries.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

struct LogEntryRow: View {
    let entry: Logger.LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            levelBadge
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.message)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                Text(timeString)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var levelBadge: some View {
        Text(entry.level.rawValue)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(levelColor.opacity(0.2))
            .foregroundColor(levelColor)
            .cornerRadius(3)
    }

    private var levelColor: Color {
        switch entry.level {
        case .info: return .blue
        case .match: return .green
        case .noMatch: return .orange
        case .error: return .red
        case .route: return .purple
        }
    }

    private var timeString: String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return df.string(from: entry.timestamp)
    }
}
