import Foundation

public struct WorkoutTemplate: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var exercises: [PlannedExercise]
    public var schemaVersion: Int
    public init(id: UUID = UUID(), name: String, exercises: [PlannedExercise], schemaVersion: Int = 1) { self.id = id; self.name = name; self.exercises = exercises; self.schemaVersion = schemaVersion }
}
