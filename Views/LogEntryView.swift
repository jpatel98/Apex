import SwiftUI
import SwiftData

struct LogEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    @Query private var allEntries: [CaffeineEntry]
    
    @State private var selectedPreset: DrinkPreset?
    @State private var customDrinkName = ""
    @State private var customCaffeineAmount = ""
    @State private var selectedTime = Date()
    @State private var showCustomEntry = false
    @State private var showSuccessAnimation = false
    
    var currentUser: User? {
        users.first(where: { $0.isOnboarded })
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Add")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(DrinkPreset.presets, id: \.name) { preset in
                                PresetButton(preset: preset, isSelected: selectedPreset?.name == preset.name) {
                                    selectedPreset = preset
                                    showCustomEntry = false
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button(action: {
                        showCustomEntry = true
                        selectedPreset = nil
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Custom Drink")
                        }
                        .font(.headline)
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.accentColor, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal)
                    
                    if showCustomEntry {
                        VStack(alignment: .leading, spacing: 15) {
                            TextField("Drink name", text: $customDrinkName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            HStack {
                                TextField("Caffeine amount", text: $customCaffeineAmount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Text("mg")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Time", systemImage: "clock")
                            .font(.headline)
                        
                        DatePicker("", selection: $selectedTime, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .frame(height: 300)
                    }
                    .padding(.horizontal)
                    
                    Button(action: logEntry) {
                        Text("Log Caffeine")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canLog ? Color.accentColor : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!canLog)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Log Caffeine")
            .navigationBarTitleDisplayMode(.large)
            .overlay(
                Group {
                    if showSuccessAnimation {
                        SuccessAnimation()
                    }
                }
            )
        }
    }
    
    var canLog: Bool {
        if showCustomEntry {
            return !customDrinkName.isEmpty && Double(customCaffeineAmount) != nil && Double(customCaffeineAmount)! > 0
        } else {
            return selectedPreset != nil
        }
    }
    
    private func logEntry() {
        guard currentUser != nil else { return }
        
        let entry: CaffeineEntry
        
        if showCustomEntry {
            guard let amount = Double(customCaffeineAmount) else { return }
            entry = CaffeineEntry(drinkName: customDrinkName, caffeineAmountMg: amount, timestamp: selectedTime)
        } else if let preset = selectedPreset {
            entry = CaffeineEntry(drinkName: preset.name, caffeineAmountMg: preset.caffeineAmountMg, timestamp: selectedTime)
        } else {
            return
        }
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            
            if let user = currentUser {
                let recentEntries = CaffeineCalculator.getRecentEntries(allEntries, within: 24)
                NotificationManager.shared.updateCrashAlert(entries: recentEntries, sensitivity: user.sensitivity)
            }
            
            withAnimation(.spring()) {
                showSuccessAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSuccessAnimation = false
                resetForm()
            }
        } catch {
            print("Failed to save entry: \(error)")
        }
    }
    
    private func resetForm() {
        selectedPreset = nil
        customDrinkName = ""
        customCaffeineAmount = ""
        showCustomEntry = false
        selectedTime = Date()
    }
}

struct PresetButton: View {
    let preset: DrinkPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: preset.icon)
                    .font(.system(size: 30))
                
                Text(preset.name)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                
                Text("\(Int(preset.caffeineAmountMg))mg")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SuccessAnimation: View {
    @State private var scale = 0.5
    @State private var opacity = 1.0
    
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .onAppear {
            withAnimation(.spring()) {
                scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0.0
                }
            }
        }
    }
}