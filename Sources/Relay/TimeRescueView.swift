import SwiftUI

struct TimeRescueView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var minutes: Int
    private var choices: [Int] { Array(Set([15, 20, 30, 45, minutes])).sorted() }

    init(initialMinutes: Int? = nil) {
        _minutes = State(initialValue: max(5, min(initialMinutes ?? 20, 180)))
    }

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
