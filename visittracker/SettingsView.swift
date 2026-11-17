import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Settings.limitKey) private var limit = 45
    @AppStorage(Settings.templateKey) private var template = Settings.defaultTemplate

    var body: some View {
        NavigationView {
            Form {
                Section("مدة التنبيه") {
                    Stepper("التنبيه بعد \(limit) يوم", value: $limit, in: 1...365)
                }
                Section(header: Text("نص الرسالة الافتراضي"),
                        footer: Text("استخدم {name} لإدراج اسم الشخص.")) {
                    TextEditor(text: $template).frame(minHeight: 100)
                }
            }
            .navigationTitle("الإعدادات")
            .toolbar {
                Button("تم") { store.rescheduleNotifications(); dismiss() }
            }
        }
    }
}
