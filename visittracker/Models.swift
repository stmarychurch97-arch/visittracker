import Foundation

struct Visit: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var note: String = ""
}

struct Person: Identifiable, Codable {
    var id = UUID()
    var name: String
    var phone: String = ""
    var birthday: Date?
    var nextVisit: Date?
    var notes: String = ""
    var visits: [Visit] = []

    var lastVisit: Date? { visits.map(\.date).max() }

    func daysSinceLastVisit(now: Date = Date()) -> Int? {
        guard let last = lastVisit else { return nil }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: now)).day
    }

    func isOverdue(limit: Int) -> Bool {
        guard let d = daysSinceLastVisit() else { return false }
        return d > limit
    }

    /// عدد الأيام حتى عيد الميلاد القادم (0 = اليوم)
    func daysUntilBirthday(now: Date = Date()) -> Int? {
        guard let b = birthday else { return nil }
        let cal = Calendar.current
        let comps = cal.dateComponents([.month, .day], from: b)
        guard let next = cal.nextDate(after: cal.startOfDay(for: now).addingTimeInterval(-1),
                                      matching: comps, matchingPolicy: .nextTime) else { return nil }
        return cal.dateComponents([.day], from: cal.startOfDay(for: now), to: next).day
    }
}

enum Settings {
    static let limitKey = "limitDays"
    static let templateKey = "messageTemplate"
    static let defaultTemplate = "مرحبًا {name}، أتمنى أن تكون بخير. أود الاطمئنان عليك وتحديد موعد للزيارة."
    static var limitDays: Int {
        let v = UserDefaults.standard.integer(forKey: limitKey)
        return v == 0 ? 45 : v
    }
    static var template: String {
        UserDefaults.standard.string(forKey: templateKey) ?? defaultTemplate
    }
}
