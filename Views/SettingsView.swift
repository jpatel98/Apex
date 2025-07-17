import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    @State private var showResetConfirmation = false
    @State private var selectedSensitivity: CaffeineSensitivity = .medium
    @State private var weightInput: String = ""
    @State private var useKg = true
    
    var currentUser: User? {
        users.first(where: { $0.isOnboarded })
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    if let user = currentUser {
                        HStack {
                            Label("Weight", systemImage: "scalemass")
                            Spacer()
                            Text("\(Int(user.weightKg)) kg")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Sensitivity", systemImage: "gauge")
                            Spacer()
                            Text(user.sensitivity.displayName)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            showResetConfirmation = true
                        }) {
                            Label("Reset Profile", systemImage: "arrow.clockwise")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Notifications")) {
                    Toggle(isOn: .constant(true)) {
                        Label("Crash Alerts", systemImage: "bell")
                    }
                    
                    HStack {
                        Label("Alert Time", systemImage: "clock")
                        Spacer()
                        Text("30 min before")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(action: clearAllData) {
                        Text("Clear All Data")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog("Reset Profile", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) {
                    resetProfile()
                }
            } message: {
                Text("This will reset your profile settings. Your caffeine history will be preserved.")
            }
        }
    }
    
    private func resetProfile() {
        guard let user = currentUser else { return }
        user.isOnboarded = false
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to reset profile: \(error)")
        }
    }
    
    private func clearAllData() {
        do {
            try modelContext.delete(model: User.self)
            try modelContext.delete(model: CaffeineEntry.self)
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}