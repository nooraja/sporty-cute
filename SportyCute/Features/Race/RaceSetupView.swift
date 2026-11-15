import SwiftUI

struct RaceSetupView: View {
    @Bindable var model: RaceViewModel
    let vault: VoiceVaultViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Cue source", selection: $model.mode) {
                        ForEach(RaceViewModel.Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                } footer: {
                    Text("Demo lets you reach each checkpoint manually. GPS plays cheers within 60 meters of a checkpoint during the race.")
                }
                Section("Checkpoint coordinates") {
                    ForEach(model.checkpoints) { checkpoint in
                        NavigationLink(checkpoint.name) {
                            CheckpointEditor(checkpoint: checkpoint, vault: vault)
                        }
                    }
                }
                if model.format == .triathlon {
                    Section {
                        ForEach(Transition.allCases) { transition in
                            NavigationLink("\(transition.rawValue) beacon") {
                                BeaconEditor(transition: transition, model: model)
                            }
                        }
                    } footer: {
                        Text("Use Bluetooth Low Energy beacons that advertise distinct service UUIDs. Manual transitions are always available.")
                    }
                }
            }
            .navigationTitle("Race setup")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct CheckpointEditor: View {
    let checkpoint: Checkpoint
    let vault: VoiceVaultViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var latitude: Double
    @State private var longitude: Double

    init(checkpoint: Checkpoint, vault: VoiceVaultViewModel) {
        self.checkpoint = checkpoint
        self.vault = vault
        _latitude = State(initialValue: checkpoint.latitude)
        _longitude = State(initialValue: checkpoint.longitude)
    }

    var body: some View {
        Form {
            TextField("Latitude", value: $latitude, format: .number.precision(.fractionLength(0...6)))
                .keyboardType(.numbersAndPunctuation)
            TextField("Longitude", value: $longitude, format: .number.precision(.fractionLength(0...6)))
                .keyboardType(.numbersAndPunctuation)
        }
        .navigationTitle(checkpoint.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var updated = checkpoint
                    updated.latitude = latitude
                    updated.longitude = longitude
                    if vault.updateCheckpoint(updated) { dismiss() }
                }
                .disabled(!(-90...90).contains(latitude) || !(-180...180).contains(longitude))
            }
        }
    }
}

private struct BeaconEditor: View {
    let transition: Transition
    let model: RaceViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var serviceID = ""

    private var trimmedID: String { serviceID.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var uuid: UUID? { UUID(uuidString: trimmedID) }
    private var isDuplicate: Bool {
        guard let uuid else { return false }
        return model.beaconIDs.contains { $0.key != transition && $0.value == uuid }
    }

    var body: some View {
        Form {
            Section {
                TextField("Service UUID", text: $serviceID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } footer: {
                Text(isDuplicate ? "Assign a different UUID to this transition." : "Leave empty to use manual transitions.")
            }
        }
        .navigationTitle("\(transition.rawValue) beacon")
        .onAppear { serviceID = model.beaconIDs[transition]?.uuidString ?? "" }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if model.saveBeacon(uuid, for: transition) { dismiss() }
                }
                .disabled((!trimmedID.isEmpty && uuid == nil) || isDuplicate)
            }
        }
    }
}
