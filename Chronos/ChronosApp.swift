import SwiftUI

@main
struct ChronosApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(store.theme.accent)
        }
    }
}
