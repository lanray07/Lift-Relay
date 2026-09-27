import SwiftUI

@main
struct LiftRelayApp: App {
    @State private var appState = AppState()
    @State private var subscriptionStore = SubscriptionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(subscriptionStore)
                .task { await subscriptionStore.prepare() }
        }
    }
}
