import SwiftUI

struct SettingsView: View {
    @ObservedObject var engine = RuleEngine.shared
    @State private var isLoadingProfiles = false
    @State private var showingAddRule = false
    @State private var editingRule: Rule? = nil
    @State private var selectedTab = "rules"

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("URL Router")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Set as Default Browser") {
                    setAsDefaultBrowser()
                }
            }
            .padding()

            Divider()

            // Tabs
            TabView(selection: $selectedTab) {
                rulesTab
                    .tabItem { Label("Rules", systemImage: "list.bullet") }
                    .tag("rules")

                LogView()
                    .tabItem { Label("Logs", systemImage: "doc.text") }
                    .tag("logs")
            }
        }
        .frame(width: 700, height: 550)
        .onAppear { loadProfiles() }
        .sheet(isPresented: $showingAddRule) {
            RuleEditorView(availableProfiles: engine.cachedProfiles) { rule in
                engine.addRule(rule)
            }
        }
        .sheet(item: $editingRule) { rule in
            RuleEditorView(availableProfiles: engine.cachedProfiles, onSave: { updated in
                engine.updateRule(updated)
            }, editingRule: rule)
        }
    }

    private var rulesTab: some View {
        VStack(spacing: 0) {
            // Default profile
            HStack {
                Text("Default Profile:")
                    .fontWeight(.medium)
                if engine.cachedProfiles.isEmpty {
                    TextField("Profile name", text: $engine.defaultProfile)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                } else {
                    Picker("", selection: $engine.defaultProfile) {
                        ForEach(engine.cachedProfiles, id: \.self) { profile in
                            Text(profile).tag(profile)
                        }
                    }
                    .frame(width: 200)
                }
                Spacer()
                Button("Refresh Profiles") {
                    loadProfiles()
                }
                .disabled(isLoadingProfiles)
            }
            .padding()

            Divider()

            // Rules list
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Rules")
                        .font(.headline)
                    Text("(matched top to bottom)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { showingAddRule = true }) {
                        Label("Add Rule", systemImage: "plus")
                    }
                }

                if engine.rules.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Text("No rules configured")
                            .foregroundColor(.secondary)
                        Text("Add rules to route URLs to specific Safari profiles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(engine.rules) { rule in
                            RuleRowView(rule: rule, engine: engine)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingRule = rule
                                }
                        }
                        .onDelete(perform: engine.deleteRules)
                        .onMove(perform: engine.moveRules)
                    }
                }
            }
            .padding()
        }
    }

    private func loadProfiles() {
        isLoadingProfiles = true
        engine.refreshProfiles {
            isLoadingProfiles = false
        }
    }

    private func setAsDefaultBrowser() {
        if let bundleID = Bundle.main.bundleIdentifier {
            LSSetDefaultHandlerForURLScheme("http" as CFString, bundleID as CFString)
            LSSetDefaultHandlerForURLScheme("https" as CFString, bundleID as CFString)
        }
    }
}

struct RuleRowView: View {
    let rule: Rule
    let engine: RuleEngine

    var body: some View {
        HStack {
            Image(systemName: rule.isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(rule.isEnabled ? .green : .secondary)
                .onTapGesture {
                    if let idx = engine.rules.firstIndex(where: { $0.id == rule.id }) {
                        engine.rules[idx].isEnabled.toggle()
                    }
                }

            VStack(alignment: .leading) {
                Text(rule.pattern)
                    .font(.system(.body, design: .monospaced))
                Text(rule.profileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}
