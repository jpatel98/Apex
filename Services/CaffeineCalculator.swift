import Foundation

struct CaffeineLevel {
    let timestamp: Date
    let activeCaffeineMg: Double
}

class CaffeineCalculator {
    static func calculateActiveCaffeine(entries: [CaffeineEntry], sensitivity: CaffeineSensitivity, at time: Date = Date()) -> Double {
        let halfLifeHours = sensitivity.halfLifeHours
        var totalActiveCaffeine = 0.0
        
        for entry in entries {
            let hoursSinceConsumption = time.timeIntervalSince(entry.timestamp) / 3600.0
            
            if hoursSinceConsumption >= 0 {
                let remainingCaffeine = entry.caffeineAmountMg * pow(0.5, hoursSinceConsumption / halfLifeHours)
                totalActiveCaffeine += remainingCaffeine
            }
        }
        
        return totalActiveCaffeine
    }
    
    static func calculateCaffeineLevels(entries: [CaffeineEntry], sensitivity: CaffeineSensitivity, from startTime: Date, to endTime: Date, intervalMinutes: Int = 15) -> [CaffeineLevel] {
        var levels: [CaffeineLevel] = []
        var currentTime = startTime
        
        while currentTime <= endTime {
            let activeCaffeine = calculateActiveCaffeine(entries: entries, sensitivity: sensitivity, at: currentTime)
            levels.append(CaffeineLevel(timestamp: currentTime, activeCaffeineMg: activeCaffeine))
            currentTime = currentTime.addingTimeInterval(Double(intervalMinutes * 60))
        }
        
        return levels
    }
    
    static func findPeakCaffeineTime(entries: [CaffeineEntry], sensitivity: CaffeineSensitivity, within hours: Int = 24) -> (time: Date, amount: Double)? {
        guard !entries.isEmpty else { return nil }
        
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }
        guard let firstEntry = sortedEntries.first else { return nil }
        
        let startTime = firstEntry.timestamp
        let endTime = Date().addingTimeInterval(TimeInterval(hours * 3600))
        
        let levels = calculateCaffeineLevels(entries: entries, sensitivity: sensitivity, from: startTime, to: endTime, intervalMinutes: 5)
        
        return levels.max { $0.activeCaffeineMg < $1.activeCaffeineMg }.map { ($0.timestamp, $0.activeCaffeineMg) }
    }
    
    static func predictCrashTime(entries: [CaffeineEntry], sensitivity: CaffeineSensitivity, thresholdPercentage: Double = 0.25) -> Date? {
        guard let (peakTime, peakAmount) = findPeakCaffeineTime(entries: entries, sensitivity: sensitivity) else {
            return nil
        }
        
        let crashThreshold = max(peakAmount * thresholdPercentage, 40.0)
        
        var currentTime = peakTime
        let endTime = peakTime.addingTimeInterval(24 * 3600)
        
        while currentTime < endTime {
            let currentLevel = calculateActiveCaffeine(entries: entries, sensitivity: sensitivity, at: currentTime)
            if currentLevel <= crashThreshold {
                return currentTime
            }
            currentTime = currentTime.addingTimeInterval(60)
        }
        
        return nil
    }
    
    static func getRecentEntries(_ entries: [CaffeineEntry], within hours: Int = 24) -> [CaffeineEntry] {
        let cutoffTime = Date().addingTimeInterval(-Double(hours * 3600))
        return entries.filter { $0.timestamp > cutoffTime }
    }
}