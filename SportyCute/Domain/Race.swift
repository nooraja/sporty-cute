import CoreLocation
import Foundation

enum Sport: String, Codable, CaseIterable, Identifiable {
    case swim = "Swim"
    case bike = "Bike"
    case run = "Run"

    var id: Self { self }

    var icon: String {
        switch self {
        case .swim: "figure.pool.swim"
        case .bike: "bicycle"
        case .run: "figure.run"
        }
    }
}

enum RaceFormat: String, CaseIterable, Identifiable {
    case run = "Run"
    case triathlon = "Triathlon"

    var id: Self { self }

    var legs: [Sport] {
        switch self {
        case .run: [.run]
        case .triathlon: [.swim, .bike, .run]
        }
    }
}

enum Transition: String, Codable, CaseIterable, Identifiable {
    case t1 = "T1"
    case t2 = "T2"

    var id: Self { self }
    var nextSport: Sport { self == .t1 ? .bike : .run }
}

struct Checkpoint: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let distance: String
    var latitude: Double
    var longitude: Double

    func contains(_ location: CLLocation, radius: CLLocationDistance = 60) -> Bool {
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= radius,
              abs(location.timestamp.timeIntervalSinceNow) < 30 else { return false }

        return location.distance(from: CLLocation(latitude: latitude, longitude: longitude)) <= radius
    }
}

struct RaceProgress {
    let format: RaceFormat
    let startedAt: Date
    private(set) var legIndex = 0
    private(set) var visited: Set<Checkpoint.ID> = []
    private(set) var heard: [Cheer.ID] = []

    var sport: Sport { format.legs[legIndex] }

    var nextTransition: Transition? {
        guard format == .triathlon else { return nil }
        switch sport {
        case .swim: return .t1
        case .bike: return .t2
        case .run: return nil
        }
    }

    mutating func advance(_ transition: Transition) {
        guard nextTransition == transition else { return }
        legIndex += 1
    }

    mutating func visit(_ checkpoint: Checkpoint) -> Bool {
        visited.insert(checkpoint.id).inserted
    }

    mutating func markHeard(_ cheer: Cheer) {
        guard !heard.contains(cheer.id) else { return }
        heard.append(cheer.id)
    }
}

struct RaceRecap: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let duration: TimeInterval
    let checkpoints: Int
    let cheers: [Cheer.ID]
}
