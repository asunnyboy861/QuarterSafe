import Foundation
import UserNotifications

struct ReminderScheduler {
    static func schedule(deadlines: [Quarter: Date], taxYear: Int) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for (q, due) in deadlines {
            for days in [21, 14, 7, 1, 0] {
                guard let fire = Calendar.current.date(byAdding: .day, value: -days, to: due) else { continue }
                guard fire > .now else { continue }
                let content = UNMutableNotificationContent()
                content.title = copyFor(daysBefore: days, quarter: q)
                content.body = "Due \(due.formatted(date: .abbreviated, time: .omitted))"
                content.sound = .default
                content.userInfo = ["deepLink": "quartersafe://pay/\(q.key)", "quarter": q.key]
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: fire)
                comps.hour = 9
                comps.minute = 0
                let request = UNNotificationRequest(
                    identifier: "qet-\(q.key)-d\(days)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
                center.add(request)
            }
        }
    }

    static func cancel(quarter: Quarter) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { reqs in
            let ids = reqs.map(\.identifier).filter { $0.hasPrefix("qet-\(quarter.key)-") }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    static func copyFor(daysBefore: Int, quarter: Quarter) -> String {
        switch daysBefore {
        case 21: "3 weeks until \(quarter.key) — check your jar"
        case 14: "\(quarter.key) is due in 2 weeks"
        case 7: "One week to \(quarter.key) — move money to your tax jar?"
        case 1: "\(quarter.key) due tomorrow"
        default: "\(quarter.key) is due today"
        }
    }
}

final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()
    var onQuarterTapped: ((Quarter) -> Void)?

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func start() {
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let key = userInfo["quarter"] as? String, let q = Quarter(rawValue: key.lowercased()) {
            onQuarterTapped?(q)
        }
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
