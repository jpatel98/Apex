import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CaffeineEntry.timestamp, order: .reverse) private var allEntries: [CaffeineEntry]
    @Query private var users: [User]
    
    @State private var selectedTimeRange = TimeRange.today
    @State private var isLoading = true
    @State private var animatedCaffeineLevel: Double = 0
    
    var currentUser: User? {
        users.first(where: { $0.isOnboarded })
    }
    
    var userEntries: [CaffeineEntry] {
        guard let user = currentUser else { return [] }
        return allEntries.filter { $0.userID == user.id }
    }
    
    var recentEntries: [CaffeineEntry] {
        CaffeineCalculator.getRecentEntries(userEntries, within: 24)
    }
    
    var currentCaffeineLevel: Double {
        guard let user = currentUser else { return 0 }
        return CaffeineCalculator.calculateActiveCaffeine(entries: recentEntries, sensitivity: user.sensitivity)
    }
    
    var crashTime: Date? {
        guard let user = currentUser else { return nil }
        return CaffeineCalculator.predictCrashTime(entries: recentEntries, sensitivity: user.sensitivity)
    }
    
    var chartData: [CaffeineLevel] {
        guard let user = currentUser else { return [] }
        
        let now = Date()
        let startTime = now.addingTimeInterval(-12 * 3600)
        let endTime = now.addingTimeInterval(12 * 3600)
        
        return CaffeineCalculator.calculateCaffeineLevels(
            entries: recentEntries,
            sensitivity: user.sensitivity,
            from: startTime,
            to: endTime,
            intervalMinutes: 15
        )
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack {
                        ProgressView("Loading your caffeine data...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if allEntries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("No Caffeine Logged")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Start tracking your caffeine intake to see predictions and insights.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            CuteCurrentLevelCard(
                                caffeineLevel: animatedCaffeineLevel,
                                crashTime: crashTime
                            )
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .scale))
                            
                            // Safety warning if needed
                            if let user = currentUser {
                                SafetyWarningCard(
                                    totalToday: totalCaffeineToday,
                                    currentLevel: animatedCaffeineLevel,
                                    userWeight: user.weightKg
                                )
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            CoffeeCupVisualization(
                                caffeineLevel: animatedCaffeineLevel,
                                maxCaffeine: (currentUser?.weightKg ?? 70) * 5.7,
                                crashTime: crashTime
                            )
                            .frame(height: 280)
                            .padding(.horizontal)
                            .transition(.opacity)
                            
                            CuteTodayView(entries: todayEntries, totalToday: totalCaffeineToday)
                                .padding(.horizontal)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            
                            PlayfulStatsView(
                                averageDaily: averageDailyCaffeine,
                                sensitivity: currentUser?.sensitivity ?? .medium,
                                entriesCount: allEntries.count
                            )
                            .padding(.horizontal)
                            .transition(.opacity)
                            
                            CaffeineEducationCard()
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                        .padding(.vertical, 10)
                    }
                    .refreshable {
                        await refreshData()
                    }
                }
            }
            .navigationTitle("Your Caffeine")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadData()
        }
        .onChange(of: currentCaffeineLevel) { oldValue, newValue in
            animatedCaffeineLevel = newValue
        }
    }
    
    private func loadData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            animatedCaffeineLevel = currentCaffeineLevel
        }
    }
    
    private func refreshData() async {
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }
    
    var todayEntries: [CaffeineEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return userEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
    }
    
    var totalCaffeineToday: Double {
        todayEntries.reduce(0) { $0 + $1.caffeineAmountMg }
    }
    
    var averageDailyCaffeine: Double {
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
        let recentEntries = userEntries.filter { $0.timestamp > thirtyDaysAgo }
        
        guard !recentEntries.isEmpty else { return 0 }
        
        let totalCaffeine = recentEntries.reduce(0) { $0 + $1.caffeineAmountMg }
        let days = 30.0
        
        return totalCaffeine / days
    }
}

struct CuteCurrentLevelCard: View {
    let caffeineLevel: Double
    let crashTime: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(caffeineEmoji)
                        .font(.system(size: 50))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(caffeineLevel))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(levelGradient)
                        Text("mg active")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    MiniProgressRing(
                        progress: min(caffeineLevel / 400, 1.0),
                        gradient: levelGradient
                    )
                    .frame(width: 100, height: 100)
                    
                    Text(levelDescription)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(levelGradient)
                }
            }
            
            if let crashTime = crashTime {
                HStack(spacing: 12) {
                    Text("⚠️")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Crash Alert")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        Text(crashTime, format: .dateTime.hour().minute())
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    Text(timeUntilCrash)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.orange.opacity(0.15))
                        )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.05), .orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
    
    var caffeineEmoji: String {
        switch caffeineLevel {
        case 0..<50: return "😴"
        case 50..<150: return "😌"
        case 150..<250: return "😊"
        case 250..<350: return "⚡"
        default: return "🚨"
        }
    }
    
    var levelGradient: LinearGradient {
        switch caffeineLevel {
        case 0..<50: 
            return LinearGradient(colors: [.red.opacity(0.8), .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 50..<150: 
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 150..<250: 
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 250..<350: 
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: 
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var levelDescription: String {
        switch caffeineLevel {
        case 0..<50: return "Feeling tired"
        case 50..<150: return "Relaxed"
        case 150..<250: return "Alert & focused"
        case 250..<350: return "Highly energized"
        default: return "Very stimulated"
        }
    }
    
    var timeUntilCrash: String {
        guard let crashTime = crashTime else { return "" }
        let interval = crashTime.timeIntervalSince(Date())
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
    }
}

struct CoffeeCupVisualization: View {
    let caffeineLevel: Double
    let maxCaffeine: Double
    let crashTime: Date?
    
    var fillPercentage: Double {
        min(max(caffeineLevel / maxCaffeine, 0), 1)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("☕ Your Caffeine")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Simple, clean cup
            SimpleCupView(
                fillPercentage: fillPercentage, 
                caffeineLevel: caffeineLevel,
                crashTime: crashTime
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
    }
}

struct SimpleCupView: View {
    let fillPercentage: Double
    let caffeineLevel: Double
    let crashTime: Date?
    
    var coffeeGradient: LinearGradient {
        switch caffeineLevel {
        case 0..<100:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
        case 100..<200:
            return LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
        case 200..<300:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Simple cup outline
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray3), lineWidth: 3)
                    .frame(width: 120, height: 160)
                
                // Coffee fill with smooth gradient
                RoundedRectangle(cornerRadius: 10)
                    .fill(coffeeGradient)
                    .frame(width: 114, height: max(4, 154 * fillPercentage))
                    .offset(y: 77 - (77 * fillPercentage))
                
                // Caffeine level text overlay
                VStack(spacing: 4) {
                    Text("\(Int(caffeineLevel))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("mg")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.6))
                )
            }
            
            // Status text
            Text(statusText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            // Crash warning - simplified
            if let crashTime = crashTime {
                Text("⚠️ Empty at \(crashTime, format: .dateTime.hour().minute())")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.orange.opacity(0.1))
                    )
            }
        }
    }
    
    var statusText: String {
        switch fillPercentage {
        case 0..<0.25: return "Crash coming soon"
        case 0.25..<0.5: return "Energy fading"
        case 0.5..<0.75: return "Nicely energized"
        case 0.75..<0.9: return "Highly alert"
        default: return "Approaching limit"
        }
    }
}

struct CuteTodayView: View {
    let entries: [CaffeineEntry]
    let totalToday: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("☕ Today")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(totalToday)) mg total")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.purple.opacity(0.1))
                    )
            }
            
            if entries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("🌙")
                            .font(.system(size: 40))
                        Text("No caffeine yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(entries.prefix(3), id: \.id) { entry in
                        HStack(spacing: 16) {
                            Text(drinkEmoji(for: entry.drinkName))
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(drinkColor(for: entry.drinkName).opacity(0.1))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.drinkName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("\(Int(entry.caffeineAmountMg)) mg")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(entry.timestamp, format: .dateTime.hour().minute())
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if entries.count > 3 {
                        Text("+ \(entries.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
    }
    
    func drinkEmoji(for name: String) -> String {
        switch name {
        case "Coffee": return "☕"
        case "Espresso": return "☕"
        case "Black Tea": return "🍵"
        case "Green Tea": return "🍵"
        case "Energy Drink": return "⚡"
        case "Soda": return "🥤"
        default: return "✨"
        }
    }
    
    func drinkColor(for name: String) -> Color {
        switch name {
        case "Coffee", "Espresso": return .brown
        case "Black Tea": return .orange
        case "Green Tea": return .green
        case "Energy Drink": return .blue
        case "Soda": return .purple
        default: return .pink
        }
    }
}

struct PlayfulStatsView: View {
    let averageDaily: Double
    let sensitivity: CaffeineSensitivity
    let entriesCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📊 Your Stats")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                PlayfulStatCard(
                    emoji: "🌅",
                    value: "\(Int(averageDaily))",
                    unit: "mg",
                    label: "Daily Average",
                    color: .orange
                )
                
                PlayfulStatCard(
                    emoji: "⏱️",
                    value: "\(Int(sensitivity.halfLifeHours))",
                    unit: "hrs",
                    label: "Metabolism",
                    color: .blue
                )
                
                PlayfulStatCard(
                    emoji: "🏆",
                    value: "\(entriesCount)",
                    unit: "",
                    label: "Total Logs",
                    color: .purple
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
    }
}

struct PlayfulStatCard: View {
    let emoji: String
    let value: String
    let unit: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.title2)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color.opacity(0.8))
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
    }
}

struct MiniProgressRing: View {
    let progress: Double
    let gradient: LinearGradient
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                .opacity(0.1)
                .foregroundColor(.gray)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(animatedProgress, 1.0)))
                .stroke(gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .rotationEffect(Angle(degrees: 270))
            
            VStack(spacing: 0) {
                Text("\(Int(progress * 100))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(gradient)
                Text("%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { oldValue, newValue in
            animatedProgress = newValue
        }
    }
}

enum TimeRange {
    case today, week, month
}

struct SafetyWarningCard: View {
    let totalToday: Double
    let currentLevel: Double
    let userWeight: Double
    
    var shouldShowWarning: Bool {
        let dailyLimit = userWeight * 5.7
        let warningLevel = userWeight * 4.5
        return totalToday > warningLevel || currentLevel > 200
    }
    
    var warningType: SafetyWarningType {
        let dailyLimit = userWeight * 5.7
        
        if totalToday > (userWeight * 15) {
            return .danger
        } else if totalToday > dailyLimit {
            return .overLimit
        } else if currentLevel > 200 {
            return .highSingleDose
        } else {
            return .approaching
        }
    }
    
    var body: some View {
        Group {
            if shouldShowWarning {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text(warningType.emoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(warningType.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(warningType.color)
                            
                            Text(warningMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
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
        let remaining = max(0, Int(dailyLimit) - Int(totalToday))
        
        switch warningType {
        case .danger:
            return "This is a lot of caffeine. Consider stopping for today."
        case .overLimit:
            return "You've had \(Int(totalToday))mg today. Daily limit: \(dailyLimit)mg"
        case .highSingleDose:
            return "That's a strong dose! Stay hydrated and monitor how you feel."
        case .approaching:
            return "You have \(remaining)mg left for today (\(dailyLimit)mg limit)"
        }
    }
}

enum SafetyWarningType {
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
        case .approaching: return "Nearing Daily Limit"
        case .overLimit: return "Over Daily Limit"
        case .highSingleDose: return "Strong Dose"
        case .danger: return "Too Much Caffeine"
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

struct CaffeineEducationCard: View {
    @State private var currentTipIndex = 0
    
    let tips = [
        CaffeineTip(
            emoji: "💡",
            title: "Did you know?",
            description: "Caffeine stays in your system for 5-6 hours. Having coffee at 3pm means it's still working at 8pm!"
        ),
        CaffeineTip(
            emoji: "⚖️",
            title: "Daily Limit",
            description: "Most adults can safely have up to 400mg daily. That's about 4 cups of coffee."
        ),
        CaffeineTip(
            emoji: "💧",
            title: "Stay Hydrated",
            description: "Caffeine is a mild diuretic. Drink water throughout the day to stay balanced."
        ),
        CaffeineTip(
            emoji: "😴",
            title: "Better Sleep",
            description: "Stop caffeine 6+ hours before bed for better sleep. Your future self will thank you!"
        ),
        CaffeineTip(
            emoji: "🍎",
            title: "Natural Energy",
            description: "Try a walk, cold water, or healthy snack when you feel tired instead of more caffeine."
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("💡 Caffeine Tips")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: nextTip) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(tips[currentTipIndex].emoji)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tips[currentTipIndex].title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(tips[currentTipIndex].description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
            }
            .padding(.bottom, 4)
            
            HStack {
                ForEach(0..<tips.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentTipIndex ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .onAppear {
            startAutoRotation()
        }
    }
    
    private func nextTip() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTipIndex = (currentTipIndex + 1) % tips.count
        }
    }
    
    private func startAutoRotation() {
        Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            nextTip()
        }
    }
}

struct CaffeineTip {
    let emoji: String
    let title: String
    let description: String
}