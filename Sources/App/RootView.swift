import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if appState.activeWorkout != nil {
                ActiveWorkoutView()
            } else {
                MainTabView()
            }
        }
        .tint(Theme.accent)
        .preferredColorScheme(nil)
        .animation(.snappy, value: appState.hasCompletedOnboarding)
        .animation(.snappy, value: appState.activeWorkout?.id)
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("tab.home", systemImage: "house.fill") }
            NavigationStack { HistoryView() }
                .tabItem { Label("tab.history", systemImage: "chart.xyaxis.line") }
            NavigationStack { SettingsView() }
                .tabItem { Label("tab.settings", systemImage: "gearshape.fill") }
        }
    }
}
