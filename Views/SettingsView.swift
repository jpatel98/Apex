import SwiftUI
import SwiftData

// Simple Authentication State
class AuthenticationState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userEmail: String?
    
    init() {
        // Check if user was previously authenticated
        isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        userEmail = UserDefaults.standard.string(forKey: "userEmail")
    }
    
    func signIn(email: String) {
        isAuthenticated = true
        userEmail = email
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(email, forKey: "userEmail")
    }
    
    func signOut() {
        isAuthenticated = false
        userEmail = nil
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @StateObject private var authState = AuthenticationState()
    
    @State private var showResetConfirmation = false
    @State private var isEditingProfile = false
    @State private var selectedSensitivity: CaffeineSensitivity = .medium
    @State private var weightInput: String = ""
    @State private var useKg = true
    @State private var notificationsEnabled = true
    @State private var alertTimeBefore = 30
    @State private var showAuthSheet = false
    @State private var showUpgradeAlert = false
    
    var currentUser: User? {
        users.first(where: { $0.isOnboarded })
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Authentication Section
                Section {
                    if !authState.isAuthenticated {
                        Button(action: {
                            showAuthSheet = true
                        }) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text("Sign In")
                                        .font(.headline)
                                    Text("Sync your data across devices")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Signed In")
                                    .font(.headline)
                                Text(authState.userEmail ?? "Unknown")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Sign Out") {
                                authState.signOut()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                }
                
                // Profile Section
                Section(header: Text("Profile")) {
                    if let user = currentUser {
                        if isEditingProfile {
                            // Edit Mode
                            HStack {
                                Label("Weight", systemImage: "scalemass")
                                Spacer()
                                TextField("Weight", text: $weightInput)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                                Picker("Unit", selection: $useKg) {
                                    Text("kg").tag(true)
                                    Text("lbs").tag(false)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 100)
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Label("How caffeine affects you", systemImage: "sparkles")
                                    .padding(.bottom, 5)
                                
                                ForEach(CaffeineSensitivity.allCases, id: \.self) { sensitivity in
                                    Button(action: {
                                        selectedSensitivity = sensitivity
                                    }) {
                                        HStack(spacing: 12) {
                                            Text(sensitivity.emoji)
                                                .font(.title3)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(sensitivity.displayName)
                                                    .font(.footnote)
                                                    .fontWeight(selectedSensitivity == sensitivity ? .semibold : .regular)
                                                    .foregroundColor(.primary)
                                                Text(sensitivity.description)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if selectedSensitivity == sensitivity {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.accentColor)
                                                    .font(.footnote)
                                            }
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedSensitivity == sensitivity ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            HStack {
                                Button("Cancel") {
                                    isEditingProfile = false
                                    loadUserData()
                                }
                                .foregroundColor(.red)
                                
                                Spacer()
                                
                                Button("Save") {
                                    saveProfileChanges()
                                }
                                .fontWeight(.semibold)
                            }
                        } else {
                            // View Mode
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
                                isEditingProfile = true
                                loadUserData()
                            }) {
                                Label("Edit Profile", systemImage: "pencil")
                            }
                        }
                        
                        Button(action: {
                            showResetConfirmation = true
                        }) {
                            Label("Reset Profile", systemImage: "arrow.clockwise")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Notifications Section
                Section(header: Text("Notifications")) {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Crash Alerts", systemImage: "bell")
                    }
                    .onChange(of: notificationsEnabled) { oldValue, newValue in
                        updateNotificationSettings()
                    }
                    
                    if notificationsEnabled {
                        VStack(alignment: .leading) {
                            Label("Alert Time", systemImage: "clock")
                            
                            Picker("Alert before crash", selection: $alertTimeBefore) {
                                Text("15 minutes").tag(15)
                                Text("30 minutes").tag(30)
                                Text("45 minutes").tag(45)
                                Text("1 hour").tag(60)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: alertTimeBefore) { oldValue, newValue in
                                updateNotificationSettings()
                            }
                        }
                    }
                }
                
                // Data Management Section
                Section(header: Text("Data Management")) {
                    if UserDefaults.isPremiumUser {
                        Button(action: exportData) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button(action: { showUpgradeAlert = true }) {
                            HStack {
                                Label("Export Data", systemImage: "square.and.arrow.up")
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    
                    Button(action: clearAllData) {
                        Label("Clear All Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // Premium Section
                if !UserDefaults.isPremiumUser {
                    Section {
                        Button(action: { showUpgradeAlert = true }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text("Upgrade to Apex Pro")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                    }
                                    
                                    Text("Unlock unlimited history, advanced analytics, and more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("$4.99/mo")
                                    .font(.headline)
                                    .foregroundColor(.accentColor)
                            }
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    Section(header: Text("Subscription")) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            
                            VStack(alignment: .leading) {
                                Text("Apex Pro")
                                    .font(.headline)
                                
                                Text("Active subscription")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Manage") {
                                // Open App Store subscription management
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption)
                        }
                    }
                }
                
                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/jpatel98/Apex")!) {
                        HStack {
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/jpatel98/Apex/blob/main/docs/METHODOLOGY.md")!) {
                        HStack {
                            Text("Methodology")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
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
            .sheet(isPresented: $showAuthSheet) {
                AuthenticationView(authState: authState)
            }
            .alert("Upgrade to Pro", isPresented: $showUpgradeAlert) {
                Button("Upgrade ($4.99/mo)") {
                    // Simulate upgrade
                    UserDefaults.isPremiumUser = true
                }
                Button("Maybe Later", role: .cancel) { }
            } message: {
                Text("Unlock unlimited history, data export, and advanced features.")
            }
            .onAppear {
                loadUserData()
            }
        }
    }
    
    private func loadUserData() {
        guard let user = currentUser else { return }
        selectedSensitivity = user.sensitivity
        weightInput = String(Int(user.weightKg))
        useKg = true
    }
    
    private func saveProfileChanges() {
        guard let user = currentUser else { return }
        
        if let weight = Double(weightInput) {
            if useKg {
                user.weightKg = weight
            } else {
                // Convert lbs to kg
                user.weightKg = weight * 0.453592
            }
        }
        
        user.sensitivity = selectedSensitivity
        
        do {
            try modelContext.save()
            isEditingProfile = false
        } catch {
            print("Failed to save profile changes: \(error)")
        }
    }
    
    private func updateNotificationSettings() {
        // Update notification settings in NotificationManager
        NotificationManager.shared.requestPermission()
    }
    
    private func exportData() {
        // TODO: Implement data export functionality
        print("Export data functionality to be implemented")
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
    
    private func sensitivityDescription(_ sensitivity: CaffeineSensitivity) -> String {
        return ""  // Description is now in the model
    }
}

// Authentication View
struct AuthenticationView: View {
    @ObservedObject var authState: AuthenticationState
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo
                Image(systemName: "bolt.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 20) {
                    // Email Field
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Password Field
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)
                        SecureField("Password", text: $password)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Auth Button
                Button(action: authenticate) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .disabled(isLoading)
                
                // Toggle Sign In/Up
                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func authenticate() {
        // Basic validation
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        if !email.contains("@") || !email.contains(".") {
            errorMessage = "Please enter a valid email"
            showError = true
            return
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }
        
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            
            // For demo purposes, we'll accept any valid email/password
            authState.signIn(email: email)
            dismiss()
        }
    }
}