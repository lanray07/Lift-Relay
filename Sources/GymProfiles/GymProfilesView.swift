import SwiftUI

struct GymProfilesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @State private var name = ""
    @State private var equipment: Set<Equipment> = []
    @State private var showsPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section("gyms.saved") {
                    ForEach(appState.gyms) { gym in
                        Button { appState.selectedGymID = gym.id; appState.persist(); dismiss() } label: {
                            HStack { VStack(alignment: .leading) { Text(gym.name); Text("gyms.items \(gym.equipment.count)").font(.caption).foregroundStyle(.secondary) }; Spacer(); if gym.id == appState.selectedGymID { Image(systemName: "checkmark") } }
                        }.foregroundStyle(.primary)
                    }
                }
                Section("gyms.add") {
                    if subscriptionStore.isPro {
                        TextField("gyms.name", text: $name)
                        EquipmentPicker(selection: $equipment)
                        Button("gyms.save") {
                            let gym = GymProfile(name: name, equipment: equipment)
                            appState.gyms.append(gym); appState.selectedGymID = gym.id; appState.persist(); dismiss()
                        }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || equipment.isEmpty)
                    } else {
                        Label("gyms.proRequired", systemImage: "crown.fill").foregroundStyle(.secondary)
                        Button("gyms.unlock") { showsPaywall = true }
                    }
                }
            }
            .navigationTitle("gyms.title")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("action.done") { dismiss() } } }
            .sheet(isPresented: $showsPaywall) { PaywallView() }
        }
    }
}
