import SwiftUI

struct VoiceCommandSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var capture = VoiceCaptureService()
    let onConfirm: (WorkoutVoiceAction) -> Void

    private var action: WorkoutVoiceAction { VoiceCommandParser().parse(capture.transcript) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: capture.isListening ? "waveform.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 74)).foregroundStyle(Theme.accent).symbolEffect(.pulse, isActive: capture.isListening)
                Text(capture.isListening ? "voice.listening" : "voice.ready").font(.title.bold())
                Text(capture.transcript.isEmpty ? String(localized: "voice.example") : capture.transcript)
                    .font(.title3).multilineTextAlignment(.center).foregroundStyle(capture.transcript.isEmpty ? .secondary : .primary).padding()
                if action != .unknown { Label(summary(action), systemImage: "checkmark.circle.fill").padding().background(Theme.card, in: RoundedRectangle(cornerRadius: 14)) }
                if let error = capture.errorMessage { Text(error).font(.footnote).foregroundStyle(.red) }
                Spacer()
                if action != .unknown {
                    Button("voice.confirm") { onConfirm(action); dismiss() }.buttonStyle(PrimaryButtonStyle())
                } else {
                    Button(capture.isListening ? "voice.stop" : "voice.start") { Task { capture.isListening ? capture.stop() : await capture.start() } }.buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding().navigationTitle("voice.title").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("action.cancel") { capture.stop(); dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }

    private func summary(_ action: WorkoutVoiceAction) -> String {
        switch action {
        case .logSet(let reps, let weight): String(localized: "voice.confirm.log \(reps) \(weight)")
        case .startRestTimer: String(localized: "voice.confirm.timer")
        case .equipmentUnavailable: String(localized: "voice.confirm.unavailable")
        case .timeRescue(let minutes): String(localized: "voice.confirm.time \(minutes)")
        case .whatsNext: String(localized: "voice.confirm.next")
        case .repeatLast: String(localized: "voice.confirm.repeat")
        case .unknown: ""
        }
    }
}
