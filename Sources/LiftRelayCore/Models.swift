import Foundation

public enum TrainingGoal: String, Codable, CaseIterable, Sendable {
    case muscle, strength, fitness, athleticPerformance, maintenance
}

public enum ExperienceLevel: String, Codable, CaseIterable, Sendable {
    case beginner, intermediate, advanced
}

public enum Equipment: String, Codable, CaseIterable, Hashable, Sendable {
    case barbell, dumbbells, squatRack, bench, smithMachine, cableStation
    case resistanceMachine, kettlebell, resistanceBands, pullUpStation, cardio, bodyweight, legPress
}

public enum MovementPattern: String, Codable, CaseIterable, Sendable {
    case squat, hinge, horizontalPush, verticalPush, horizontalPull, verticalPull, lunge, carry, isolation, cardio
}

public enum MuscleGroup: String, Codable, CaseIterable, Hashable, Sendable {
    case chest, back, shoulders, biceps, triceps, quadriceps, hamstrings, glutes, calves, core
}

public struct Exercise: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var movement: MovementPattern
    public var primaryMuscles: Set<MuscleGroup>
    public var secondaryMuscles: Set<MuscleGroup>
    public var equipment: Set<Equipment>
    public var minimumExperience: ExperienceLevel
    public var fatigueCost: Double

    public init(id: UUID = UUID(), name: String, movement: MovementPattern, primaryMuscles: Set<MuscleGroup>, secondaryMuscles: Set<MuscleGroup> = [], equipment: Set<Equipment>, minimumExperience: ExperienceLevel = .beginner, fatigueCost: Double) {
        self.id = id; self.name = name; self.movement = movement; self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles; self.equipment = equipment
        self.minimumExperience = minimumExperience; self.fatigueCost = fatigueCost
    }
}

public struct PlannedExercise: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var exercise: Exercise
    public var sets: Int
    public var repRange: ClosedRange<Int>
    public var restSeconds: Int
    public var previousPerformance: String?

    public init(id: UUID = UUID(), exercise: Exercise, sets: Int, repRange: ClosedRange<Int>, restSeconds: Int, previousPerformance: String? = nil) {
        self.id = id; self.exercise = exercise; self.sets = sets; self.repRange = repRange
        self.restSeconds = restSeconds; self.previousPerformance = previousPerformance
    }
}

public struct LoggedSet: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var reps: Int
    public var kilograms: Double
    public var rpe: Double?
    public var completedAt: Date

    public init(id: UUID = UUID(), reps: Int, kilograms: Double, rpe: Double? = nil, completedAt: Date = .now) {
        self.id = id; self.reps = reps; self.kilograms = kilograms; self.rpe = rpe; self.completedAt = completedAt
    }
}

public struct PerformedExercise: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var planned: PlannedExercise
    public var performed: Exercise
    public var substitutionReason: String?
    public var sets: [LoggedSet]
    public var isSkipped: Bool

    public init(id: UUID = UUID(), planned: PlannedExercise, performed: Exercise? = nil, substitutionReason: String? = nil, sets: [LoggedSet] = [], isSkipped: Bool = false) {
        self.id = id; self.planned = planned; self.performed = performed ?? planned.exercise
        self.substitutionReason = substitutionReason; self.sets = sets; self.isSkipped = isSkipped
    }
}

public struct WorkoutSession: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var startedAt: Date
    public var endedAt: Date?
    public var exercises: [PerformedExercise]
    public var notes: String

    public init(id: UUID = UUID(), name: String, startedAt: Date = .now, endedAt: Date? = nil, exercises: [PerformedExercise], notes: String = "") {
        self.id = id; self.name = name; self.startedAt = startedAt; self.endedAt = endedAt; self.exercises = exercises; self.notes = notes
    }
}

public struct UserProfile: Codable, Hashable, Sendable {
    public var goal: TrainingGoal
    public var experience: ExperienceLevel
    public var trainingDaysPerWeek: Int
    public var typicalEquipment: Set<Equipment>
    public var restrictions: Set<UUID>
    public var preferredUnit: WeightUnit
}

public enum WeightUnit: String, Codable, CaseIterable, Sendable { case kilograms, pounds }

public struct GymProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var equipment: Set<Equipment>
    public init(id: UUID = UUID(), name: String, equipment: Set<Equipment>) { self.id = id; self.name = name; self.equipment = equipment }
}
