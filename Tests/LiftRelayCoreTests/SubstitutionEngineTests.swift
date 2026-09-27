import XCTest
#if canImport(LiftRelayCore)
@testable import LiftRelayCore
#else
@testable import LiftRelay
#endif

final class SubstitutionEngineTests: XCTestCase {
    func testUnavailableEquipmentIsNeverRecommended() throws {
        let planned = PlannedExercise(exercise: try XCTUnwrap(ExerciseLibrary.named("Barbell Bench Press")), sets: 4, repRange: 6...6, restSeconds: 120)
        let context = SubstitutionContext(goal: .strength, experience: .intermediate, availableEquipment: [.bodyweight])
        let results = SubstitutionEngine().recommendations(for: planned, candidates: ExerciseLibrary.all, context: context)
        XCTAssertEqual(results.first?.exercise.name, "Weighted Push-Up")
        XCTAssertTrue(results.allSatisfy { $0.exercise.equipment.isSubset(of: context.availableEquipment) })
    }

    func testRestrictionsAreHardConstraints() throws {
        let planned = PlannedExercise(exercise: try XCTUnwrap(ExerciseLibrary.named("Barbell Back Squat")), sets: 4, repRange: 6...8, restSeconds: 120)
        let goblet = try XCTUnwrap(ExerciseLibrary.named("Goblet Squat"))
        let context = SubstitutionContext(goal: .muscle, experience: .intermediate, availableEquipment: [.dumbbells, .legPress], excludedExerciseIDs: [goblet.id])
        let results = SubstitutionEngine().recommendations(for: planned, candidates: ExerciseLibrary.all, context: context)
        XCTAssertFalse(results.contains { $0.exercise.id == goblet.id })
        XCTAssertEqual(results.first?.exercise.name, "Leg Press")
    }

    func testRelayPreservesAvailableExerciseAndReplacesUnavailableOne() throws {
        let bench = PlannedExercise(exercise: try XCTUnwrap(ExerciseLibrary.named("Barbell Bench Press")), sets: 4, repRange: 6...6, restSeconds: 120)
        let hinge = PlannedExercise(exercise: try XCTUnwrap(ExerciseLibrary.named("Romanian Deadlift")), sets: 3, repRange: 8...10, restSeconds: 90)
        let context = SubstitutionContext(goal: .muscle, experience: .intermediate, availableEquipment: [.dumbbells, .bench])
        let relay = RelayEngine().relay(remaining: [bench, hinge], library: ExerciseLibrary.all, context: context)
        XCTAssertEqual(relay.changes.count, 2)
        XCTAssertTrue(relay.changes.allSatisfy { $0.replacement.exercise.equipment.isSubset(of: context.availableEquipment) })
    }

    func testWeightRoundTripPreservesUnderlyingValue() {
        let pounds = WeightConverter.display(kilograms: 80, unit: .pounds)
        XCTAssertEqual(WeightConverter.kilograms(from: pounds, unit: .pounds), 80, accuracy: 0.000_001)
    }

    func testVoiceCommandParsesSpokenNumbers() {
        XCTAssertEqual(VoiceCommandParser().parse("Log eight reps at eighty kilos"), .logSet(reps: 8, weight: 80))
        XCTAssertEqual(VoiceCommandParser().parse("I only have twenty minutes left"), .timeRescue(minutes: 20))
    }

    func testExerciseIdentifiersAreStable() {
        XCTAssertEqual(ExerciseLibrary.barbellBenchPress.id.uuidString, "00000000-0000-0000-0000-000000000005")
        XCTAssertNil(ExerciseLibrary.named("Renamed or missing exercise"))
    }
}
