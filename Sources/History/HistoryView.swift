import Charts
import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionStore.self) private var subscriptionStore

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if appState.history.isEmpty {
                    ContentUnavailableView("history.empty", systemImage: "chart.bar.xaxis", description: Text("history.empty.detail"))
                        .frame(minHeight: 420)
                } else {
                    if subscriptionStore.isPro { summary } else { proHistoryPrompt }
                    ForEach(appState.history) { workout in WorkoutHistoryCard(workout: workout, unit: appState.profile.preferredUnit) }
                }
            }.padding()
        }
        .relayBackground().navigationTitle("history.title")
        .appSheets($appState.activeSheet)
    }

    private var summary: some View {
        RelayCard {
            VStack(alignment: .leading) {
                Text("history.volume").font(.headline)
                Chart(Array(appState.history.prefix(7))) { workout in
                    BarMark(x: .value("Date", workout.startedAt, unit: .day), y: .value("Volume", volume(workout)))
                        .foregroundStyle(Theme.accent.gradient)
                }.frame(height: 150)
                Text("history.estimateNote").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func volume(_ workout: WorkoutSession) -> Double { workout.exercises.flatMap(\.sets).reduce(0) { $0 + Double($1.reps) * $1.kilograms } }

    private var proHistoryPrompt: some View {
        RelayCard {
            HStack {
                Label("history.proInsight", systemImage: "chart.xyaxis.line").font(.headline)
                Spacer()
                Button("history.unlock") { appState.activeSheet = .paywall }.buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct WorkoutHistoryCard: View {
    let workout: WorkoutSession
    let unit: WeightUnit
    var body: some View {
        RelayCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack { Text(workout.name).font(.title3.bold()); Spacer(); Text(workout.startedAt, style: .date).font(.caption).foregroundStyle(.secondary) }
                Text("history.completedSets \(workout.exercises.flatMap(\.sets).count)").font(.subheadline)
                ForEach(workout.exercises) { item in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.performed.name).font(.subheadline.weight(.semibold))
                        if item.performed != item.planned.exercise {
                            Label("\(item.planned.exercise.name) → \(item.performed.name)", systemImage: "arrow.triangle.swap").font(.caption).foregroundStyle(.orange)
                        }
                        if item.isSkipped {
                            Text("history.skipped").font(.caption).foregroundStyle(.secondary)
                        } else if !item.sets.isEmpty {
                            Text(item.sets.map { "\($0.reps) × \(WeightConverter.display(kilograms: $0.kilograms, unit: unit), format: .number.precision(.fractionLength(0...1))) \(unit == .kilograms ? "kg" : "lb")" }.joined(separator: " • "))
                                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
