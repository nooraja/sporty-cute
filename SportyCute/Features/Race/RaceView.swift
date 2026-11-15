import SwiftUI

struct RaceView: View {
    @Bindable var model: RaceViewModel
    let vault: VoiceVaultViewModel
    let showVault: () -> Void

    @State private var showsSetup = false
    @State private var confirmsFinish = false

    var body: some View {
        if let progress = model.progress {
            liveRace(progress)
        } else {
            preparation
        }
    }

    private var preparation: some View {
        Group {
            VStack(alignment: .leading, spacing: 7) {
                Text("RACE DAY").font(Theme.label).foregroundStyle(Theme.violet)
                Text("Every mile,\na little louder.")
                    .font(Theme.display())
                    .accessibilityAddTraits(.isHeader)
                Text("Hear your crew when you reach a checkpoint.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            }

            CourseCard(count: model.checkpoints.count)

            VStack(spacing: 14) {
                Picker("Race format", selection: $model.format) {
                    ForEach(RaceFormat.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("race.format")

                PrimaryButton(
                    title: model.mode == .demo ? "Start demo race" : "Start GPS race",
                    icon: "play.fill",
                    action: model.start
                )
                .accessibilityIdentifier("race.start")
                .disabled(vault.recording != .idle)

                Button {
                    showsSetup = true
                } label: {
                    Label("Race setup", systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }
                .sheet(isPresented: $showsSetup) {
                    RaceSetupView(model: model, vault: vault)
                }
            }

            SectionHeading("Course cues", detail: "ON THE ROUTE")
            checkpointRows(visited: [])
        }
    }

    private func liveRace(_ progress: RaceProgress) -> some View {
        Group {
            VStack(alignment: .leading, spacing: 10) {
                Label(model.locationStatus, systemImage: model.mode == .demo ? "sparkles" : "location.circle.fill")
                    .font(Theme.label)
                    .foregroundStyle(Theme.lime)
                Text(progress.sport == .run ? "Keep it moving." : "\(progress.sport.rawValue) leg")
                    .font(Theme.display())
                    .accessibilityIdentifier("race.currentLeg")
                TimelineView(.periodic(from: progress.startedAt, by: 1)) { clock in
                    Text(Duration.seconds(max(0, clock.date.timeIntervalSince(progress.startedAt))), format: .time(pattern: .hourMinuteSecond))
                        .font(.system(.largeTitle, design: .monospaced, weight: .semibold))
                        .monospacedDigit()
                        .accessibilityLabel("Elapsed time")
                }
                HStack {
                    Label("\(progress.visited.count)/\(model.checkpoints.count) cues", systemImage: "flag.fill")
                    Spacer()
                    Label("\(progress.heard.count) played", systemImage: "waveform")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.lavender)
                if let cheer = vault.playing {
                    Label("Playing \(cheer.sender)’s cheer", systemImage: "speaker.wave.2.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.lime)
                }
            }
            .foregroundStyle(.white)
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.violet, in: RoundedRectangle(cornerRadius: 25))

            if model.mode == .demo, model.nextCheckpoint != nil {
                PrimaryButton(title: "Reach next checkpoint", icon: "location.fill", action: model.advanceDemo)
                    .accessibilityIdentifier("race.nextCheckpoint")
            }

            if let transition = progress.nextTransition {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeading("Next transition", detail: model.bluetoothStatus)
                    Button(action: model.advanceTransition) {
                        Label("\(transition.rawValue) · Start \(transition.nextSport.rawValue.lowercased())",
                              systemImage: transition.nextSport.icon)
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 47)
                            .background(Theme.lavender, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("race.transition")
                }
            }

            SectionHeading("Course cues")
            checkpointRows(visited: progress.visited)

            Button("Finish race") { confirmsFinish = true }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityIdentifier("race.finish")
                .confirmationDialog("Finish this race?", isPresented: $confirmsFinish, titleVisibility: .visible) {
                    Button("Finish and view replay") {
                        model.finish()
                        showVault()
                    }
                    Button("Keep going", role: .cancel) {}
                }
        }
    }

    private func checkpointRows(visited: Set<Checkpoint.ID>) -> some View {
        VStack(spacing: 0) {
            ForEach(model.checkpoints) { checkpoint in
                HStack(spacing: 13) {
                    Image(systemName: visited.contains(checkpoint.id) ? "checkmark.circle.fill" : "flag")
                        .font(.subheadline.weight(.bold))
                        .frame(width: 36, height: 36)
                        .background(Theme.lavender, in: Circle())
                        .accessibilityHidden(true)
                    Text(checkpoint.name).font(.subheadline.weight(.bold))
                    Spacer()
                    Text(checkpoint.distance).font(Theme.label).foregroundStyle(Theme.muted)
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
                .accessibilityValue(visited.contains(checkpoint.id) ? "Reached" : "Upcoming")

                if checkpoint.id != model.checkpoints.last?.id {
                    Rectangle().fill(Theme.line).frame(height: 1)
                }
            }
        }
    }
}
