import CoreLocation
import Foundation
import Observation
import os

@MainActor
@Observable
final class RaceViewModel {
    enum Mode: String, CaseIterable, Identifiable {
        case demo = "Demo"
        case gps = "GPS"
        var id: Self { self }
    }

    private let location: LocationTracker
    private let bluetooth: TransitionScanner
    private let vault: VoiceVaultViewModel
    private let log = Logger(subsystem: "indie.sportycute.app", category: "Race")
    private var checkpointQueue: [Checkpoint] = []
    private var pendingCheers: [Cheer] = []

    var format: RaceFormat = .run
    var mode: Mode = .demo
    var beaconIDs: [Transition: UUID] { vault.library.beaconIDs ?? [:] }

    private(set) var progress: RaceProgress?
    private(set) var locationStatus = "Ready"
    private(set) var bluetoothStatus: String?

    var checkpoints: [Checkpoint] { vault.library.checkpoints }
    var nextCheckpoint: Checkpoint? {
        guard let progress else { return nil }
        return checkpoints.first { !progress.visited.contains($0.id) }
    }

    init(location: LocationTracker, bluetooth: TransitionScanner, vault: VoiceVaultViewModel) {
        self.location = location
        self.bluetooth = bluetooth
        self.vault = vault
        location.onLocation = { [weak self] update in self?.receiveLocation(update) }
        location.onStatus = { [weak self] status in self?.locationStatus = status }
        bluetooth.onStatus = { [weak self] status in self?.bluetoothStatus = status }
        bluetooth.onDetection = { [weak self] in self?.advanceTransition() }
        vault.onPlaybackEnd = { [weak self] in self?.resumeQueue() }
    }

    @discardableResult
    func saveBeacon(_ id: UUID?, for transition: Transition) -> Bool {
        vault.saveBeacon(id, for: transition)
    }

    func start() {
        guard progress == nil, vault.recording == .idle else { return }
        vault.stopPlayback()
        checkpointQueue = []
        pendingCheers = []
        progress = RaceProgress(format: format, startedAt: .now)
        locationStatus = mode == .demo ? "Demo race" : "Waiting for GPS"
        if mode == .gps { location.start() }
        watchNextTransition()
        log.info("Race started in \(self.mode.rawValue, privacy: .public) mode")
    }

    func advanceDemo() {
        guard mode == .demo, let nextCheckpoint else { return }
        visit(nextCheckpoint)
    }

    func advanceTransition() {
        guard let next = progress?.nextTransition else { return }
        progress?.advance(next)
        log.info("Advanced through \(next.rawValue, privacy: .public)")
        watchNextTransition()
    }

    func resumeQueue() {
        guard let progress, vault.playing == nil else { return }
        while !pendingCheers.isEmpty {
            let cheer = pendingCheers.removeFirst()
            if vault.play(cheer) {
                var updatedProgress = progress
                updatedProgress.markHeard(cheer)
                self.progress = updatedProgress
                return
            }
        }

        if !checkpointQueue.isEmpty {
            let checkpoint = checkpointQueue.removeFirst()
            pendingCheers = vault.cheers(at: checkpoint)
            resumeQueue()
        }
    }

    func finish() {
        guard let progress else { return }

        self.progress = nil
        checkpointQueue = []
        pendingCheers = []
        location.stop()
        bluetooth.stop()
        vault.stopPlayback()
        vault.addRecap(RaceRecap(
            date: progress.startedAt, duration: Date.now.timeIntervalSince(progress.startedAt),
            checkpoints: progress.visited.count, cheers: progress.heard
        ))
        log.info("Race finished")
    }

    private func receiveLocation(_ location: CLLocation) {
        guard progress != nil else { return }
        for checkpoint in checkpoints where checkpoint.contains(location) {
            visit(checkpoint)
        }
    }

    private func visit(_ checkpoint: Checkpoint) {
        guard var progress, progress.visit(checkpoint) else { return }
        self.progress = progress
        checkpointQueue.append(checkpoint)
        resumeQueue()
    }

    private func watchNextTransition() {
        bluetooth.stop()
        bluetoothStatus = nil
        guard let next = progress?.nextTransition else { return }
        bluetoothStatus = mode == .demo ? "Manual transition" : "Manual transition · no beacon configured"
        if mode == .gps, let service = beaconIDs[next] {
            bluetooth.watch(service: service)
        }
    }
}
