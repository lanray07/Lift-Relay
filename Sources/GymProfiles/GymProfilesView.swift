import SwiftUI

struct GymProfilesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var name = ""
    @State private var equipment: Set<Equipment> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("gyms.saved") {
                    ForEach(appState.gyms) { gym in
                        Button { appState.selectedGymID = gym.id; dismiss() } label: {
                            HStack { VStack(alignment: .leading) { Text(gym.name); Text("gyms.items \(gym.equipment.count)").font(.caption).foregroundStyle(.secondary) }; Spacer(); if gym.id == appState.selectedGymID { Image(systemName: "checkmark") } }
                        }.foregroundStyle(.primary)
                    }
                }
                Section("gyms.add") {
                    TextField("gyms.name", text: $name)
                    EquipmentPicker(selection: $equipment)
                    Button("gyms.save") {
                        let gym = GymProfile(name: name, equipment: equipment)
                        appState.gyms.append(gym); appState.selectedGymID = gym.id; appState.persist(); dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || equipment.isEmpty)
                }
            }
            .navigationTitle("gyms.title")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("action.done") { dismiss() } } }
        }
    }
}
