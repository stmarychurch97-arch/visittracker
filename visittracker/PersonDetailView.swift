import SwiftUI
import MessageUI

struct PersonDetailView: View {
    @EnvironmentObject var store: Store
    let personID: UUID
    @AppStorage(Settings.limitKey) private var limit = 45
    @State private var showVisit = false
    @State private var showEdit = false
    @State private var showSMS = false

    private var person: Person? { store.people.first { $0.id == personID } }

    var body: some View {
        if let p = person {
            List {
                Section {
                    if let d = p.daysSinceLastVisit() {
                        LabeledContent("منذ آخر زيارة") {
                            Text("\(d) يوم").foregroundColor(p.isOverdue(limit: limit) ? .red : .primary)
                        }
                    }
                    if let n = p.nextVisit {
                        LabeledContent("الزيارة القادمة", value: n.formatted(date: .abbreviated, time: .shortened))
                    }
                    if let b = p.birthday {
                        LabeledContent("عيد الميلاد", value: b.formatted(date: .long, time: .omitted))
                    }
                    if !p.phone.isEmpty { LabeledContent("الهاتف", value: p.phone) }
                    if !p.notes.isEmpty { Text(p.notes) }
                }

                if !p.phone.isEmpty {
                    Section("تواصل") {
                        Button { Contact.call(p.phone) } label: { Label("اتصال", systemImage: "phone.fill") }
                        Button { Contact.whatsapp(p.phone, text: Contact.message(for: p)) } label: {
                            Label("واتساب", systemImage: "message.fill")
                        }
                        if MFMessageComposeViewController.canSendText() {
                            Button { showSMS = true } label: { Label("رسالة نصية", systemImage: "text.bubble") }
                        }
                    }
                }

                Section("سجل الزيارات") {
                    Button { showVisit = true } label: { Label("تسجيل زيارة", systemImage: "plus.circle.fill") }
                    ForEach(p.visits.sorted { $0.date > $1.date }) { v in
                        VStack(alignment: .leading) {
                            Text(v.date.formatted(date: .long, time: .omitted))
                            if !v.note.isEmpty { Text(v.note).font(.caption).foregroundColor(.secondary) }
                        }
                    }
                    .onDelete { offs in
                        let sorted = p.visits.sorted { $0.date > $1.date }
                        let ids = offs.map { sorted[$0].id }
                        if let i = store.people.firstIndex(where: { $0.id == personID }) {
                            store.people[i].visits.removeAll { ids.contains($0.id) }
                        }
                    }
                }
            }
            .navigationTitle(p.name)
            .toolbar { Button("تعديل") { showEdit = true } }
            .sheet(isPresented: $showVisit) { VisitSheet(personID: personID) }
            .sheet(isPresented: $showEdit) { PersonFormView(person: p) }
            .sheet(isPresented: $showSMS) { SMSView(recipient: p.phone, body: Contact.message(for: p)) }
        } else {
            Text("لم يتم العثور على الشخص")
        }
    }
}

struct VisitSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let personID: UUID
    @State private var date = Date()
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                DatePicker("تاريخ الزيارة", selection: $date, in: ...Date(), displayedComponents: .date)
                TextField("ملاحظات", text: $note)
            }
            .navigationTitle("تسجيل زيارة")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("إلغاء") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        store.addVisit(personID: personID, date: date, note: note)
                        dismiss()
                    }
                }
            }
        }
    }
}
