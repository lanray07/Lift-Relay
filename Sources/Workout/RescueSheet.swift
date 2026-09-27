import SwiftUI

struct RescueSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let target: RescueTarget
    @State private var available: Set<Equipment> = []
    @State private var showAnything = false

    private var recommendations: [SubstitutionRecommendation] {
        let equipment = showAnything ? appState.selectedGym.equipment : available
        let context = SubstitutionContext(goal: appState.profile.goal, experience: appState.profile.experience, availableEquipment: equipment, excludedExerciseIDs: appState.profile.restrictions, completedExerciseIDs: completedIDs, preferredExerciseIDs: appState.preferredExerciseIDs)
        return SubstitutionEngine().recommendations(for: target.planned, candidates: ExerciseLibrary.all, context: context)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("rescue.equipmentUnavailable").font(.largeTitle.bold())
                        Text("rescue.subtitle \(target.planned.exercise.name)").foregroundStyle(.secondary)
                    }
                    Text("rescue.available").font(.headline)
                    EquipmentPicker(selection: $available)
                    Toggle("rescue.anything", isOn: $showAnything).tint(Theme.accent)
                    Divider()
                    if recommendations.isEmpty {
                        ContentUnavailableView("rescue.noMatches", systemImage: "magnifyingglass", description: Text("rescue.noMatches.detail"))
                    } else {
                        ForEach(recommendations) { recommendation in
                            RecommendationCard(recommendation: recommendation) {
                                appState.applySubstitution(to: target.id, recommendation: recommendation)
                                dismiss()
                            }
                        }
                    }
                }.padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("action.cancel") { dismiss() } } }
            .onAppear { available = appState.selectedGym.equipment.intersection([.dumbbells, .smithMachine, .resistanceMachine, .cableStation, .resistanceBands, .bodyweight]) }
        }
        .presentationDetents([.large])
    }

    private var completedIDs: Set<UUID> { Set(appState.activeWorkout?.exercises.filter { !$0.sets.isEmpty }.map(\.performed.id) ?? []) }
}

struct EquipmentPicker: View {
    @Binding var selection: Set<Equipment>
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 8) {
            ForEach(Equipment.allCases, id: \.self) { item in
                Button { if selection.contains(item) { selection.remove(item) } else { selection.insert(item) } } label: {
                    HStack { Image(systemName: selection.contains(item) ? "checkmark.circle.fill" : "circle"); Text(LocalizedStringKey("equipment.\(item.rawValue)")); Spacer() }
                        .font(.subheadline.weight(.semibold)).padding(10).background(selection.contains(item) ? Theme.accent.opacity(0.18) : Theme.card, in: RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain)
            }
        }
    }
}

private struct RecommendationCard: View {
    let recommendation: SubstitutionRecommendation
    let action: () -> Void
    var body: some View {
        RelayCard {
            VStack(alignment: .leading, spacing: 9) {
                Text(recommendation.badge.uppercased()).font(.caption2.bold()).foregroundStyle(Theme.accent)
                Text(recommendation.exercise.name).font(.title3.bold())
                Text(recommendation.reason).font(.subheadline).foregroundStyle(.secondary)
                Text("\(recommendation.sets) × \(recommendation.repRange.lowerBound)–\(recommendation.repRange.upperBound)").font(.headline)
                Button("rescue.useSwap", action: action).buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}
