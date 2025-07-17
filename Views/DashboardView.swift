import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CaffeineEntry.timestamp, order: .reverse) private var allEntries: [CaffeineEntry]
    @Query private var users: [User]
    
    @State private var selectedTimeRange = TimeRange.today
    
    var currentUser: User? {
        users.first(where: { $0.isOnboarded })
    }
    
    var recentEntries: [CaffeineEntry] {
        CaffeineCalculator.getRecentEntries(allEntries, within: 24)
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
            ScrollView {
                VStack(spacing: 20) {
                    CurrentLevelCard(
                        caffeineLevel: currentCaffeineLevel,
                        crashTime: crashTime
                    )
                    
                    CaffeineChart(data: chartData, crashTime: crashTime)
                        .frame(height: 300)
                        .padding(.horizontal)
                    
                    TodayEntriesView(entries: todayEntries)
                    
                    QuickStatsView(
                        totalToday: totalCaffeineToday,
                        averageDaily: averageDailyCaffeine,
                        sensitivity: currentUser?.sensitivity ?? .medium
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    var todayEntries: [CaffeineEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
    }
    
    var totalCaffeineToday: Double {
        todayEntries.reduce(0) { $0 + $1.caffeineAmountMg }
    }
    
    var averageDailyCaffeine: Double {
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
        let recentEntries = allEntries.filter { $0.timestamp > thirtyDaysAgo }
        
        guard !recentEntries.isEmpty else { return 0 }
        
        let totalCaffeine = recentEntries.reduce(0) { $0 + $1.caffeineAmountMg }
        let days = 30.0
        
        return totalCaffeine / days
    }
}

struct CurrentLevelCard: View {
    let caffeineLevel: Double
    let crashTime: Date?
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Active Caffeine")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(caffeineLevel)) mg")
                        .font(.system(size: 36, weight: .bold))
                    
                    HStack(spacing: 5) {
                        Image(systemName: levelIcon)
                            .foregroundColor(levelColor)
                        Text(levelDescription)
                            .font(.subheadline)
                            .foregroundColor(levelColor)
                    }
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: min(caffeineLevel / 400, 1.0),
                    color: levelColor
                )
                .frame(width: 80, height: 80)
            }
            
            if let crashTime = crashTime {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Crash predicted at \(crashTime, format: .dateTime.hour().minute())")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    var levelIcon: String {
        switch caffeineLevel {
        case 0..<50: return "battery.0"
        case 50..<150: return "battery.25"
        case 150..<250: return "battery.50"
        case 250..<350: return "battery.75"
        default: return "battery.100"
        }
    }
    
    var levelColor: Color {
        switch caffeineLevel {
        case 0..<50: return .red
        case 50..<150: return .orange
        case 150..<250: return .green
        case 250..<350: return .blue
        default: return .purple
        }
    }
    
    var levelDescription: String {
        switch caffeineLevel {
        case 0..<50: return "Low"
        case 50..<150: return "Moderate"
        case 150..<250: return "Optimal"
        case 250..<350: return "High"
        default: return "Very High"
        }
    }
}

struct CaffeineChart: View {
    let data: [CaffeineLevel]
    let crashTime: Date?
    
    var body: some View {
        Chart {
            ForEach(data, id: \.timestamp) { level in
                LineMark(
                    x: .value("Time", level.timestamp),
                    y: .value("Caffeine", level.activeCaffeineMg)
                )
                .foregroundStyle(Color.accentColor)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", level.timestamp),
                    y: .value("Caffeine", level.activeCaffeineMg)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            
            if let crashTime = crashTime {
                RuleMark(x: .value("Crash Time", crashTime))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top) {
                        Text("Crash")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
            }
            
            RuleMark(x: .value("Now", Date()))
                .foregroundStyle(.gray)
                .lineStyle(StrokeStyle(lineWidth: 1))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 3)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}

struct TodayEntriesView: View {
    let entries: [CaffeineEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Caffeine")
                .font(.headline)
                .padding(.horizontal)
            
            if entries.isEmpty {
                Text("No caffeine logged today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(entries, id: \.id) { entry in
                    HStack {
                        Image(systemName: iconForDrink(entry.drinkName))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading) {
                            Text(entry.drinkName)
                                .font(.subheadline)
                            Text("\(Int(entry.caffeineAmountMg))mg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(entry.timestamp, format: .dateTime.hour().minute())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                }
            }
        }
        .padding(.vertical)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    func iconForDrink(_ name: String) -> String {
        if let preset = DrinkPreset.presets.first(where: { $0.name == name }) {
            return preset.icon
        }
        return "cup.and.saucer"
    }
}

struct QuickStatsView: View {
    let totalToday: Double
    let averageDaily: Double
    let sensitivity: CaffeineSensitivity
    
    var body: some View {
        HStack(spacing: 15) {
            StatCard(
                title: "Today",
                value: "\(Int(totalToday))mg",
                icon: "calendar"
            )
            
            StatCard(
                title: "Daily Avg",
                value: "\(Int(averageDaily))mg",
                icon: "chart.bar"
            )
            
            StatCard(
                title: "Half-life",
                value: "\(Int(sensitivity.halfLifeHours))h",
                icon: "clock"
            )
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 8)
                .opacity(0.3)
                .foregroundColor(color)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270))
                .animation(.linear, value: progress)
        }
    }
}

enum TimeRange {
    case today, week, month
}