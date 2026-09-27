import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @State private var exportDocument: WorkoutExportDocument?
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var confirmsHistoryDeletion = false

    var body: some View {
        @Bindable var appState = appState
        Form {
            Section("settings.training") {
                Picker("settings.units", selection: $appState.profile.preferredUnit) {
                    Text("unit.kg").tag(WeightUnit.kilograms)
                    Text("unit.lb").tag(WeightUnit.pounds)
                }
                Button("gyms.title") { appState.activeSheet = .gymProfiles }
                Button { appState.activeSheet = .paywall } label: {
                    HStack {
                        Text("settings.subscription")
                        Spacer()
                        Text(LocalizedStringKey(subscriptionStore.isPro ? "settings.proActive" : "settings.freePlan")).foregroundStyle(.secondary)
                    }
                }
            }
            Section("settings.privacy") {
                Label("settings.localProcessing", systemImage: "iphone.and.arrow.forward")
                Button("settings.export") { prepareExport() }
                Button("settings.deleteHistory", role: .destructive) { confirmsHistoryDeletion = true }
            }
            Section("settings.about") {
                Text("settings.medicalDisclaimer").font(.footnote).foregroundStyle(.secondary)
                Link("legal.privacy", destination: URL(string: "https://github.com/lanray07/Lift-Relay/blob/main/PRIVACY.md")!)
                Link("legal.terms", destination: URL(string: "https://github.com/lanray07/Lift-Relay/blob/main/TERMS.md")!)
            }
            Section { Button("settings.replayOnboarding") { appState.resetOnboarding() } }
        }
        .navigationTitle("settings.title")
        .appSheets($appState.activeSheet)
        .onChange(of: appState.profile.preferredUnit) { _, _ in appState.persist() }
        .fileExporter(isPresented: $isExporting, document: exportDocument, contentType: .json, defaultFilename: "Lift-Relay-Workout-Data") { result in
            if case .failure(let error) = result { exportError = error.localizedDescription }
            exportDocument = nil
        }
        .confirmationDialog("settings.deleteHistory.confirm", isPresented: $confirmsHistoryDeletion) {
            Button("settings.deleteHistory", role: .destructive) { appState.history = []; appState.persist() }
            Button("action.cancel", role: .cancel) {}
        }
        .alert("settings.exportFailed", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("action.done") { exportError = nil }
        } message: { Text(exportError ?? "") }
    }

    private func prepareExport() {
        do {
            exportDocument = WorkoutExportDocument(data: try appState.exportData())
            isExporting = true
        } catch {
            exportError = error.localizedDescription
        }
    }
}

private struct WorkoutExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
