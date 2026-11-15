import CoreLocation
import Foundation
import Testing
@testable import SportyCute

struct RaceTests {
    @Test func checkpointTriggersOncePerRace() throws {
        let checkpoint = try #require(PortfolioData.checkpoints.first)
        var progress = RaceProgress(format: .run, startedAt: .now)

        let firstPass = progress.visit(checkpoint)
        let secondPass = progress.visit(checkpoint)
        #expect(firstPass)
        #expect(!secondPass)
        #expect(progress.visited.count == 1)
    }

    @Test func staleInaccurateAndDistantGPSFixesDoNotTrigger() throws {
        let checkpoint = try #require(PortfolioData.checkpoints.first)

        func fix(latitude: Double, accuracy: Double, age: TimeInterval = 0) -> CLLocation {
            CLLocation(
                coordinate: .init(latitude: latitude, longitude: checkpoint.longitude),
                altitude: 0,
                horizontalAccuracy: accuracy,
                verticalAccuracy: 0,
                timestamp: .now.addingTimeInterval(-age)
            )
        }

        #expect(checkpoint.contains(fix(latitude: checkpoint.latitude, accuracy: 12)))
        #expect(!checkpoint.contains(fix(latitude: checkpoint.latitude, accuracy: 90)))
        #expect(!checkpoint.contains(fix(latitude: checkpoint.latitude, accuracy: 12, age: 60)))
        #expect(!checkpoint.contains(fix(latitude: checkpoint.latitude + 0.002, accuracy: 12)))
    }

    @Test func triathlonRejectsOutOfOrderAndRepeatedTransitions() {
        var progress = RaceProgress(format: .triathlon, startedAt: .now)

        progress.advance(.t2)
        #expect(progress.sport == .swim)
        progress.advance(.t1)
        progress.advance(.t1)
        #expect(progress.sport == .bike)
        progress.advance(.t2)
        #expect(progress.sport == .run)
        #expect(progress.nextTransition == nil)
    }

    @Test func recapKeepsPlaybackOrderWithoutDuplicates() throws {
        let first = try #require(PortfolioData.cheers.first)
        let last = try #require(PortfolioData.cheers.last)
        var progress = RaceProgress(format: .run, startedAt: .now)
        progress.markHeard(last)
        progress.markHeard(first)
        progress.markHeard(last)

        #expect(progress.heard == [last.id, first.id])
    }
}
