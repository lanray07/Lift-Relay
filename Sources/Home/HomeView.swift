import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                todayCard
                quickActions
                savedTemplates
                insight
            }.padding()
        }
        .relayBackground()
        .navigationTitle("home.title")
        .appSheets($appState.activeSheet)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("home.ready").font(.subheadline).foregroundStyle(.secondary)
                Text(appState.selectedGym.name).font(.headline)
            }
            Spacer()
            Button { appState.activeSheet = .gymProfiles } label: { Image(systemName: "building.2.crop.circle.fill").font(.title2) }
        }
    }

    private var todayCard: some View {
        RelayCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("home.today", systemImage: "bolt.fill").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                Text("PUSH A").font(.system(size: 34, weight: .black, design: .rounded))
                HStack(spacing: 18) {
                    Stat(value: "4", label: "home.exercises")
                    Stat(value: "16", label: "home.sets")
                    Stat(value: "~58", label: "home.minutes")
                }
                Button("home.start") { appState.startSampleWorkout() }
                    .buttonStyle(PrimaryButtonStyle()).accessibilityHint("home.start.hint")
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickAction(title: "home.create", icon: "plus", action: { appState.activeSheet = .createWorkout })
            QuickAction(title: "home.quick", icon: "timer", action: { appState.activeSheet = .quickWorkout })
            QuickAction(title: "home.pro", icon: "crown.fill", action: { appState.activeSheet = .paywall })
        }
    }

    private var insight: some View {
        RelayCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("home.insight").font(.headline)
                    Text("home.insight.empty").font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder private var savedTemplates: some View {
        if !appState.workoutTemplates.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("home.savedWorkouts").font(.headline)
                ForEach(appState.workoutTemplates) { template in
                    Button { appState.startWorkout(from: template) } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(template.name).font(.headline)
                                Text("home.templateExercises \(template.exercises.count)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(Theme.accent)
                        }
                        .padding().background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct Stat: View {
    let value: String; let label: LocalizedStringKey
    var body: some View { VStack(alignment: .leading) { Text(value).font(.title3.bold()); Text(label).font(.caption).foregroundStyle(.secondary) } }
}

private struct QuickAction: View {
    let title: LocalizedStringKey; let icon: String; let action: () -> Void
    var body: some View {
        Button(action: action) { VStack(spacing: 8) { Image(systemName: icon).font(.title3); Text(title).font(.caption.weight(.semibold)).multilineTextAlignment(.center) }.frame(maxWidth: .infinity).padding(.vertical, 14).background(Theme.card, in: RoundedRectangle(cornerRadius: 16)) }.buttonStyle(.plain)
    }
}
