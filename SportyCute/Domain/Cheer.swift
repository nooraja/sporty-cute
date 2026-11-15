import Foundation

struct Cheer: Identifiable, Codable {
    let id: UUID
    let title: String
    let sender: String
    let checkpointID: Checkpoint.ID
    let fileName: String
    let duration: TimeInterval
    let isBundled: Bool
}

struct PortfolioData {
    static let checkpoints = [
        Checkpoint(id: "start", name: "The Send-off", distance: "KM 01", latitude: -8.67868, longitude: 115.26677),
        Checkpoint(id: "middle", name: "The Long Middle", distance: "KM 05", latitude: -8.69154, longitude: 115.26304),
        Checkpoint(id: "finish", name: "Finish-Mode", distance: "KM 10", latitude: -8.70822, longitude: 115.26282)
    ]

    static var cheers: [Cheer] {
        [
            Cheer(
                id: stableID(1), title: "Little steps, big heart", sender: "Mia",
                checkpointID: "start", fileName: "mia.m4a", duration: 6, isBundled: true
            ),
            Cheer(
                id: stableID(2), title: "You found your rhythm", sender: "Jo",
                checkpointID: "middle", fileName: "jo.m4a", duration: 6, isBundled: true
            ),
            Cheer(
                id: stableID(3), title: "Eyes on that finish", sender: "Sam",
                checkpointID: "finish", fileName: "sam.m4a", duration: 6, isBundled: true
            )
        ]
    }

    private static func stableID(_ value: UInt8) -> UUID {
        UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, value))
    }
}
