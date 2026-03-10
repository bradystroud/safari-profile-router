import Foundation

struct ProfileDiscovery {
    static func availableProfiles(completion: @escaping ([String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let script = """
            tell application "Safari" to activate
            delay 0.3
            tell application "System Events"
                tell process "Safari"
                    set menuItems to name of every menu item of menu 1 of menu item "New Window" of menu 1 of menu bar item "File" of menu bar 1
                end tell
            end tell
            return menuItems
            """

            var error: NSDictionary?
            guard let appleScript = NSAppleScript(source: script) else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let result = appleScript.executeAndReturnError(&error)
            guard error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            var profiles: [String] = []
            for i in 1...result.numberOfItems {
                if let item = result.atIndex(i)?.stringValue {
                    // Menu items are like "New Personal Window"
                    let name = item
                        .replacingOccurrences(of: "New ", with: "")
                        .replacingOccurrences(of: " Window", with: "")
                    if !name.isEmpty && name != item {
                        profiles.append(name)
                    }
                }
            }

            DispatchQueue.main.async { completion(profiles) }
        }
    }
}
