import SwiftUI

struct RelayModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var available: Set<Equipment> = []

    private var plan: RelayPlan? {
        guard let workout = appState.activeWorkout else { return nil }
        let remaining = workout.exercises.filter { $0.sets.count < $0.planned.sets && !$0.isSkipped }.map(\.planned)
        let context = SubstitutionContext(goal: appState.profile.goal, experience: appState.profile.experience, availableEquipment: available, excludedExerciseIDs: appState.profile.restrictions, completedExerciseIDs: Set(workout.exercises.filter { !$0.sets.isEmpty }.map(\.performed.id)), preferredExerciseIDs: appState.preferredExerciseIDs)
        return RelayEngine().relay(remaining: remaining, library: ExerciseLibrary.all, context: context)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("relay.headline").font(.largeTitle.bold())
                    Text("relay.subtitle").foregroundStyle(.secondary)
                    Text("relay.availableNow").font(.headline)
                    EquipmentPicker(selection: $available)
                    if let plan {
                        HStack { Text("relay.estimated"); Spacer(); Text("~\(plan.estimatedMinutes) min").fontWeight(.bold) }.padding(.top)
                        ForEach(plan.changes) { change in
                            RelayCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label(change.original.exercise.name, systemImage: "xmark.circle").foregroundStyle(.secondary)
                                    Image(systemName: "arrow.down").foregroundStyle(Theme.accent)
                                    Label(change.replacement.exercise.name, systemImage: "checkmark.circle.fill").font(.headline)
                                    Text(change.reason).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        ForEach(plan.unchanged) { item in Label("relay.kept \(item.exercise.name)", systemImage: "equal.circle").font(.subheadline) }
                        Button("relay.accept") { appState.acceptRelay(plan); dismiss() }.buttonStyle(PrimaryButtonStyle()).disabled(plan.changes.isEmpty)
                    }
                }.padding()
            }
            .relayBackground()
            .navigationTitle("relay.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("action.cancel") { dismiss() } } }
            .onAppear { available = appState.selectedGym.equipment }
        }
    }
}
