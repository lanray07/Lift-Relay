import Foundation

public enum ExerciseLibrary {
    public static let all: [Exercise] = [
        Exercise(name: "Barbell Back Squat", movement: .squat, primaryMuscles: [.quadriceps, .glutes], secondaryMuscles: [.hamstrings, .core], equipment: [.barbell, .squatRack], minimumExperience: .intermediate, fatigueCost: 0.90),
        Exercise(name: "Goblet Squat", movement: .squat, primaryMuscles: [.quadriceps, .glutes], secondaryMuscles: [.core], equipment: [.dumbbells], fatigueCost: 0.55),
        Exercise(name: "Leg Press", movement: .squat, primaryMuscles: [.quadriceps, .glutes], secondaryMuscles: [.hamstrings], equipment: [.legPress], fatigueCost: 0.65),
        Exercise(name: "Smith Machine Squat", movement: .squat, primaryMuscles: [.quadriceps, .glutes], secondaryMuscles: [.hamstrings], equipment: [.smithMachine], fatigueCost: 0.70),
        Exercise(name: "Barbell Bench Press", movement: .horizontalPush, primaryMuscles: [.chest], secondaryMuscles: [.triceps, .shoulders], equipment: [.barbell, .bench], minimumExperience: .intermediate, fatigueCost: 0.78),
        Exercise(name: "Dumbbell Bench Press", movement: .horizontalPush, primaryMuscles: [.chest], secondaryMuscles: [.triceps, .shoulders], equipment: [.dumbbells, .bench], fatigueCost: 0.68),
        Exercise(name: "Machine Chest Press", movement: .horizontalPush, primaryMuscles: [.chest], secondaryMuscles: [.triceps, .shoulders], equipment: [.resistanceMachine], fatigueCost: 0.52),
        Exercise(name: "Weighted Push-Up", movement: .horizontalPush, primaryMuscles: [.chest], secondaryMuscles: [.triceps, .shoulders, .core], equipment: [.bodyweight], fatigueCost: 0.48),
        Exercise(name: "Seated Cable Row", movement: .horizontalPull, primaryMuscles: [.back], secondaryMuscles: [.biceps], equipment: [.cableStation], fatigueCost: 0.52),
        Exercise(name: "One-Arm Dumbbell Row", movement: .horizontalPull, primaryMuscles: [.back], secondaryMuscles: [.biceps, .core], equipment: [.dumbbells, .bench], fatigueCost: 0.58),
        Exercise(name: "Chest-Supported Machine Row", movement: .horizontalPull, primaryMuscles: [.back], secondaryMuscles: [.biceps], equipment: [.resistanceMachine], fatigueCost: 0.45),
        Exercise(name: "Romanian Deadlift", movement: .hinge, primaryMuscles: [.hamstrings, .glutes], secondaryMuscles: [.back, .core], equipment: [.barbell], minimumExperience: .intermediate, fatigueCost: 0.82),
        Exercise(name: "Dumbbell Romanian Deadlift", movement: .hinge, primaryMuscles: [.hamstrings, .glutes], secondaryMuscles: [.back, .core], equipment: [.dumbbells], fatigueCost: 0.68),
        Exercise(name: "Cable Pull-Through", movement: .hinge, primaryMuscles: [.glutes, .hamstrings], secondaryMuscles: [.core], equipment: [.cableStation], fatigueCost: 0.45)
    ]

    public static func named(_ name: String) -> Exercise { all.first { $0.name == name }! }
}
