import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSensitivity: CaffeineSensitivity = .medium
    @State private var weightInput: String = "70"
    @State private var useKg = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Welcome to Apex")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Let's personalize your caffeine tracking")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Body Weight", systemImage: "scalemass")
                            .font(.headline)
                        
                        HStack {
                            TextField("Weight", text: $weightInput)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                            
                            Picker("Unit", selection: $useKg) {
                                Text("kg").tag(true)
                                Text("lbs").tag(false)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 100)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Caffeine Sensitivity", systemImage: "gauge")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(CaffeineSensitivity.allCases, id: \.self) { sensitivity in
                                Button(action: {
                                    selectedSensitivity = sensitivity
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(sensitivity.displayName)
                                                .font(.body)
                                                .fontWeight(selectedSensitivity == sensitivity ? .semibold : .regular)
                                            Text("Half-life: \(Int(sensitivity.halfLifeHours)) hours")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedSensitivity == sensitivity {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedSensitivity == sensitivity ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: saveProfile) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func saveProfile() {
        guard let weight = Double(weightInput), weight > 0 else { return }
        
        let weightInKg = useKg ? weight : weight / 2.20462
        
        let user = User(weightKg: weightInKg, sensitivity: selectedSensitivity)
        user.isOnboarded = true
        
        modelContext.insert(user)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save user profile: \(error)")
        }
    }
}