import re

with open("iLoveWorks/PushManager.swift", "r") as f:
    text = f.read()

# Add scheduleAlarm and cancelAlarm methods.
# Since we have due date / due time logic, we need to schedule a local notification.
# The user wants local alarms for tasks.

new_methods = """
    func scheduleAlarm(id: String, title: String, body: String, timeString: String?) {
        guard let timeString = timeString else {
            cancelAlarm(id: id)
            return
        }
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Parse "HH:mm"
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return }
              
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "alarm_\\(id)", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling alarm: \\(error)")
            }
        }
    }
    
    func cancelAlarm(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["alarm_\\(id)"])
    }
"""

text = text.replace("func forgetToken() {\n        registered = false\n    }", "func forgetToken() {\n        registered = false\n    }" + new_methods)

with open("iLoveWorks/PushManager.swift", "w") as f:
    f.write(text)
print("Added local alarm scheduling")
