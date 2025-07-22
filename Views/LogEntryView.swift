import SwiftUI
import SwiftData

struct LogEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    @Query private var allEntries: [CaffeineEntry]
    
    @Binding var selectedTab: Int
    
    @State private var currentStep = 0
    @State private var selectedDrink: String = ""
    @State private var caffeineAmount: Double = 0
    @State private var customDrinkName = ""
    @State private var customCaffeineAmount = ""
    @State private var selectedHour = Calendar.current.component(.hour, from: Date())
    @State private var selectedMinute = Calendar.current.component(.minute, from: Date())
    @State private var isToday = true
    @State private var showSuccessAnimation = false
    @State private var stepOpacity = 1.0
    @State private var stepOffset: CGFloat = 0
    
    var currentUser: User? {
        users.first(where: { $0.isOnboarded })
    }
    
    var currentDailyTotal: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayEntries = allEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
        return todayEntries.reduce(0) { $0 + $1.caffeineAmountMg }
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
                    colors: [Color.blue, Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                    .opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Progress indicator with better styling
                    HStack(spacing: 12) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(index == currentStep ? Color.accentColor : Color.gray.opacity(0.2))
                                .frame(width: index == currentStep ? 10 : 8, height: index == currentStep ? 10 : 8)
                                .scaleEffect(index == currentStep ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)
                        }
                    }
                    .padding(.top, 16)
                    
                    // Question content
                    VStack(spacing: 32) {
                        if currentStep == 0 {
                            drinkSelectionView
                        } else if currentStep == 1 {
                            caffeineAmountView
                        } else if currentStep == 2 {
                            timeSelectionView
                        } else if currentStep == 3 {
                            VStack(spacing: 20) {
                                confirmationView
                                
                                // Safety warning before logging
                                if let user = currentUser {
                                    LogSafetyWarning(
                                        plannedAmount: selectedDrink == "Custom" ? (Double(customCaffeineAmount) ?? 0) : caffeineAmount,
                                        currentDailyTotal: currentDailyTotal,
                                        userWeight: user.weightKg
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .opacity(stepOpacity)
                    .offset(x: stepOffset)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                    
                    Spacer()
                    
                    // Navigation buttons
                    VStack(spacing: 12) {
                        // Main action button
                        Button(action: handleNextAction) {
                            HStack {
                                Text(currentStep == 3 ? "Log It!" : "Next")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                if currentStep < 3 {
                                    Image(systemName: "chevron.right")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(22)
                            .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .disabled(!canProceed)
                        .opacity(canProceed ? 1 : 0.5)
                        .scaleEffect(canProceed ? 1 : 0.95)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canProceed)
                        
                        // Back button
                        if currentStep > 0 {
                            Button(action: { 
                                withAnimation(.spring()) {
                                    currentStep -= 1
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                    Text("Back")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.secondary)
                                .frame(height: 40)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(.systemGray6))
                                        .shadow(color: Color.black.opacity(0.03), radius: 2, y: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 120 : 100)
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
                .onAppear {
                    // Reset form each time view appears
                    if !showSuccessAnimation {
                        resetForm()
                    }
                }
            }
        }
    }
    
    var drinkSelectionView: some View {
        VStack(spacing: 20) {
            Text("What did you drink?")
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primary, Color.primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            LazyVGrid(
                columns: UIDevice.current.userInterfaceIdiom == .pad ? 
                    [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())] :
                    [GridItem(.flexible()), GridItem(.flexible())], 
                spacing: 15
            ) {
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
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primary, Color.primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            if selectedDrink == "Custom" {
                VStack(spacing: 20) {
                    TextField("Drink name", text: $customDrinkName)
                        .font(.title2)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .shadow(color: Color.black.opacity(0.03), radius: 2, y: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Caffeine amount")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("0", text: $customCaffeineAmount)
                                .font(.title)
                                .keyboardType(.numberPad)
                                .frame(width: 100)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .shadow(color: Color.black.opacity(0.03), radius: 2, y: 1)
                                )
                            
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
                    
                    VStack(spacing: 15) {
                        HStack {
                            TextField("\(Int(caffeineAmount))", value: $caffeineAmount, format: .number)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(drinkColors[selectedDrink] ?? .blue)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 120)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(drinkColors[selectedDrink]?.opacity(0.3) ?? Color.blue.opacity(0.3), lineWidth: 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(drinkColors[selectedDrink]?.opacity(0.05) ?? Color.blue.opacity(0.05))
                                        )
                                )
                            
                            Text("mg")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Tap to adjust")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
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
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primary, Color.primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
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
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primary, Color.primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
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
        let feedback = UISelectionFeedbackGenerator()
        feedback.selectionChanged()
        
        if currentStep < 3 {
            // Animate out current step
            withAnimation(.easeInOut(duration: 0.2)) {
                stepOpacity = 0
                stepOffset = -30
            }
            
            // Wait then animate in next step
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                currentStep += 1
                stepOffset = 30
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    stepOpacity = 1
                    stepOffset = 0
                }
            }
        } else {
            logEntry()
        }
    }
    
    func handlePreviousAction() {
        guard currentStep > 0 else { return }
        
        let feedback = UISelectionFeedbackGenerator()
        feedback.selectionChanged()
        
        // Animate out current step
        withAnimation(.easeInOut(duration: 0.2)) {
            stepOpacity = 0
            stepOffset = 30
        }
        
        // Wait then animate in previous step
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentStep -= 1
            stepOffset = -30
            
            withAnimation(.easeInOut(duration: 0.3)) {
                stepOpacity = 1
                stepOffset = 0
            }
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
            
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showSuccessAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSuccessAnimation = false
                // Reset state before switching tabs
                resetForm()
                withAnimation(.spring()) {
                    selectedTab = 0 // Switch to dashboard
                }
            }
        } catch {
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.error)
            // TODO: Show error alert to user
            print("Failed to save entry: \(error)")
        }
    }
    
    private func resetForm() {
        currentStep = 0
        selectedDrink = ""
        caffeineAmount = 0
        customDrinkName = ""
        customCaffeineAmount = ""
        selectedHour = Calendar.current.component(.hour, from: Date())
        selectedMinute = Calendar.current.component(.minute, from: Date())
        isToday = true
        stepOpacity = 1.0
        stepOffset = 0
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
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 32))
                
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                if caffeineAmount > 0 {
                    Text("\(Int(caffeineAmount))mg")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.15) : Color(.systemBackground))
                    .shadow(color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color.opacity(0.8) : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SuccessAnimation: View {
    @State private var opacity = 0.0
    @State private var offset: CGFloat = 20
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                Text("Added")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
            .opacity(opacity)
            .offset(y: offset)
            
            Spacer()
                .frame(height: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1.0
                offset = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 0.0
                    offset = -10
                }
            }
        }
    }
}

struct LogSafetyWarning: View {
    let plannedAmount: Double
    let currentDailyTotal: Double
    let userWeight: Double
    
    var newTotal: Double {
        currentDailyTotal + plannedAmount
    }
    
    var shouldShowWarning: Bool {
        let warningLevel = userWeight * 4.5
        return newTotal > warningLevel || plannedAmount > 200
    }
    
    var warningType: LogWarningType {
        let dailyLimit = userWeight * 5.7
        
        if newTotal > (userWeight * 15) {
            return .danger
        } else if newTotal > dailyLimit {
            return .overLimit
        } else if plannedAmount > 200 {
            return .highSingleDose
        } else {
            return .approaching
        }
    }
    
    var body: some View {
        Group {
            if shouldShowWarning {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(warningType.emoji)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(warningType.title)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(warningType.color)
                            
                            Text(warningMessage)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [warningType.color.opacity(0.05), warningType.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
        }
    }
    
    var warningMessage: String {
        let dailyLimit = Int(userWeight * 5.7)
        
        switch warningType {
        case .danger:
            return "This would put you at \(Int(newTotal))mg today. That's quite a lot!"
        case .overLimit:
            return "This brings you to \(Int(newTotal))mg (limit: \(dailyLimit)mg)"
        case .highSingleDose:
            return "\(Int(plannedAmount))mg is a strong dose. You might feel jittery."
        case .approaching:
            return "This brings you to \(Int(newTotal))mg of \(dailyLimit)mg today"
        }
    }
}

enum LogWarningType {
    case approaching, overLimit, highSingleDose, danger
    
    var emoji: String {
        switch self {
        case .approaching: return "⚠️"
        case .overLimit: return "🚨"
        case .highSingleDose: return "💪"
        case .danger: return "🛑"
        }
    }
    
    var title: String {
        switch self {
        case .approaching: return "Getting Close"
        case .overLimit: return "Over Your Limit"
        case .highSingleDose: return "Strong Dose"
        case .danger: return "Very High Amount"
        }
    }
    
    var color: Color {
        switch self {
        case .approaching: return .orange
        case .overLimit: return .red
        case .highSingleDose: return .blue
        case .danger: return .red
        }
    }
}