import Foundation

public struct RelayChange: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let original: PlannedExercise
    public let replacement: PlannedExercise
    public let reason: String
}

public struct RelayPlan: Sendable, Equatable {
    public let unchanged: [PlannedExercise]
    public let changes: [RelayChange]
    public let skipped: [PlannedExercise]
    public let estimatedMinutes: Int
}

public struct RelayEngine: Sendable {
    private let substitutionEngine: SubstitutionEngine
    public init(substitutionEngine: SubstitutionEngine = .init()) { self.substitutionEngine = substitutionEngine }

    public func relay(remaining: [PlannedExercise], library: [Exercise], context: SubstitutionContext) -> RelayPlan {
        var unchanged: [PlannedExercise] = []
        var changes: [RelayChange] = []
        var skipped: [PlannedExercise] = []
        var used = context.completedExerciseIDs

        for planned in remaining {
            if planned.exercise.equipment.isSubset(of: context.availableEquipment) {
                unchanged.append(condensed(planned, minutes: context.minutesRemaining))
                used.insert(planned.exercise.id)
                continue
            }
            var nextContext = context
            nextContext.completedExerciseIDs = used
            if let recommendation = substitutionEngine.recommendations(for: planned, candidates: library, context: nextContext, limit: 1).first {
                let replacement = PlannedExercise(exercise: recommendation.exercise, sets: recommendation.sets, repRange: recommendation.repRange, restSeconds: min(planned.restSeconds, 90), previousPerformance: nil)
                changes.append(RelayChange(id: planned.id, original: planned, replacement: replacement, reason: recommendation.reason))
                used.insert(recommendation.exercise.id)
            } else {
                skipped.append(planned)
            }
        }

        let all = unchanged + changes.map(\.replacement)
        let estimate = all.reduce(0) { $0 + max(3, $1.sets * ($1.restSeconds + 45) / 60) }
        return RelayPlan(unchanged: unchanged, changes: changes, skipped: skipped, estimatedMinutes: estimate)
    }

    private func condensed(_ exercise: PlannedExercise, minutes: Int?) -> PlannedExercise {
        guard let minutes, minutes <= 20, exercise.sets > 2 else { return exercise }
        var copy = exercise
        copy.sets -= 1
        copy.restSeconds = min(copy.restSeconds, 90)
        return copy
    }
}
