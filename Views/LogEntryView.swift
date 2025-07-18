import SwiftUI
import SwiftData

struct LogEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    @Query private var allEntries: [CaffeineEntry]
    
    @State private var currentStep = 0
    @State private var selectedDrink: String = ""
    @State private var caffeineAmount: Double = 0
    @State private var customDrinkName = ""
    @State private var customCaffeineAmount = ""
    @State private var selectedHour = Calendar.current.component(.hour, from: Date())
    @State private var selectedMinute = Calendar.current.component(.minute, from: Date())
    @State private var isToday = true
    @State private var showSuccessAnimation = false
    
    var currentUser: User? {
        users.first(where: { $0.isOnboarded })
    }
    
    let drinkEmojis = [
        "Coffee": "☕",
        "Espresso": "☕",
        "Black Tea": "🍵",
        "Green Tea": "🍵",
        "Energy Drink": "⚡",
        "Soda": "🥤",
        "Custom": "✨"
    ]
    
    let drinkColors = [
        "Coffee": Color.brown,
        "Espresso": Color.brown.opacity(0.8),
        "Black Tea": Color.orange,
        "Green Tea": Color.green,
        "Energy Drink": Color.blue,
        "Soda": Color.purple,
        "Custom": Color.pink
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(index <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: currentStep)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Question content
                    VStack(spacing: 40) {
                        if currentStep == 0 {
                            drinkSelectionView
                        } else if currentStep == 1 {
                            caffeineAmountView
                        } else if currentStep == 2 {
                            timeSelectionView
                        } else if currentStep == 3 {
                            confirmationView
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        if currentStep > 0 {
                            Button(action: { 
                                withAnimation(.spring()) {
                                    currentStep -= 1
                                }
                            }) {
                                Text("Back")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .frame(width: 100, height: 50)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(25)
                            }
                        }
                        
                        Button(action: handleNextAction) {
                            Text(currentStep == 3 ? "Log It!" : "Next")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: currentStep == 3 ? 200 : 100, height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                        }
                        .disabled(!canProceed)
                        .opacity(canProceed ? 1 : 0.5)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Log Caffeine")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(
                Group {
                    if showSuccessAnimation {
                        SuccessAnimation()
                    }
                }
            )
        }
    }
    
    var drinkSelectionView: some View {
        VStack(spacing: 25) {
            Text("What did you drink?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(DrinkPreset.presets, id: \.name) { preset in
                    DrinkButton(
                        name: preset.name,
                        emoji: drinkEmojis[preset.name] ?? "🥤",
                        color: drinkColors[preset.name] ?? .blue,
                        isSelected: selectedDrink == preset.name,
                        caffeineAmount: preset.caffeineAmountMg
                    ) {
                        withAnimation(.spring()) {
                            selectedDrink = preset.name
                            caffeineAmount = preset.caffeineAmountMg
                        }
                    }
                }
                
                // Custom drink option
                DrinkButton(
                    name: "Custom",
                    emoji: "✨",
                    color: Color.pink,
                    isSelected: selectedDrink == "Custom",
                    caffeineAmount: 0
                ) {
                    withAnimation(.spring()) {
                        selectedDrink = "Custom"
                    }
                }
            }
        }
    }
    
    var caffeineAmountView: some View {
        VStack(spacing: 25) {
            Text(selectedDrink == "Custom" ? "Tell me about your drink" : "Confirm the caffeine")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            if selectedDrink == "Custom" {
                VStack(spacing: 20) {
                    TextField("Drink name", text: $customDrinkName)
                        .font(.title2)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Caffeine amount")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("0", text: $customCaffeineAmount)
                                .font(.title)
                                .keyboardType(.numberPad)
                                .frame(width: 100)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(15)
                            
                            Text("mg")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                VStack(spacing: 30) {
                    Text("\(drinkEmojis[selectedDrink] ?? "☕")")
                        .font(.system(size: 80))
                    
                    Text("\(Int(caffeineAmount)) mg")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(drinkColors[selectedDrink] ?? .blue)
                    
                    Text("of caffeine")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    var timeSelectionView: some View {
        VStack(spacing: 25) {
            Text("When did you have it?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                // Today/Yesterday toggle
                HStack(spacing: 0) {
                    Button(action: { isToday = true }) {
                        Text("Today")
                            .font(.headline)
                            .foregroundColor(isToday ? .white : .gray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isToday ? Color.accentColor : Color.clear)
                    }
                    
                    Button(action: { isToday = false }) {
                        Text("Yesterday")
                            .font(.headline)
                            .foregroundColor(!isToday ? .white : .gray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(!isToday ? Color.accentColor : Color.clear)
                    }
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(25)
                
                // Time picker
                HStack(spacing: 20) {
                    // Hour picker
                    VStack {
                        Text("Hour")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Hour", selection: $selectedHour) {
                            ForEach(0..<24) { hour in
                                Text(String(format: "%02d", hour))
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 120)
                        .clipped()
                    }
                    
                    Text(":")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Minute picker
                    VStack {
                        Text("Minute")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Minute", selection: $selectedMinute) {
                            ForEach(0..<60) { minute in
                                Text(String(format: "%02d", minute))
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 120)
                        .clipped()
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            }
        }
    }
    
    var confirmationView: some View {
        VStack(spacing: 30) {
            Text("Ready to log!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 20) {
                HStack {
                    Text(drinkEmojis[selectedDrink == "Custom" ? "Custom" : selectedDrink] ?? "☕")
                        .font(.system(size: 60))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(selectedDrink == "Custom" ? customDrinkName : selectedDrink)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("\(Int(selectedDrink == "Custom" ? Double(customCaffeineAmount) ?? 0 : caffeineAmount)) mg caffeine")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(drinkColors[selectedDrink == "Custom" ? "Custom" : selectedDrink]?.opacity(0.1) ?? Color.blue.opacity(0.1))
                )
                
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("\(isToday ? "Today" : "Yesterday") at \(String(format: "%02d:%02d", selectedHour, selectedMinute))")
                        .font(.headline)
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.1))
                )
            }
        }
    }
    
    var canProceed: Bool {
        switch currentStep {
        case 0:
            return !selectedDrink.isEmpty
        case 1:
            if selectedDrink == "Custom" {
                return !customDrinkName.isEmpty && Double(customCaffeineAmount) != nil && Double(customCaffeineAmount)! > 0
            }
            return true
        case 2:
            return true
        case 3:
            return true
        default:
            return false
        }
    }
    
    func handleNextAction() {
        if currentStep < 3 {
            withAnimation(.spring()) {
                currentStep += 1
            }
        } else {
            logEntry()
        }
    }
    
    private func logEntry() {
        guard currentUser != nil else { return }
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = selectedHour
        components.minute = selectedMinute
        
        var date = Date()
        if !isToday {
            date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }
        
        date = calendar.date(bySettingHour: selectedHour, minute: selectedMinute, second: 0, of: date) ?? date
        
        let entry: CaffeineEntry
        
        if selectedDrink == "Custom" {
            guard let amount = Double(customCaffeineAmount) else { return }
            entry = CaffeineEntry(drinkName: customDrinkName, caffeineAmountMg: amount, timestamp: date)
        } else {
            entry = CaffeineEntry(drinkName: selectedDrink, caffeineAmountMg: caffeineAmount, timestamp: date)
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
                dismiss()
            }
        } catch {
            print("Failed to save entry: \(error)")
        }
    }
}

struct DrinkButton: View {
    let name: String
    let emoji: String
    let color: Color
    let isSelected: Bool
    let caffeineAmount: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 40))
                
                Text(name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                if caffeineAmount > 0 {
                    Text("\(Int(caffeineAmount))mg")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 3)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SuccessAnimation: View {
    @State private var scale = 0.5
    @State private var opacity = 1.0
    @State private var rotation = 0.0
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 150, height: 150)
                    .scaleEffect(scale * 1.5)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
            }
            
            Text("Logged!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .opacity(opacity)
                .offset(y: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                rotation = 360
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0.0
                }
            }
        }
    }
}