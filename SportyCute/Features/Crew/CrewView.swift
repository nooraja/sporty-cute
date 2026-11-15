import SwiftUI

struct CrewView: View {
    let vault: VoiceVaultViewModel
    let raceIsActive: Bool

    @State private var showsRecorder = false

    var body: some View {
        VStack(alignment: .leading, spacing: 21) {
            VStack(alignment: .leading, spacing: 7) {
                Text("THE SUPPORT SQUAD").font(Theme.label).foregroundStyle(Theme.violet)
                Text("Small words.\nBig energy.")
                    .font(Theme.display()).accessibilityAddTraits(.isHeader)
                Text("Give someone a boost for the hard part.")
                    .font(.subheadline).foregroundStyle(Theme.muted)
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 25, weight: .bold))
                        .padding(17)
                        .background(Theme.peach, in: Circle())
                        .accessibilityHidden(true)
                    Spacer()
                    Image(systemName: "waveform")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(Theme.violet)
                        .accessibilityHidden(true)
                }
                Text("Send a little noise").font(Theme.display(.title2))
                Text("Record a voice note and pick where it plays on the course.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                PrimaryButton(title: "Record a cheer", icon: "mic.fill") { showsRecorder = true }
                    .accessibilityIdentifier("crew.record")
                    .disabled(raceIsActive)
                if raceIsActive {
                    Text("Finish the race to record a new cheer.").font(.footnote)
                }
            }
            .padding(20)
            .background(Theme.lavender, in: RoundedRectangle(cornerRadius: 25))

            SectionHeading("Your crew", detail: "\(vault.cheers.count) CHEERS")
            ForEach(vault.cheers) { cheer in
                HStack(spacing: 14) {
                    Text(String(cheer.sender.prefix(1)).uppercased())
                        .font(Theme.display(.headline))
                        .frame(width: 43, height: 43)
                        .background(Theme.peach, in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(cheer.sender).font(.headline)
                        Text(cheer.title).font(.subheadline).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Text(cheer.isBundled ? "DEMO" : "LOCAL")
                        .font(Theme.label).foregroundStyle(Theme.muted)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .sheet(isPresented: $showsRecorder, onDismiss: vault.cancelRecording) {
            CheerRecorderView(vault: vault)
        }
    }
}
