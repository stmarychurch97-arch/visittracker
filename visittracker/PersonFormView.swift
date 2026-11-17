import SwiftUI

struct PersonFormView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let person: Person?

    @State private var name = ""
    @State private var phone = ""
    @State private var hasBirthday = false
    @State private var birthday = Date()
    @State private var hasNext = false
    @State private var nextVisit = Date()
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("الاسم", text: $name)
                    TextField("رقم الهاتف (مع رمز الدولة)", text: $phone).keyboardType(.phonePad)
                }
                Section {
                    Toggle("تاريخ الميلاد", isOn: $hasBirthday)
                    if hasBirthday {
                        DatePicker("التاريخ", selection: $birthday, in: ...Date(), displayedComponents: .date)
                    }
                    Toggle("موعد الزيارة القادمة", isOn: $hasNext)
                    if hasNext {
                        DatePicker("الموعد", selection: $nextVisit, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                Section("ملاحظات") { TextField("ملاحظات", text: $notes) }
            }
            .navigationTitle(person == nil ? "شخص جديد" : "تعديل")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("إلغاء") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: fill)
        }
    }

    private func fill() {
        guard let p = person else { return }
        name = p.name; phone = p.phone; notes = p.notes
        if let b = p.birthday { hasBirthday = true; birthday = b }
        if let n = p.nextVisit { hasNext = true; nextVisit = n }
    }

    private func save() {
        var p = person ?? Person(name: name)
        p.name = name.trimmingCharacters(in: .whitespaces)
        p.phone = phone
        p.notes = notes
        p.birthday = hasBirthday ? birthday : nil
        p.nextVisit = hasNext ? nextVisit : nil
        if let i = store.people.firstIndex(where: { $0.id == p.id }) {
            store.people[i] = p
        } else {
            store.people.append(p)
        }
        dismiss()
    }
}
