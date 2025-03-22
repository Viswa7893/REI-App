import SwiftUI
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Notification authorization granted")
            } else if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleReminderNotification(for reminder: Reminder) {
        // First, remove any existing notifications for this reminder
        cancelNotification(for: reminder.id)
        
        // Don't schedule for completed or past reminders
        guard !reminder.isCompleted && reminder.dueDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        
        if !reminder.notes.isEmpty {
            content.body = reminder.notes
        } else {
            content.body = "Your reminder is due now."
        }
        
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        // Add reminder ID to notification so we can identify it later
        content.userInfo = ["reminderId": reminder.id.uuidString]
        
        // Create trigger based on the reminder's due date
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled notification for reminder: \(reminder.title)")
            }
        }
    }
    
    func cancelNotification(for reminderId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId.uuidString])
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle interaction with notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Get the reminder ID from the notification
        if let reminderIdString = response.notification.request.content.userInfo["reminderId"] as? String,
           let reminderId = UUID(uuidString: reminderIdString) {
            
            // Here you could navigate to the reminder or mark it as completed
            // We'll implement this later by posting a notification that the app can listen for
            NotificationCenter.default.post(name: NSNotification.Name("ReminderNotificationTapped"), 
                                           object: nil, 
                                           userInfo: ["reminderId": reminderId])
        }
        
        completionHandler()
    }
} 