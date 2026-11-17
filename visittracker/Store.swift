import Foundation

final class Store: ObservableObject {
    @Published var people: [Person] = [] {
        didSet { save(); rescheduleNotifications() }
    }

    private let url: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("people.json")
    }()

    init() { load() }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Person].self, from: data) else { return }
        people = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(people) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func rescheduleNotifications() {
        NotificationManager.rescheduleAll(people: people, limit: Settings.limitDays)
    }

    func addVisit(personID: UUID, date: Date, note: String) {
        guard let i = people.firstIndex(where: { $0.id == personID }) else { return }
        people[i].visits.append(Visit(date: date, note: note))
    }

    func delete(at offsets: IndexSet, from list: [Person]) {
        let ids = offsets.map { list[$0].id }
        people.removeAll { ids.contains($0.id) }
    }
}
