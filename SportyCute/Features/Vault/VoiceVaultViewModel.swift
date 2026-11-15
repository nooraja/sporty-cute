import AVFoundation
import Foundation
import Observation
import os

@MainActor
@Observable
final class VoiceVaultViewModel {
    enum Recording: Equatable {
        case idle
        case requesting
        case active(URL)
    }

    private let store: LocalRaceStore
    private let audio: CheerAudio
    private let log = Logger(subsystem: "indie.sportycute.app", category: "Vault")
    private var canSave = true

    private(set) var library = RaceLibrary()
    private(set) var recording: Recording = .idle
    private(set) var playing: Cheer?
    var errorMessage: String?
    var onPlaybackEnd: (() -> Void)?

    var cheers: [Cheer] { library.cheers + PortfolioData.cheers }

    init(store: LocalRaceStore, audio: CheerAudio) {
        self.store = store
        self.audio = audio
        do {
            library = try store.load()
        } catch {
            canSave = false
            report(error)
        }
        audio.onPlaybackEnd = { [weak self] in
            self?.playing = nil
            self?.onPlaybackEnd?()
        }
        audio.onRecordingFailure = { [weak self] message in
            self?.cancelRecording()
            self?.errorMessage = message
        }
    }

    func cheers(at checkpoint: Checkpoint) -> [Cheer] {
        cheers.filter { $0.checkpointID == checkpoint.id }
    }

    @discardableResult
    func play(_ cheer: Cheer) -> Bool {
        guard recording == .idle, let url = shareURL(for: cheer) else { return false }
        do {
            try audio.play(url)
            playing = cheer
            return true
        } catch {
            playing = nil
            report(error)
            return false
        }
    }

    func togglePlayback(_ cheer: Cheer) {
        if playing?.id == cheer.id {
            stopPlayback()
        } else {
            play(cheer)
        }
    }

    func stopPlayback() {
        audio.stopPlayback()
        playing = nil
    }

    func shareURL(for cheer: Cheer) -> URL? {
        guard let url = store.audioURL(for: cheer),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    func startRecording() async {
        guard recording == .idle else { return }
        stopPlayback()
        recording = .requesting
        var destination: URL?

        do {
            let url = try store.newAudioURL()
            destination = url
            try await audio.startRecording(to: url)
            recording = .active(url)
        } catch {
            if let destination { try? FileManager.default.removeItem(at: destination) }
            recording = .idle
            if !(error is CancellationError) { report(error) }
        }
    }

    func saveRecording(title: String, sender: String, checkpoint: Checkpoint) -> Bool {
        guard case let .active(url) = recording else { return false }
        recording = .idle

        do {
            let duration = try audio.stopRecording()
            let cheer = Cheer(
                id: UUID(), title: title, sender: sender, checkpointID: checkpoint.id,
                fileName: url.lastPathComponent, duration: duration, isBundled: false
            )
            var updated = library
            updated.cheers.insert(cheer, at: 0)
            if commit(updated) { return true }
        } catch {
            report(error)
        }

        try? FileManager.default.removeItem(at: url)
        return false
    }

    func cancelRecording() {
        guard case let .active(url) = recording else { return }
        recording = .idle
        _ = try? audio.stopRecording()
        try? FileManager.default.removeItem(at: url)
    }

    func updateCheckpoint(_ checkpoint: Checkpoint) -> Bool {
        guard let index = library.checkpoints.firstIndex(where: { $0.id == checkpoint.id }) else { return false }
        var updated = library
        updated.checkpoints[index] = checkpoint
        return commit(updated)
    }

    func saveBeacon(_ id: UUID?, for transition: Transition) -> Bool {
        var updated = library
        var beacons = updated.beaconIDs ?? [:]
        beacons[transition] = id
        updated.beaconIDs = beacons
        return commit(updated)
    }

    func addRecap(_ recap: RaceRecap) {
        var updated = library
        updated.recaps.insert(recap, at: 0)
        commit(updated)
    }

    @discardableResult
    private func commit(_ updated: RaceLibrary) -> Bool {
        guard canSave else {
            errorMessage = "The local library could not be opened. Your existing files were preserved."
            return false
        }

        do {
            try store.save(updated)
            library = updated
            return true
        } catch {
            report(error)
            return false
        }
    }

    private func report(_ error: Error) {
        log.error("Vault operation failed: \(String(describing: error), privacy: .private)")
        errorMessage = error.localizedDescription
    }
}
