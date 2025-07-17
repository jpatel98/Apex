import Foundation
import SwiftData

enum CaffeineSensitivity: String, CaseIterable, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
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