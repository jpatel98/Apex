import SwiftUI

enum Constants {
    enum Colors {
        static let primaryGradient = LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let secondaryGradient = LinearGradient(
            colors: [Color.orange, Color.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let successGradient = LinearGradient(
            colors: [Color.green, Color.mint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardBackground = Color(.systemGray6)
        static let cardBackgroundDark = Color(.systemGray5)
    }
    
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let full: CGFloat = .infinity
    }
    
    enum Animation {
        static let quick = Animation.easeInOut(duration: 0.2)
        static let standard = Animation.easeInOut(duration: 0.3)
        static let smooth = Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    }
    
    enum Haptics {
        static let impact = UIImpactFeedbackGenerator(style: .medium)
        static let selection = UISelectionFeedbackGenerator()
        static let notification = UINotificationFeedbackGenerator()
    }
    
    enum Subscription {
        static let proMonthlyPrice = "$4.99/month"
        static let proMonthlyPriceValue = 4.99
        static let premiumYearlyPrice = "$39.99/year"
        static let premiumYearlyPriceValue = 39.99
        static let freeHistoryDays = 7
    }
    
    enum Caffeine {
        static let maxDailyAmount: Double = 400
        static let crashNotificationMinutes = 30
        static let defaultHalfLife: Double = 5.0
        static let lowSensitivityHalfLife: Double = 6.0
        static let highSensitivityHalfLife: Double = 4.0
        static let crashThresholdPercentage: Double = 0.25
        static let minimumCaffeineLevel: Double = 40.0
        
        // Safety calculations based on body weight
        static let safeDailyMgPerKg: Double = 5.7  // ~400mg for 70kg person
        static let warningMgPerKg: Double = 4.5    // Warning at ~315mg for 70kg person
        static let dangerMgPerKg: Double = 150     // Dangerous level (LD50 approximation)
        
        // Single dose limits
        static let maxSingleDose: Double = 200     // FDA recommendation
        static let warningSingleDose: Double = 150
        
        // User-friendly warnings
        static func dailyLimit(for weightKg: Double) -> Double {
            return weightKg * safeDailyMgPerKg
        }
        
        static func warningLevel(for weightKg: Double) -> Double {
            return weightKg * warningMgPerKg
        }
        
        static func isDangerous(amount: Double, weightKg: Double) -> Bool {
            return amount > (weightKg * dangerMgPerKg * 0.1) // 10% of dangerous level
        }
    }
}