import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var hasCompletedOnboarding: Bool
    var profile: UserProfile
    var gyms: [GymProfile]
    var selectedGymID: UUID?
    var activeWorkout: WorkoutSession?
    var history: [WorkoutSession]
    var workoutTemplates: [WorkoutTemplate]
    var activeSheet: AppSheet?
    var preferredExerciseIDs: Set<UUID> = []

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedOnboarding = defaults.bool(forKey: "onboarding.complete")
        profile = Self.load(UserProfile.self, key: "profile", defaults: defaults) ?? .sample
        let restoredGyms = Self.load([GymProfile].self, key: "gyms", defaults: defaults) ?? [.commercialGym]
        gyms = restoredGyms
        let restoredGymID = Self.load(UUID.self, key: "selectedGymID", defaults: defaults)
        selectedGymID = restoredGyms.contains(where: { $0.id == restoredGymID }) ? restoredGymID : restoredGyms.first?.id
        activeWorkout = Self.load(WorkoutSession.self, key: "activeWorkout", defaults: defaults)
        history = Self.load([WorkoutSession].self, key: "history", defaults: defaults) ?? []
        workoutTemplates = Self.load([WorkoutTemplate].self, key: "workoutTemplates", defaults: defaults) ?? []
        preferredExerciseIDs = Self.load(Set<UUID>.self, key: "preferredExerciseIDs", defaults: defaults) ?? []
    }

    var selectedGym: GymProfile { gyms.first(where: { $0.id == selectedGymID }) ?? gyms.first ?? .commercialGym }

    func finishOnboarding(profile: UserProfile) {
        self.profile = profile
        hasCompletedOnboarding = true
        defaults.set(true, forKey: "onboarding.complete")
        persist()
    }

    func startSampleWorkout() {
        startWorkout(name: "PUSH A", exercises: SampleData.pushWorkout)
    }

    func startWorkout(name: String, exercises: [PlannedExercise]) {
        activeWorkout = WorkoutSession(name: name, exercises: exercises.map { PerformedExercise(planned: $0) })
        persist()
        AnalyticsClient.shared.track(.workoutStarted)
    }

    func startWorkout(from template: WorkoutTemplate) {
        startWorkout(name: template.name, exercises: template.exercises)
    }

    func saveTemplate(name: String, exercises: [PlannedExercise]) {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, !exercises.isEmpty else { return }
        workoutTemplates.removeAll { $0.name.caseInsensitiveCompare(normalized) == .orderedSame }
        workoutTemplates.insert(WorkoutTemplate(name: normalized, exercises: exercises), at: 0)
        persist()
    }

    func logSet(exerciseID: UUID, reps: Int, displayedWeight: Double) {
        guard let index = activeWorkout?.exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        let kilograms = WeightConverter.kilograms(from: displayedWeight, unit: profile.preferredUnit)
        activeWorkout?.exercises[index].sets.append(LoggedSet(reps: reps, kilograms: kilograms))
        persist()
    }

    func applySubstitution(to performedID: UUID, recommendation: SubstitutionRecommendation) {
        guard let index = activeWorkout?.exercises.firstIndex(where: { $0.id == performedID }) else { return }
        activeWorkout?.exercises[index].performed = recommendation.exercise
        activeWorkout?.exercises[index].substitutionReason = "Equipment unavailable"
        preferredExerciseIDs.insert(recommendation.exercise.id)
        persist()
        AnalyticsClient.shared.track(.substitutionSelected)
    }

    func acceptRelay(_ plan: RelayPlan) {
        guard var workout = activeWorkout else { return }
        for change in plan.changes {
            guard let index = workout.exercises.firstIndex(where: { $0.planned.id == change.original.id }) else { continue }
            workout.exercises[index].performed = change.replacement.exercise
            workout.exercises[index].substitutionReason = "Relay Mode: equipment unavailable"
        }
        activeWorkout = workout
        persist()
        AnalyticsClient.shared.track(.relayAccepted)
    }

    func applyTimeRescue(minutes: Int) {
        guard var workout = activeWorkout else { return }
        let incomplete = workout.exercises.indices.filter { workout.exercises[$0].sets.count < workout.exercises[$0].planned.sets }
        let keepCount = minutes <= 15 ? 2 : minutes <= 30 ? 3 : incomplete.count
        for (position, index) in incomplete.enumerated() {
            if position >= keepCount {
                workout.exercises[index].isSkipped = true
            } else {
                let completed = workout.exercises[index].sets.count
                workout.exercises[index].planned.sets = max(completed + 1, min(workout.exercises[index].planned.sets, minutes <= 20 ? 3 : 4))
                workout.exercises[index].planned.restSeconds = min(workout.exercises[index].planned.restSeconds, 90)
            }
        }
        activeWorkout = workout
        persist()
        AnalyticsClient.shared.track(.timeRescueUsed)
    }

    func finishWorkout() {
        guard var workout = activeWorkout else { return }
        workout.endedAt = .now
        history.insert(workout, at: 0)
        activeWorkout = nil
        persist()
        AnalyticsClient.shared.track(.workoutCompleted)
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        defaults.set(false, forKey: "onboarding.complete")
    }

    func persist() {
        if let data = try? encoder.encode(profile) { defaults.set(data, forKey: "profile") }
        if let data = try? encoder.encode(gyms) { defaults.set(data, forKey: "gyms") }
        if let data = try? encoder.encode(selectedGymID) { defaults.set(data, forKey: "selectedGymID") }
        if let data = try? encoder.encode(activeWorkout) { defaults.set(data, forKey: "activeWorkout") }
        else { defaults.removeObject(forKey: "activeWorkout") }
        if let data = try? encoder.encode(history) { defaults.set(data, forKey: "history") }
        if let data = try? encoder.encode(workoutTemplates) { defaults.set(data, forKey: "workoutTemplates") }
        if let data = try? encoder.encode(preferredExerciseIDs) { defaults.set(data, forKey: "preferredExerciseIDs") }
    }

    func exportData() throws -> Data {
        let export = WorkoutDataExport(exportedAt: .now, profile: profile, gyms: gyms, templates: workoutTemplates, activeWorkout: activeWorkout, history: history)
        let exportEncoder = JSONEncoder()
        exportEncoder.dateEncodingStrategy = .iso8601
        exportEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try exportEncoder.encode(export)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

enum AppSheet: Identifiable {
    case createWorkout, quickWorkout, gymProfiles, paywall
    var id: String { String(describing: self) }
}

extension UserProfile {
    static let sample = UserProfile(goal: .muscle, experience: .intermediate, trainingDaysPerWeek: 4, typicalEquipment: Set(Equipment.allCases), restrictions: [], preferredUnit: .kilograms)
}

extension GymProfile {
    static let commercialGym = GymProfile(name: "Home Gym", equipment: Set(Equipment.allCases))
}

enum SampleData {
    static let pushWorkout: [PlannedExercise] = [
        PlannedExercise(exercise: ExerciseLibrary.barbellBenchPress, sets: 4, repRange: 6...6, restSeconds: 120, previousPerformance: "80 kg × 6, 6, 6, 5"),
        PlannedExercise(exercise: ExerciseLibrary.seatedCableRow, sets: 4, repRange: 8...10, restSeconds: 90, previousPerformance: "64 kg × 10, 10, 9, 8"),
        PlannedExercise(exercise: ExerciseLibrary.dumbbellBenchPress, sets: 4, repRange: 8...10, restSeconds: 90, previousPerformance: "30 kg × 10, 9, 8"),
        PlannedExercise(exercise: ExerciseLibrary.cablePullThrough, sets: 4, repRange: 10...12, restSeconds: 75, previousPerformance: "41 kg × 12, 12, 11")
    ]
}

private struct WorkoutDataExport: Encodable {
    let exportedAt: Date
    let profile: UserProfile
    let gyms: [GymProfile]
    let templates: [WorkoutTemplate]
    let activeWorkout: WorkoutSession?
    let history: [WorkoutSession]
}
