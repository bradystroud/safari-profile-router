import Foundation
import AppKit

struct SafariLauncher {
    static func open(url: URL, inProfile profileName: String) {
        let log = Logger.shared
        log.log(.route, "Opening '\(url.absoluteString)' in profile '\(profileName)'")

        let escapedURL = url.absoluteString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let escapedProfile = profileName
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Safari" to activate
        delay 0.3

        tell application "Safari"
            set profileFound to false
            repeat with w in windows
                try
                    if name of w starts with "\(escapedProfile) \u{2014}" or name of w is "\(escapedProfile)" then
                        set profileFound to true
                        set current tab of w to (make new tab in w with properties {URL:"\(escapedURL)"})
                        set index of w to 1
                        exit repeat
                    end if
                end try
            end repeat
        end tell

        if not profileFound then
            tell application "System Events"
                tell process "Safari"
                    click menu item "New \(escapedProfile) Window" of menu 1 of menu item "New Window" of menu 1 of menu bar item "File" of menu bar 1
                end tell
            end tell
            delay 0.5
            tell application "Safari"
                set URL of current tab of front window to "\(escapedURL)"
            end tell
        end if
        """

        log.log(.info, "Executing AppleScript via osascript...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorString = String(data: errorData, encoding: .utf8) ?? "unknown error"
                log.log(.error, "osascript failed (exit \(process.terminationStatus)): \(errorString)")
                log.log(.route, "Falling back to opening directly in Safari (default profile)")
                openDirectlyInSafari(url: url)
            } else {
                log.log(.route, "Successfully opened in profile '\(profileName)'")
            }
        } catch {
            log.log(.error, "Failed to launch osascript: \(error.localizedDescription)")
            log.log(.route, "Falling back to opening directly in Safari (default profile)")
            openDirectlyInSafari(url: url)
        }
    }

    /// Opens a URL directly in Safari by bundle identifier, bypassing the default browser
    private static func openDirectlyInSafari(url: URL) {
        let config = NSWorkspace.OpenConfiguration()
        let safariURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari")
        if let safariURL = safariURL {
            NSWorkspace.shared.open([url], withApplicationAt: safariURL, configuration: config)
        }
    }
}
