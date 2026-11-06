import Foundation
import UserNotifications

/// 安静提醒：只有横幅和通知中心，不设声音、不震动，不是闹钟
@MainActor
final class NotificationManager {

    static let shared = NotificationManager()
    private var authorized = false

    func setupIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            authorized = (try? await center.requestAuthorization(options: [.alert, .badge])) ?? false
        case .authorized, .provisional:
            authorized = true
        default:
            authorized = false
        }
    }

    func scheduleAll(_ data: AppData) {
        guard authorized, data.settings.notificationsEnabled else { return }
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let now = Date()
        let calendar = DanmakuLogic.calendar

        // 节日：提前 N 天 + 前一天，各一条安静横幅
        for fest in DanmakuLogic.occurrences(data, now: now).filter({ $0.tier <= 2 }).prefix(60) {
            let reminders: [(Int, String)] = [
                (data.settings.leadDays, "还有 \(data.settings.leadDays) 天就是\(fest.name)了，\(fest.hint)"),
                (1, "明天就是\(fest.name)，今天把礼物落实")
            ]
            for (offset, body) in reminders {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: fest.date),
                      day > now else { continue }
                var comps = calendar.dateComponents([.year, .month, .day], from: day)
                comps.hour = 9
                comps.minute = 0
                let content = UNMutableNotificationContent()
                content.title = "\(fest.emoji) \(fest.name)"
                content.body = body
                content.sound = nil
                content.interruptionLevel = .passive
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                center.add(UNNotificationRequest(identifier: "fest-\(fest.id)-\(offset)",
                                                 content: content, trigger: trigger))
            }
        }

        // 每天一条安静横幅（同样不响）
        var daily = DateComponents()
        daily.hour = data.settings.dailyHour
        daily.minute = data.settings.dailyMinute
        let content = UNMutableNotificationContent()
        content.title = "记得"
        content.body = "今天还有几句她说过的话没看，点开看一眼就好。"
        content.sound = nil
        content.interruptionLevel = .passive
        center.add(UNNotificationRequest(
            identifier: "daily-review",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: daily, repeats: true)
        ))
    }
}
