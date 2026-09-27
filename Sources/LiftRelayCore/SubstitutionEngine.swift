import Foundation

public struct SubstitutionWeights: Sendable, Equatable {
    public var movement: Double = 0.30
    public var muscleOverlap: Double = 0.25
    public var goalCompatibility: Double = 0.15
    public var equipment: Double = 0.15
    public var fatigue: Double = 0.10
    public var preference: Double = 0.05

    public init() {}
}

public struct SubstitutionContext: Sendable {
    public var goal: TrainingGoal
    public var experience: ExperienceLevel
    public var availableEquipment: Set<Equipment>
    public var excludedExerciseIDs: Set<UUID>
    public var completedExerciseIDs: Set<UUID>
    public var preferredExerciseIDs: Set<UUID>
    public var fatigue: Double
    public var minutesRemaining: Int?

    public init(goal: TrainingGoal, experience: ExperienceLevel, availableEquipment: Set<Equipment>, excludedExerciseIDs: Set<UUID> = [], completedExerciseIDs: Set<UUID> = [], preferredExerciseIDs: Set<UUID> = [], fatigue: Double = 0.35, minutesRemaining: Int? = nil) {
        self.goal = goal; self.experience = experience; self.availableEquipment = availableEquipment
        self.excludedExerciseIDs = excludedExerciseIDs; self.completedExerciseIDs = completedExerciseIDs
        self.preferredExerciseIDs = preferredExerciseIDs; self.fatigue = fatigue; self.minutesRemaining = minutesRemaining
    }
}

public struct SubstitutionRecommendation: Identifiable, Sendable, Equatable {
    public var id: UUID { exercise.id }
    public let exercise: Exercise
    public let score: Double
    public let badge: String
    public let reason: String
    public let sets: Int
    public let repRange: ClosedRange<Int>
}

public struct SubstitutionEngine: Sendable {
    public let weights: SubstitutionWeights
    public init(weights: SubstitutionWeights = .init()) { self.weights = weights }

    public func recommendations(for planned: PlannedExercise, candidates: [Exercise], context: SubstitutionContext, limit: Int = 3) -> [SubstitutionRecommendation] {
        candidates
            .filter { $0.id != planned.exercise.id }
            .filter { !context.excludedExerciseIDs.contains($0.id) }
            .filter { !context.completedExerciseIDs.contains($0.id) }
            .filter { $0.equipment.isSubset(of: context.availableEquipment) }
            .filter { experienceRank($0.minimumExperience) <= experienceRank(context.experience) }
            .map { candidate in
                let score = score(candidate, against: planned.exercise, context: context)
                return SubstitutionRecommendation(
                    exercise: candidate,
                    score: score,
                    badge: badge(for: score, candidate: candidate, planned: planned.exercise),
                    reason: explanation(candidate: candidate, planned: planned.exercise),
                    sets: adjustedSets(planned.sets, minutes: context.minutesRemaining),
                    repRange: adjustedReps(planned.repRange, goal: context.goal, fatigue: context.fatigue)
                )
            }
            .filter { $0.score >= 0.42 }
            .sorted { lhs, rhs in lhs.score == rhs.score ? lhs.exercise.name < rhs.exercise.name : lhs.score > rhs.score }
            .prefix(limit)
            .map { $0 }
    }

    private func score(_ candidate: Exercise, against planned: Exercise, context: SubstitutionContext) -> Double {
        let movement = candidate.movement == planned.movement ? 1.0 : 0.15
        let plannedMuscles = planned.primaryMuscles.union(planned.secondaryMuscles)
        let candidateMuscles = candidate.primaryMuscles.union(candidate.secondaryMuscles)
        let overlap = plannedMuscles.isEmpty ? 0 : Double(plannedMuscles.intersection(candidateMuscles).count) / Double(plannedMuscles.count)
        let goal = goalScore(candidate, goal: context.goal)
        let equipment = candidate.equipment.isSubset(of: context.availableEquipment) ? 1.0 : 0.0
        let desiredFatigue = max(0.25, 1.0 - context.fatigue)
        let fatigue = max(0, 1.0 - abs(candidate.fatigueCost - desiredFatigue))
        let preference = context.preferredExerciseIDs.contains(candidate.id) ? 1.0 : 0.5
        return movement * weights.movement + overlap * weights.muscleOverlap + goal * weights.goalCompatibility + equipment * weights.equipment + fatigue * weights.fatigue + preference * weights.preference
    }

    private func goalScore(_ exercise: Exercise, goal: TrainingGoal) -> Double {
        switch goal {
        case .strength: exercise.fatigueCost >= 0.65 ? 1 : 0.70
        case .muscle: (0.40...0.80).contains(exercise.fatigueCost) ? 1 : 0.75
        case .athleticPerformance: exercise.movement == .isolation ? 0.55 : 1
        case .fitness, .maintenance: exercise.fatigueCost <= 0.75 ? 1 : 0.75
        }
    }

    private func experienceRank(_ value: ExperienceLevel) -> Int {
        switch value { case .beginner: 0; case .intermediate: 1; case .advanced: 2 }
    }

    private func badge(for score: Double, candidate: Exercise, planned: Exercise) -> String {
        if score >= 0.86 { return "Best match" }
        if candidate.fatigueCost < planned.fatigueCost - 0.15 { return "Lower fatigue" }
        if candidate.equipment == [.bodyweight] { return "No equipment" }
        return "Strong alternative"
    }

    private func explanation(candidate: Exercise, planned: Exercise) -> String {
        if candidate.movement == planned.movement {
            return "Keeps the same movement pattern and preserves most of the intended muscle work without treating the exercises as identical."
        }
        return "Preserves much of the intended muscle work while adapting to the equipment currently available."
    }

    private func adjustedSets(_ sets: Int, minutes: Int?) -> Int {
        guard let minutes else { return sets }
        return minutes <= 20 ? max(2, sets - 1) : sets
    }

    private func adjustedReps(_ range: ClosedRange<Int>, goal: TrainingGoal, fatigue: Double) -> ClosedRange<Int> {
        if fatigue > 0.75 { return max(8, range.lowerBound)...max(12, range.upperBound) }
        if goal == .strength { return min(range.lowerBound, 5)...min(max(range.upperBound, 6), 8) }
        return range
    }
}
