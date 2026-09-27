import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedRescue: RescueTarget?
    @State private var showsRelay = false
    @State private var showsTimeRescue = false
    @State private var showsFinishConfirmation = false
    @State private var showsVoice = false
    @State private var restDeadline: Date?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    workoutSummary
                    if let workout = appState.activeWorkout {
                        ForEach(workout.exercises) { exercise in
                            ExerciseCard(performed: exercise, unit: appState.profile.preferredUnit, onLog: { reps, weight in
                                appState.logSet(exerciseID: exercise.id, reps: reps, displayedWeight: weight)
                                restDeadline = .now.addingTimeInterval(TimeInterval(exercise.planned.restSeconds))
                            }, onUnavailable: {
                                AnalyticsClient.shared.track(.equipmentUnavailable)
                                selectedRescue = RescueTarget(id: exercise.id, planned: exercise.planned)
                            })
                        }
                    }
                }.padding()
            }
            .relayBackground()
            .navigationTitle(appState.activeWorkout?.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("workout.end") { showsFinishConfirmation = true } }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showsTimeRescue = true } label: { Image(systemName: "timer") }.accessibilityLabel("timeRescue.title")
                    Button { showsRelay = true; AnalyticsClient.shared.track(.relayStarted) } label: { Label("relay.title", systemImage: "arrow.triangle.2.circlepath") }.labelStyle(.iconOnly)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let deadline = restDeadline { RestTimerBar(deadline: deadline) { restDeadline = nil } }
            }
            .sheet(item: $selectedRescue) { target in RescueSheet(target: target) }
            .sheet(isPresented: $showsRelay) { RelayModeView() }
            .sheet(isPresented: $showsTimeRescue) { TimeRescueView() }
            .sheet(isPresented: $showsVoice) { VoiceCommandSheet(onConfirm: handleVoice) }
            .confirmationDialog("workout.finish.title", isPresented: $showsFinishConfirmation) {
                Button("workout.finish", role: .destructive) { appState.finishWorkout() }
                Button("action.cancel", role: .cancel) {}
            }
        }
    }

    private var workoutSummary: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("workout.inProgress").font(.caption.bold()).foregroundStyle(Theme.accent)
                Text("workout.keepIntent").font(.title3.bold())
            }
            Spacer()
            Button { showsVoice = true } label: { Image(systemName: "waveform.circle.fill").font(.title2) }.accessibilityLabel("voice.title")
        }.padding(.bottom, 4)
    }

    private func handleVoice(_ action: WorkoutVoiceAction) {
        guard let current = appState.activeWorkout?.exercises.first(where: { !$0.isSkipped && $0.sets.count < $0.planned.sets }) else { return }
        switch action {
        case .logSet(let reps, let weight): appState.logSet(exerciseID: current.id, reps: reps, displayedWeight: weight)
        case .startRestTimer: restDeadline = .now.addingTimeInterval(TimeInterval(current.planned.restSeconds))
        case .equipmentUnavailable: selectedRescue = RescueTarget(id: current.id, planned: current.planned)
        case .timeRescue: showsTimeRescue = true
        case .whatsNext, .repeatLast, .unknown: break
        }
    }
}

struct RescueTarget: Identifiable {
    let id: UUID
    let planned: PlannedExercise
}

private struct ExerciseCard: View {
    let performed: PerformedExercise
    let unit: WeightUnit
    let onLog: (Int, Double) -> Void
    let onUnavailable: () -> Void
    @State private var reps = 8
    @State private var weight = 20.0

    var body: some View {
        RelayCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(performed.performed.name.uppercased()).font(.headline.weight(.black))
                        Text(muscles).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(performed.planned.sets) × \(repText)").font(.title3.bold())
                }
                if performed.performed != performed.planned.exercise {
                    Label("workout.substitutedFor \(performed.planned.exercise.name)", systemImage: "arrow.triangle.swap")
                        .font(.caption).foregroundStyle(.orange)
                }
                if let previous = performed.planned.previousPerformance {
                    VStack(alignment: .leading, spacing: 2) { Text("workout.lastSession").font(.caption2.bold()).foregroundStyle(.secondary); Text(previous).font(.subheadline.monospacedDigit()) }
                }
                if !performed.sets.isEmpty {
                    HStack { ForEach(performed.sets) { set in Text("\(set.reps)").font(.caption.bold()).padding(8).background(Theme.accent.opacity(0.18), in: Circle()) } }
                }
                HStack {
                    Stepper("\(reps) reps", value: $reps, in: 1...30).labelsHidden()
                    TextField("0", value: $weight, format: .number).keyboardType(.decimalPad).textFieldStyle(.roundedBorder).frame(width: 70)
                    Text(unit == .kilograms ? "kg" : "lb").foregroundStyle(.secondary)
                    Button("workout.logSet") { onLog(reps, weight) }.buttonStyle(.borderedProminent).font(.caption.bold())
                }
                Button(action: onUnavailable) { Label("workout.unavailable", systemImage: "exclamationmark.triangle").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered).tint(.primary)
            }
        }
    }

    private var muscles: String { performed.performed.primaryMuscles.map(\.rawValue).sorted().joined(separator: " • ").capitalized }
    private var repText: String { let range = performed.planned.repRange; return range.lowerBound == range.upperBound ? "\(range.lowerBound)" : "\(range.lowerBound)–\(range.upperBound)" }
}

private struct RestTimerBar: View {
    let deadline: Date
    let cancel: () -> Void
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(deadline.timeIntervalSince(context.date)))
            HStack { Image(systemName: "timer"); Text("workout.rest \(remaining)").monospacedDigit().fontWeight(.bold); Spacer(); Button("action.skip", action: cancel) }
                .padding().background(.ultraThinMaterial).onChange(of: remaining) { _, value in if value == 0 { cancel() } }
        }
    }
}
