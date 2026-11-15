import AVFoundation
import Foundation

enum CheerAudioError: LocalizedError {
    case microphoneDenied, recordingFailed, playbackFailed, noRecording

    var errorDescription: String? {
        switch self {
        case .microphoneDenied: "Allow microphone access in Settings to record a cheer."
        case .recordingFailed: "The recording could not start."
        case .playbackFailed: "This cheer could not play."
        case .noRecording: "Record a longer cheer before saving."
        }
    }
}

@MainActor
final class CheerAudio: NSObject {
    private let session = AVAudioSession.sharedInstance()
    private var player: AVAudioPlayer?
    private var recorder: AVAudioRecorder?

    var onPlaybackEnd: (() -> Void)?
    var onRecordingFailure: ((String) -> Void)?

    func play(_ url: URL) throws {
        guard recorder == nil else { throw CheerAudioError.playbackFailed }
        stopPlayback()
        let player = try AVAudioPlayer(contentsOf: url)

        do {
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            player.delegate = self
            guard player.play() else { throw CheerAudioError.playbackFailed }
            self.player = player
        } catch {
            deactivate()
            throw error
        }
    }

    func stopPlayback() {
        guard let player else { return }
        player.stop()
        self.player = nil
        deactivate()
    }

    func startRecording(to url: URL) async throws {
        guard await AVAudioApplication.requestRecordPermission() else {
            throw CheerAudioError.microphoneDenied
        }
        try Task.checkCancellation()
        stopPlayback()

        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            recorder.delegate = self
            guard recorder.record() else { throw CheerAudioError.recordingFailed }
            self.recorder = recorder
        } catch {
            deactivate()
            throw error
        }
    }

    func stopRecording() throws -> TimeInterval {
        guard let recorder else { throw CheerAudioError.noRecording }
        let duration = recorder.currentTime
        recorder.stop()
        self.recorder = nil
        deactivate()
        guard duration >= 0.3 else { throw CheerAudioError.noRecording }
        return duration
    }

    private func deactivate() {
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

extension CheerAudio: AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        schedulePlaybackEnd(for: ObjectIdentifier(player))
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        schedulePlaybackEnd(for: ObjectIdentifier(player))
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        scheduleRecordingFailure(for: ObjectIdentifier(recorder), message: "Recording ended before it could be saved.")
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: (any Error)?) {
        let message = error?.localizedDescription ?? "Recording could not be saved."
        scheduleRecordingFailure(for: ObjectIdentifier(recorder), message: message)
    }

    private nonisolated func schedulePlaybackEnd(for identity: ObjectIdentifier) {
        Task { @MainActor [weak self] in
            guard let self, let player, ObjectIdentifier(player) == identity else { return }
            stopPlayback()
            onPlaybackEnd?()
        }
    }

    private nonisolated func scheduleRecordingFailure(for identity: ObjectIdentifier, message: String) {
        Task { @MainActor [weak self] in
            guard let self, let recorder, ObjectIdentifier(recorder) == identity else { return }
            self.recorder = nil
            recorder.stop()
            deactivate()
            onRecordingFailure?(message)
        }
    }
}
