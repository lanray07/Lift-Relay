import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var step = 0
    @State private var goal: TrainingGoal = .muscle
    @State private var experience: ExperienceLevel = .intermediate
    @State private var days = 4
    @State private var equipment: Set<Equipment> = [.barbell, .dumbbells, .squatRack, .bench, .cableStation]
    @State private var restrictions = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("app.name").font(.headline)
                Spacer()
                Text("onboarding.step \(step + 1) 4").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            .padding()

            ProgressView(value: Double(step + 1), total: 4).tint(Theme.accent).padding(.horizontal)

            TabView(selection: $step) {
                goalStep.tag(0)
                experienceStep.tag(1)
                equipmentStep.tag(2)
                restrictionStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 12) {
                if step > 0 { Button("action.back") { step -= 1 }.buttonStyle(.bordered).controlSize(.large) }
                Button(step == 3 ? "action.finish" : "action.continue") {
                    if step < 3 { step += 1 } else { complete() }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var goalStep: some View {
        OnboardingPage(title: "onboarding.goal.title", subtitle: "onboarding.goal.subtitle") {
            ChoiceList(values: TrainingGoal.allCases, selection: $goal, title: goalTitle)
        }
    }

    private var experienceStep: some View {
        OnboardingPage(title: "onboarding.experience.title", subtitle: "onboarding.experience.subtitle") {
            ChoiceList(values: ExperienceLevel.allCases, selection: $experience, title: experienceTitle)
            VStack(alignment: .leading, spacing: 12) {
                Text("onboarding.frequency").font(.headline)
                Stepper(value: $days, in: 1...7) { Text("onboarding.days \(days)").font(.title3.weight(.semibold)) }
            }
            .padding(.top, 24)
        }
    }

    private var equipmentStep: some View {
        OnboardingPage(title: "onboarding.equipment.title", subtitle: "onboarding.equipment.subtitle") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Equipment.allCases, id: \.self) { item in
                    Button { toggle(item) } label: {
                        HStack { Image(systemName: equipment.contains(item) ? "checkmark.circle.fill" : "circle"); Text(equipmentTitle(item)); Spacer() }
                            .font(.subheadline.weight(.semibold)).padding(12).frame(maxWidth: .infinity)
                            .background(equipment.contains(item) ? Theme.accent.opacity(0.2) : Theme.card, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var restrictionStep: some View {
        OnboardingPage(title: "onboarding.restrictions.title", subtitle: "onboarding.restrictions.subtitle") {
            TextField("onboarding.restrictions.placeholder", text: $restrictions, axis: .vertical)
                .lineLimit(4...7).textFieldStyle(.roundedBorder)
            Label("onboarding.safety", systemImage: "cross.case")
                .font(.footnote).foregroundStyle(.secondary).padding(.top, 16)
        }
    }

    private func toggle(_ item: Equipment) { if equipment.contains(item) { equipment.remove(item) } else { equipment.insert(item) } }
    private func complete() {
        appState.finishOnboarding(profile: UserProfile(goal: goal, experience: experience, trainingDaysPerWeek: days, typicalEquipment: equipment, restrictions: [], preferredUnit: .kilograms))
        AnalyticsClient.shared.track(.onboardingCompleted)
    }
    private func goalTitle(_ value: TrainingGoal) -> LocalizedStringKey { LocalizedStringKey("goal.\(value.rawValue)") }
    private func experienceTitle(_ value: ExperienceLevel) -> LocalizedStringKey { LocalizedStringKey("experience.\(value.rawValue)") }
    private func equipmentTitle(_ value: Equipment) -> LocalizedStringKey { LocalizedStringKey("equipment.\(value.rawValue)") }
}

private struct OnboardingPage<Content: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Spacer(minLength: 30)
                Text(title).font(.largeTitle.bold())
                Text(subtitle).font(.body).foregroundStyle(.secondary).padding(.bottom, 12)
                content
            }.padding(24)
        }
    }
}

private struct ChoiceList<Value: Hashable & CaseIterable>: View where Value.AllCases: RandomAccessCollection {
    let values: Value.AllCases
    @Binding var selection: Value
    let title: (Value) -> LocalizedStringKey
    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(values), id: \.self) { value in
                Button { selection = value } label: {
                    HStack { Text(title(value)); Spacer(); Image(systemName: selection == value ? "checkmark.circle.fill" : "circle") }
                        .padding(16).background(selection == value ? Theme.accent.opacity(0.2) : Theme.card, in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)
            }
        }
    }
}
