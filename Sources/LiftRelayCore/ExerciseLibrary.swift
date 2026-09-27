import Foundation

public enum ExerciseLibrary {
    public static let barbellBackSquat = exercise("00000000-0000-0000-0000-000000000001", name: "Barbell Back Squat", movement: .squat, primaryMuscles: [.quadriceps, .glutes], secondaryMuscles: [.hamstrings, .core], equipment: [.barbell, .squatRack], minimumExperience: .intermediate, fatigueCost: 0.90)
    public static let gobletSquat = exercise("00000000-0000-0000-0000-000000000002", name: "Goblet Squat", movement: .squat, primaryMuscles: [.quadriceps, .glutes], secondaryMuscles: [.core], equipment: [.dumbbells], fatigueCost: 0.55)
    public static let legPress = exercise("00000000-0000-0000-0000-000000000003", name: "Leg Press", movement: .squat, primaryMuscles: [.quadriceps, .glutes], secondaryMuscles: [.hamstrings], equipment: [.legPress], fatigueCost: 0.65)
    public static let smithMachineSquat = exercise("00000000-0000-0000-0000-000000000004", name: "Smith Machine Squat", movement: .squat, primaryMuscles: [.quadriceps, .glutes], secondaryMuscles: [.hamstrings], equipment: [.smithMachine], fatigueCost: 0.70)
    public static let barbellBenchPress = exercise("00000000-0000-0000-0000-000000000005", name: "Barbell Bench Press", movement: .horizontalPush, primaryMuscles: [.chest], secondaryMuscles: [.triceps, .shoulders], equipment: [.barbell, .bench], minimumExperience: .intermediate, fatigueCost: 0.78)
    public static let dumbbellBenchPress = exercise("00000000-0000-0000-0000-000000000006", name: "Dumbbell Bench Press", movement: .horizontalPush, primaryMuscles: [.chest], secondaryMuscles: [.triceps, .shoulders], equipment: [.dumbbells, .bench], fatigueCost: 0.68)
    public static let machineChestPress = exercise("00000000-0000-0000-0000-000000000007", name: "Machine Chest Press", movement: .horizontalPush, primaryMuscles: [.chest], secondaryMuscles: [.triceps, .shoulders], equipment: [.resistanceMachine], fatigueCost: 0.52)
    public static let weightedPushUp = exercise("00000000-0000-0000-0000-000000000008", name: "Weighted Push-Up", movement: .horizontalPush, primaryMuscles: [.chest], secondaryMuscles: [.triceps, .shoulders, .core], equipment: [.bodyweight], fatigueCost: 0.48)
    public static let seatedCableRow = exercise("00000000-0000-0000-0000-000000000009", name: "Seated Cable Row", movement: .horizontalPull, primaryMuscles: [.back], secondaryMuscles: [.biceps], equipment: [.cableStation], fatigueCost: 0.52)
    public static let oneArmDumbbellRow = exercise("00000000-0000-0000-0000-000000000010", name: "One-Arm Dumbbell Row", movement: .horizontalPull, primaryMuscles: [.back], secondaryMuscles: [.biceps, .core], equipment: [.dumbbells, .bench], fatigueCost: 0.58)
    public static let chestSupportedMachineRow = exercise("00000000-0000-0000-0000-000000000011", name: "Chest-Supported Machine Row", movement: .horizontalPull, primaryMuscles: [.back], secondaryMuscles: [.biceps], equipment: [.resistanceMachine], fatigueCost: 0.45)
    public static let romanianDeadlift = exercise("00000000-0000-0000-0000-000000000012", name: "Romanian Deadlift", movement: .hinge, primaryMuscles: [.hamstrings, .glutes], secondaryMuscles: [.back, .core], equipment: [.barbell], minimumExperience: .intermediate, fatigueCost: 0.82)
    public static let dumbbellRomanianDeadlift = exercise("00000000-0000-0000-0000-000000000013", name: "Dumbbell Romanian Deadlift", movement: .hinge, primaryMuscles: [.hamstrings, .glutes], secondaryMuscles: [.back, .core], equipment: [.dumbbells], fatigueCost: 0.68)
    public static let cablePullThrough = exercise("00000000-0000-0000-0000-000000000014", name: "Cable Pull-Through", movement: .hinge, primaryMuscles: [.glutes, .hamstrings], secondaryMuscles: [.core], equipment: [.cableStation], fatigueCost: 0.45)

    public static let all: [Exercise] = [
        barbellBackSquat, gobletSquat, legPress, smithMachineSquat,
        barbellBenchPress, dumbbellBenchPress, machineChestPress, weightedPushUp,
        seatedCableRow, oneArmDumbbellRow, chestSupportedMachineRow,
        romanianDeadlift, dumbbellRomanianDeadlift, cablePullThrough
    ]

    public static func named(_ name: String) -> Exercise? { all.first { $0.name == name } }

    private static func exercise(
        _ identifier: String,
        name: String,
        movement: MovementPattern,
        primaryMuscles: Set<MuscleGroup>,
        secondaryMuscles: Set<MuscleGroup> = [],
        equipment: Set<Equipment>,
        minimumExperience: ExperienceLevel = .beginner,
        fatigueCost: Double
    ) -> Exercise {
        guard let id = UUID(uuidString: identifier) else {
            preconditionFailure("Invalid stable exercise identifier: \(identifier)")
        }
        return Exercise(id: id, name: name, movement: movement, primaryMuscles: primaryMuscles, secondaryMuscles: secondaryMuscles, equipment: equipment, minimumExperience: minimumExperience, fatigueCost: fatigueCost)
    }
}
