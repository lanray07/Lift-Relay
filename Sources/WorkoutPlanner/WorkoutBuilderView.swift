import SwiftUI

struct WorkoutBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let isQuick: Bool
    @State private var name = "MY WORKOUT"
    @State private var selected: Set<UUID> = []

    private var availableExercises: [Exercise] {
        ExerciseLibrary.all.filter { $0.equipment.isSubset(of: appState.selectedGym.equipment) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !isQuick { Section("builder.details") { TextField("builder.name", text: $name) } }
                Section("builder.exercises") {
                    ForEach(availableExercises) { exercise in
                        Button { toggle(exercise.id) } label: {
                            HStack { VStack(alignment: .leading) { Text(exercise.name); Text(exercise.movement.rawValue).font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: selected.contains(exercise.id) ? "checkmark.circle.fill" : "circle") }
                        }.foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle(isQuick ? "home.quick" : "home.create")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("action.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("builder.start") { start() }.disabled(selected.isEmpty) }
            }
            .onAppear { if isQuick { selected = Set(availableExercises.prefix(3).map(\.id)); name = "QUICK WORKOUT" } }
        }
    }

    private func toggle(_ id: UUID) { if selected.contains(id) { selected.remove(id) } else { selected.insert(id) } }
    private func start() {
        let exercises = availableExercises.filter { selected.contains($0.id) }.map { PlannedExercise(exercise: $0, sets: 3, repRange: 8...12, restSeconds: 90) }
        dismiss()
        appState.startWorkout(name: name.isEmpty ? "MY WORKOUT" : name, exercises: exercises)
    }
}
