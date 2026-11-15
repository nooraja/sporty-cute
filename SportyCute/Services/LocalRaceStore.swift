import Foundation

struct RaceLibrary: Codable {
    var checkpoints = PortfolioData.checkpoints
    var cheers: [Cheer] = []
    var recaps: [RaceRecap] = []
    var beaconIDs: [Transition: UUID]?
}

struct LocalRaceStore {
    let directory: URL

    private var libraryURL: URL {
        directory.appending(path: "race-library.json")
    }

    func load() throws -> RaceLibrary {
        guard FileManager.default.fileExists(atPath: libraryURL.path) else { return RaceLibrary() }
        return try JSONDecoder().decode(RaceLibrary.self, from: Data(contentsOf: libraryURL))
    }

    func save(_ library: RaceLibrary) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(library).write(to: libraryURL, options: .atomic)
    }

    func newAudioURL() throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: UUID().uuidString + ".m4a")
    }

    func audioURL(for cheer: Cheer) -> URL? {
        if cheer.isBundled {
            return Bundle.main.url(forResource: cheer.fileName, withExtension: nil)
        }
        return directory.appending(path: cheer.fileName)
    }
}
