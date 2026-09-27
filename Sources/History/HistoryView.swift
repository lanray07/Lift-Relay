import Charts
import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if appState.history.isEmpty {
                    ContentUnavailableView("history.empty", systemImage: "chart.bar.xaxis", description: Text("history.empty.detail"))
                        .frame(minHeight: 420)
                } else {
                    summary
                    ForEach(appState.history) { workout in WorkoutHistoryCard(workout: workout) }
                }
            }.padding()
        }
        .relayBackground().navigationTitle("history.title")
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
}

private struct WorkoutHistoryCard: View {
    let workout: WorkoutSession
    var body: some View {
        RelayCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack { Text(workout.name).font(.title3.bold()); Spacer(); Text(workout.startedAt, style: .date).font(.caption).foregroundStyle(.secondary) }
                Text("history.completedSets \(workout.exercises.flatMap(\.sets).count)").font(.subheadline)
                ForEach(workout.exercises.filter { $0.performed != $0.planned.exercise }) { item in
                    Label("\(item.planned.exercise.name) → \(item.performed.name)", systemImage: "arrow.triangle.swap").font(.caption).foregroundStyle(.orange)
                }
            }
        }
    }
}
