import Foundation
import UserNotifications

enum NotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// iOS يسمح بـ 64 تنبيهًا معلّقًا كحد أقصى، لذلك نجدول الأقرب موعدًا أولًا
    /// ونعيد الجدولة كلما فُتح التطبيق أو تغيّرت البيانات.
    static func rescheduleAll(people: [Person], limit: Int) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let cal = Calendar.current
        let now = Date()
        var items: [(date: Date, id: String, title: String, body: String)] = []

        func at9(_ d: Date) -> Date? {
            cal.date(bySettingHour: 9, minute: 0, second: 0, of: d)
        }

        for p in people {
            // 1) تجاوز المدة
            if let last = p.lastVisit,
               let due = cal.date(byAdding: .day, value: limit + 1, to: last),
               let when = at9(due), when > now {
                items.append((when, "\(p.id)-overdue", "⚠️ تجاوز مدة الزيارة",
                              "مرّ أكثر من \(limit) يومًا على آخر زيارة لـ \(p.name)"))
            }
            // 2) موعد الزيارة القادمة (صباح اليوم نفسه)
            if let n = p.nextVisit {
                let when = n > now && !cal.isDate(n, equalTo: n, toGranularity: .day) ? n : (at9(n) ?? n)
                if when > now {
                    items.append((when, "\(p.id)-next", "📅 موعد زيارة",
                                  "اليوم موعد زيارة \(p.name)"))
                }
            }
            // 3) عيد الميلاد القادم
            if let b = p.birthday,
               let next = cal.nextDate(after: now, matching: cal.dateComponents([.month, .day], from: b),
                                       matchingPolicy: .nextTime),
               let when = at9(next), when > now {
                items.append((when, "\(p.id)-bday", "🎂 عيد ميلاد",
                              "اليوم عيد ميلاد \(p.name)"))
            }
        }

        for item in items.sorted(by: { $0.date < $1.date }).prefix(64) {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: item.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: item.id, content: content, trigger: trigger))
        }
    }
}
