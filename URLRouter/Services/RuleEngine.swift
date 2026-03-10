import Foundation

class RuleEngine: ObservableObject {
    static let shared = RuleEngine()

    @Published var rules: [Rule] = [] {
        didSet { saveRules() }
    }
    @Published var defaultProfile: String = "Personal" {
        didSet { UserDefaults.standard.set(defaultProfile, forKey: "defaultProfile") }
    }
    @Published var cachedProfiles: [String] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(cachedProfiles) {
                UserDefaults.standard.set(data, forKey: "cachedProfiles")
            }
        }
    }

    private let rulesKey = "savedRules"
    private let log = Logger.shared

    init() {
        loadRules()
        defaultProfile = UserDefaults.standard.string(forKey: "defaultProfile") ?? "Personal"
        if let data = UserDefaults.standard.data(forKey: "cachedProfiles"),
           let profiles = try? JSONDecoder().decode([String].self, from: data) {
            cachedProfiles = profiles
        }
        log.log(.info, "RuleEngine initialized with \(rules.count) rules, default profile: \(defaultProfile)")
    }

    func refreshProfiles(completion: @escaping () -> Void = {}) {
        ProfileDiscovery.availableProfiles { profiles in
            if !profiles.isEmpty {
                self.cachedProfiles = profiles
            }
            completion()
        }
    }

    func matchingProfile(for url: URL) -> String {
        log.log(.info, "Matching URL: \(url.absoluteString)")
        log.log(.info, "Testing against \(rules.filter { $0.isEnabled }.count) enabled rules")

        for (index, rule) in rules.enumerated() where rule.isEnabled {
            let matched = rule.matches(url: url)
            if matched {
                log.log(.match, "Rule #\(index + 1) MATCHED: pattern '\(rule.pattern)' -> profile '\(rule.profileName)'")
                return rule.profileName
            } else {
                log.log(.noMatch, "Rule #\(index + 1) no match: pattern '\(rule.pattern)' (host: \(url.host ?? "nil"))")
            }
        }

        log.log(.noMatch, "No rules matched, using default profile: \(defaultProfile)")
        return defaultProfile
    }

    func addRule(_ rule: Rule) {
        rules.append(rule)
        log.log(.info, "Added rule: '\(rule.pattern)' -> '\(rule.profileName)'")
    }

    func updateRule(_ rule: Rule) {
        if let idx = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[idx] = rule
            log.log(.info, "Updated rule: '\(rule.pattern)' -> '\(rule.profileName)'")
        }
    }

    func deleteRules(at offsets: IndexSet) {
        rules.remove(atOffsets: offsets)
    }

    func moveRules(from source: IndexSet, to destination: Int) {
        rules.move(fromOffsets: source, toOffset: destination)
    }

    private func saveRules() {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: rulesKey)
        }
    }

    private func loadRules() {
        guard let data = UserDefaults.standard.data(forKey: rulesKey),
              let decoded = try? JSONDecoder().decode([Rule].self, from: data) else { return }
        rules = decoded
    }
}
