import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleWeatherNotification(title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleWeatherAlert(for condition: String, temperature: Double, in hours: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Weather Alert"
        
        if condition.lowercased().contains("rain") {
            content.body = "Rain expected in your area. Don't forget your umbrella!"
        } else if condition.lowercased().contains("snow") {
            content.body = "Snow expected in your area. Bundle up!"
        } else if temperature > 30 {
            content.body = "High temperature alert: \(Int(temperature))°C expected. Stay hydrated!"
        } else if temperature < 0 {
            content.body = "Freezing temperature alert: \(Int(temperature))°C expected. Stay warm!"
        } else {
            content.body = "Current weather: \(condition), \(Int(temperature))°C"
        }
        
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(hours * 3600), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
