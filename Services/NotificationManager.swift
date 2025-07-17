import Foundation
import UserNotifications
import SwiftData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleCrashAlert(for crashTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Caffeine Crash Alert"
        content.body = "Heads up: A caffeine crash is predicted around \(crashTime.formatted(date: .omitted, time: .shortened)). Consider a short walk or a glass of water."
        content.sound = .default
        content.badge = 1
        
        let alertTime = crashTime.addingTimeInterval(-30 * 60)
        
        guard alertTime > Date() else { return }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "crash-alert-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("Crash alert scheduled for \(alertTime)")
            }
        }
    }
    
    func cancelAllCrashAlerts() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let crashAlertIds = requests
                .filter { $0.identifier.hasPrefix("crash-alert-") }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: crashAlertIds)
        }
    }
    
    func updateCrashAlert(entries: [CaffeineEntry], sensitivity: CaffeineSensitivity) {
        cancelAllCrashAlerts()
        
        if let crashTime = CaffeineCalculator.predictCrashTime(entries: entries, sensitivity: sensitivity) {
            scheduleCrashAlert(for: crashTime)
        }
    }
}