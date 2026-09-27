import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        Form {
            Section("settings.training") {
                Picker("settings.units", selection: $appState.profile.preferredUnit) {
                    Text("unit.kg").tag(WeightUnit.kilograms)
                    Text("unit.lb").tag(WeightUnit.pounds)
                }
                Button("gyms.title") { appState.activeSheet = .gymProfiles }
                Button("settings.subscription") { appState.activeSheet = .paywall }
            }
            Section("settings.privacy") {
                Toggle("settings.ai", isOn: .constant(true))
                Toggle("settings.crowd", isOn: .constant(false))
                Button("settings.export") {}
                Button("settings.deleteHistory", role: .destructive) { appState.history = []; appState.persist() }
            }
            Section("settings.about") {
                Text("settings.medicalDisclaimer").font(.footnote).foregroundStyle(.secondary)
                Link("legal.privacy", destination: URL(string: "https://liftrelay.app/privacy")!)
                Link("legal.terms", destination: URL(string: "https://liftrelay.app/terms")!)
            }
            Section { Button("settings.replayOnboarding") { appState.resetOnboarding() } }
        }
        .navigationTitle("settings.title")
        .sheet(item: $appState.activeSheet) { sheet in
            switch sheet {
            case .gymProfiles: GymProfilesView()
            case .paywall: PaywallView()
            case .createWorkout: WorkoutBuilderView(isQuick: false)
            case .quickWorkout: WorkoutBuilderView(isQuick: true)
            }
        }
        .onChange(of: appState.profile.preferredUnit) { _, _ in appState.persist() }
    }
}
