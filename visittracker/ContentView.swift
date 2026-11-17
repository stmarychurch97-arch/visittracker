import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @AppStorage(Settings.limitKey) private var limit = 45
    @State private var search = ""
    @State private var showAdd = false
    @State private var showSettings = false

    private var filtered: [Person] {
        let list = store.people.sorted { $0.name < $1.name }
        guard !search.isEmpty else { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.phone.contains(search) }
    }
    private var overdue: [Person] {
        filtered.filter { $0.isOverdue(limit: limit) }
            .sorted { ($0.daysSinceLastVisit() ?? 0) > ($1.daysSinceLastVisit() ?? 0) }
    }
    private var birthdays: [Person] {
        filtered.filter { ($0.daysUntilBirthday() ?? 99) <= 7 }
            .sorted { ($0.daysUntilBirthday() ?? 0) < ($1.daysUntilBirthday() ?? 0) }
    }

    var body: some View {
        NavigationView {
            List {
                if !overdue.isEmpty {
                    Section("⚠️ تجاوزوا \(limit) يومًا") { rows(overdue) }
                }
                if !birthdays.isEmpty {
                    Section("🎂 أعياد ميلاد خلال 7 أيام") { rows(birthdays) }
                }
                Section("الجميع (\(filtered.count))") { rows(filtered) }
            }
            .searchable(text: $search, prompt: "بحث بالاسم أو الرقم")
            .navigationTitle("متابعة الزيارات")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { PersonFormView(person: nil) }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func rows(_ list: [Person]) -> some View {
        ForEach(list) { p in
            NavigationLink(destination: PersonDetailView(personID: p.id)) {
                PersonRow(p: p, limit: limit)
            }
        }
        .onDelete { store.delete(at: $0, from: list) }
    }
}

struct PersonRow: View {
    let p: Person
    let limit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(p.name).font(.headline)
            if let d = p.daysSinceLastVisit() {
                Text("منذ \(d) يوم من آخر زيارة")
                    .font(.subheadline)
                    .foregroundColor(p.isOverdue(limit: limit) ? .red : .secondary)
            } else {
                Text("لا توجد زيارات مسجلة").font(.subheadline).foregroundColor(.secondary)
            }
            if let n = p.nextVisit {
                Text("الزيارة القادمة: \(n.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundColor(.blue)
            }
            if let b = p.daysUntilBirthday(), b <= 7 {
                Text(b == 0 ? "🎂 عيد ميلاده اليوم" : "🎂 عيد ميلاده بعد \(b) يوم")
                    .font(.caption).foregroundColor(.orange)
            }
        }
    }
}
