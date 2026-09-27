import Foundation

public struct WorkoutTemplate: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var exercises: [PlannedExercise]
    public var schemaVersion: Int
    public init(id: UUID = UUID(), name: String, exercises: [PlannedExercise], schemaVersion: Int = 1) { self.id = id; self.name = name; self.exercises = exercises; self.schemaVersion = schemaVersion }
}

public struct ExerciseSubstitution: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let plannedExerciseID: UUID
    public let performedExerciseID: UUID
    public let reason: String
    public let score: Double?
    public init(id: UUID = UUID(), plannedExerciseID: UUID, performedExerciseID: UUID, reason: String, score: Double?) { self.id = id; self.plannedExerciseID = plannedExerciseID; self.performedExerciseID = performedExerciseID; self.reason = reason; self.score = score }
}

public struct GymEquipment: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var equipment: Equipment
    public var quantity: Int?
    public init(id: UUID = UUID(), equipment: Equipment, quantity: Int? = nil) { self.id = id; self.equipment = equipment; self.quantity = quantity }
}

public enum CrowdLevel: String, Codable, CaseIterable, Sendable { case quiet, moderate, busy, veryBusy }

public struct CrowdReport: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let gymID: UUID
    public let level: CrowdLevel
    public let unavailableEquipment: Set<Equipment>
    public let createdAt: Date
    public init(id: UUID = UUID(), gymID: UUID, level: CrowdLevel, unavailableEquipment: Set<Equipment>, createdAt: Date = .now) { self.id = id; self.gymID = gymID; self.level = level; self.unavailableEquipment = unavailableEquipment; self.createdAt = createdAt }
}

public struct TrainingRestriction: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var note: String
    public var excludedExerciseIDs: Set<UUID>
    public init(id: UUID = UUID(), note: String, excludedExerciseIDs: Set<UUID> = []) { self.id = id; self.note = note; self.excludedExerciseIDs = excludedExerciseIDs }
}

public struct VoiceCommand: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let transcript: String
    public let createdAt: Date
    public let wasConfirmed: Bool
}

public struct SubscriptionState: Codable, Hashable, Sendable {
    public var activeProductIDs: Set<String>
    public var lastVerifiedAt: Date?
}

public struct UserPreference: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let exerciseID: UUID
    public var selectionCount: Int
}
