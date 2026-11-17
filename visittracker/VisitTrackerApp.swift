import SwiftUI

@main
struct VisitTrackerApp: App {
    @StateObject private var store = Store()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear { NotificationManager.requestPermission() }
                .onChange(of: phase) { if $0 == .active { store.rescheduleNotifications() } }
        }
    }
}
