import SwiftUI

struct TimeRescueView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var minutes = 20
    private let choices = [15, 20, 30, 45]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("timeRescue.headline").font(.largeTitle.bold())
                Text("timeRescue.subtitle").foregroundStyle(.secondary)
                HStack {
                    ForEach(choices, id: \.self) { value in
                        Button("\(value)") { minutes = value }
                            .buttonStyle(.borderedProminent).tint(minutes == value ? Theme.accent : .secondary)
                            .foregroundStyle(minutes == value ? Theme.ink : .primary)
                    }
                }
                RelayCard {
                    Label("timeRescue.explanation \(minutes)", systemImage: "bolt.horizontal.circle.fill")
                        .font(.headline)
                }
                Spacer()
                Button("timeRescue.relay") {
                    appState.applyTimeRescue(minutes: minutes)
                    dismiss()
                }.buttonStyle(PrimaryButtonStyle())
            }
            .padding().relayBackground()
            .navigationTitle("timeRescue.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("action.cancel") { dismiss() } } }
        }
        .presentationDetents([.medium])
    }
}
