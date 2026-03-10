import SwiftUI
import AppKit

@main
struct URLRouterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("URL Router Settings", id: "settings") {
            SettingsView()
        }
        .defaultSize(width: 600, height: 500)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.shared.log(.info, "URLRouter launched")

        // Register for URL open events
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        // Set up menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: "URL Router")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit URL Router", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc func openSettings() {
        // Open the settings window by ID
        if let url = URL(string: "urlrouter://settings") {
            NSWorkspace.shared.open(url)
        }
        // Bring app to front and show all windows
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            if window.title.contains("Settings") || window.title.contains("URL Router") {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
        // Fallback: open via SwiftUI environment action
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc func handleGetURL(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        let log = Logger.shared
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else {
            log.log(.error, "Received URL event but could not parse URL")
            return
        }

        log.log(.info, "Received URL: \(urlString)")

        let engine = RuleEngine.shared
        let profile = engine.matchingProfile(for: url)

        log.log(.route, "Routing '\(urlString)' -> profile '\(profile)'")
        SafariLauncher.open(url: url, inProfile: profile)
    }
}
