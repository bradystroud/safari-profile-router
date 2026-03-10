import SwiftUI

struct RuleEditorView: View {
    let availableProfiles: [String]
    let onSave: (Rule) -> Void
    var editingRule: Rule? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var pattern = ""
    @State private var profileName = ""

    var isEditing: Bool { editingRule != nil }

    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? "Edit Rule" : "Add Rule")
                .font(.headline)

            Form {
                TextField("URL Pattern", text: $pattern)
                    .textFieldStyle(.roundedBorder)

                Text("Examples: *.github.com, *jira*, mail.google.com")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if availableProfiles.isEmpty {
                    TextField("Safari Profile Name", text: $profileName)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Picker("Safari Profile", selection: $profileName) {
                        Text("Select...").tag("")
                        ForEach(availableProfiles, id: \.self) { profile in
                            Text(profile).tag(profile)
                        }
                    }
                }
            }
            .padding(.horizontal)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isEditing ? "Save" : "Add") {
                    var rule = editingRule ?? Rule(pattern: pattern, profileName: profileName)
                    rule.pattern = pattern
                    rule.profileName = profileName
                    onSave(rule)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(pattern.isEmpty || profileName.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 400, height: 250)
        .onAppear {
            if let rule = editingRule {
                pattern = rule.pattern
                profileName = rule.profileName
            }
        }
    }
}
