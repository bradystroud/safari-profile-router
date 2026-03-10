import Foundation

struct Rule: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var pattern: String
    var profileName: String
    var isEnabled: Bool = true

    func matches(url: URL) -> Bool {
        guard isEnabled else { return false }
        let urlString = url.absoluteString.lowercased()
        let host = url.host?.lowercased() ?? ""
        let loweredPattern = pattern.lowercased()

        // If pattern contains "/" treat it as a full URL match, otherwise host-only
        if loweredPattern.contains("/") {
            return matchesGlob(string: urlString, pattern: loweredPattern)
        } else {
            return matchesGlob(string: host, pattern: loweredPattern)
        }
    }

    private func matchesGlob(string: String, pattern: String) -> Bool {
        let predicate = NSPredicate(format: "SELF LIKE %@", pattern)
        return predicate.evaluate(with: string)
    }
}
