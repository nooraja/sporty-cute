import SwiftUI

struct CheerRecorderView: View {
    let vault: VoiceVaultViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var sender = ""
    @State private var checkpointID = ""
    @State private var permissionTask: Task<Void, Never>?

    private var cleanTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var cleanSender: String { sender.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var checkpoint: Checkpoint? {
        vault.library.checkpoints.first { $0.id == checkpointID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cheer details") {
                    TextField("Title", text: $title)
                    TextField("Your name", text: $sender)
                    Picker("Checkpoint", selection: $checkpointID) {
                        ForEach(vault.library.checkpoints) { Text($0.name).tag($0.id) }
                    }
                }
                .disabled(vault.recording != .idle)

                Section {
                    switch vault.recording {
                    case .idle:
                        Button("Start recording", systemImage: "mic.fill") {
                            permissionTask = Task { await vault.startRecording() }
                        }
                        .disabled(cleanTitle.isEmpty || cleanSender.isEmpty || checkpoint == nil)
                    case .requesting:
                        ProgressView("Waiting for microphone")
                    case .active:
                        Label("Recording…", systemImage: "record.circle.fill")
                            .foregroundStyle(.red)
                        Button("Stop and save", systemImage: "checkmark.circle.fill") {
                            guard let checkpoint else { return }
                            if vault.saveRecording(title: cleanTitle, sender: cleanSender, checkpoint: checkpoint) {
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("New cheer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            if checkpointID.isEmpty { checkpointID = vault.library.checkpoints.first?.id ?? "" }
        }
        .onDisappear {
            permissionTask?.cancel()
            vault.cancelRecording()
        }
        .alert("Recording", isPresented: Binding(
            get: { vault.errorMessage != nil },
            set: { if !$0 { vault.errorMessage = nil } }
        )) {
            Button("OK") { vault.errorMessage = nil }
        } message: {
            Text(vault.errorMessage ?? "")
        }
    }
}
