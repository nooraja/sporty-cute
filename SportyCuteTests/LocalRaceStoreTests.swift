import Foundation
import Testing
@testable import SportyCute

struct LocalRaceStoreTests {
    @Test func coordinatesAndRecapSurviveReload() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = LocalRaceStore(directory: directory)
        var library = try store.load()
        let checkpoint = try #require(library.checkpoints.first)
        var updated = checkpoint
        updated.latitude = -6.91
        library.checkpoints = [updated]
        let id = UUID()
        library.beaconIDs = [.t1: id]
        let recap = RaceRecap(date: .now, duration: 30, checkpoints: 1, cheers: [])
        library.recaps = [recap]

        try store.save(library)

        let reloaded = try LocalRaceStore(directory: directory).load()
        #expect(reloaded.checkpoints == [updated])
        #expect(reloaded.beaconIDs?[.t1] == id)
        #expect(reloaded.recaps.first?.id == recap.id)
    }
}
