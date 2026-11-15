import SwiftUI

struct VoiceVaultView: View {
    let vault: VoiceVaultViewModel
    let raceIsActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 21) {
            VStack(alignment: .leading, spacing: 7) {
                Text("VOICE VAULT").font(Theme.label).foregroundStyle(Theme.violet)
                Text("Keep the good stuff.").font(Theme.display())
                    .accessibilityAddTraits(.isHeader)
                Text("Replay the cheers that carried you through.")
                    .font(.subheadline).foregroundStyle(Theme.muted)
            }

            if let recap = vault.library.recaps.first {
                recapCard(recap)
            }

            SectionHeading("All voice notes", detail: "\(vault.cheers.count) SAVED")
            ForEach(vault.cheers) { cheer in
                CheerRow(
                    cheer: cheer, isPlaying: vault.playing?.id == cheer.id, canPlay: !raceIsActive,
                    shareURL: vault.shareURL(for: cheer)
                ) {
                    vault.togglePlayback(cheer)
                }
            }
        }
    }

    private func recapCard(_ recap: RaceRecap) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Label("LAST RACE", systemImage: "flag.checkered").font(Theme.label)
            Text("Finish line feelings").font(Theme.display(.title2))
                .accessibilityIdentifier("vault.recap")
            Divider()
            HStack {
                Label("\(recap.checkpoints) reached", systemImage: "flag.fill")
                Spacer()
                Label("\(recap.cheers.count) played", systemImage: "waveform")
            }
            .font(.subheadline.weight(.semibold))

            ForEach(recap.cheers.compactMap { id in vault.cheers.first { $0.id == id } }) { cheer in
                CheerRow(
                    cheer: cheer, isPlaying: vault.playing?.id == cheer.id, canPlay: !raceIsActive,
                    shareURL: vault.shareURL(for: cheer)
                ) {
                    vault.togglePlayback(cheer)
                }
            }
        }
        .padding(19)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.lime, in: RoundedRectangle(cornerRadius: 25))
    }
}

private struct CheerRow: View {
    let cheer: Cheer
    let isPlaying: Bool
    let canPlay: Bool
    let shareURL: URL?
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggle) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(Theme.lavender.opacity(canPlay ? 1 : 0.5), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(isPlaying ? "Stop" : "Play") \(cheer.title)")
            .disabled(!canPlay)

            VStack(alignment: .leading, spacing: 4) {
                Text(cheer.title).font(.subheadline.weight(.bold))
                HStack {
                    Text(cheer.sender)
                    Text(Duration.seconds(cheer.duration), format: .time(pattern: .minuteSecond))
                }
                .font(.caption)
                .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
            if let shareURL {
                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Share \(cheer.title)")
            }
        }
        .foregroundStyle(Theme.ink)
        .padding(8)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
    }
}
