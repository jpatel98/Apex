import Foundation
import SwiftData

@Model
final class CaffeineEntry {
    var id: UUID
    var drinkName: String
    var caffeineAmountMg: Double
    var timestamp: Date
    var userID: UUID
    
    init(drinkName: String, caffeineAmountMg: Double, timestamp: Date = Date(), userID: UUID) {
        self.id = UUID()
        self.drinkName = drinkName
        self.caffeineAmountMg = caffeineAmountMg
        self.timestamp = timestamp
        self.userID = userID
    }
}

struct DrinkPreset {
    let name: String
    let caffeineAmountMg: Double
    let icon: String
    
    static let presets: [DrinkPreset] = [
        DrinkPreset(name: "Coffee (8oz)", caffeineAmountMg: 95, icon: "cup.and.saucer.fill"),
        DrinkPreset(name: "Espresso Shot", caffeineAmountMg: 63, icon: "cup.and.saucer"),
        DrinkPreset(name: "Black Tea", caffeineAmountMg: 47, icon: "leaf.fill"),
        DrinkPreset(name: "Green Tea", caffeineAmountMg: 28, icon: "leaf"),
        DrinkPreset(name: "Energy Drink", caffeineAmountMg: 80, icon: "bolt.fill"),
        DrinkPreset(name: "Soda (12oz)", caffeineAmountMg: 35, icon: "bubbles.and.sparkles.fill")
    ]
}