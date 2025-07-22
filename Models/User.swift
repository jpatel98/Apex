import Foundation
import SwiftData

enum CaffeineSensitivity: String, CaseIterable, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    
    var displayName: String {
        switch self {
        case .low: return "Caffeine Veteran"
        case .medium: return "Regular Coffee Drinker"
        case .high: return "Caffeine Sensitive"
        }
    }
    
    var description: String {
        switch self {
        case .low: return "I can drink coffee at night and still sleep fine"
        case .medium: return "I avoid coffee after 2-3 PM"
        case .high: return "Even morning coffee can make me jittery"
        }
    }
    
    var emoji: String {
        switch self {
        case .low: return "💪"
        case .medium: return "☕"
        case .high: return "⚡"
        }
    }
    
    var halfLifeHours: Double {
        switch self {
        case .low: return 6.0
        case .medium: return 5.0
        case .high: return 4.0
        }
    }
}

@Model
final class User {
    var id: UUID
    var weightKg: Double
    var sensitivity: CaffeineSensitivity
    var createdAt: Date
    var isOnboarded: Bool
    
    init(weightKg: Double = 70.0, sensitivity: CaffeineSensitivity = .medium) {
        self.id = UUID()
        self.weightKg = weightKg
        self.sensitivity = sensitivity
        self.createdAt = Date()
        self.isOnboarded = false
    }
}