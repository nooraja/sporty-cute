import CoreLocation

@MainActor
final class LocationTracker: NSObject {
    private let manager = CLLocationManager()
    private var trackingRequested = false

    var onLocation: ((CLLocation) -> Void)?
    var onStatus: ((String) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.pausesLocationUpdatesAutomatically = false
    }

    func start() {
        trackingRequested = true
        updateAuthorization()
    }

    func stop() {
        trackingRequested = false
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    private func updateAuthorization() {
        guard trackingRequested else { return }

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
            manager.startUpdatingLocation()
            let precise = manager.accuracyAuthorization == .fullAccuracy
            onStatus?(precise ? "GPS active" : "Enable Precise Location in Settings for reliable cues.")
        case .denied, .restricted:
            onStatus?("Location unavailable. Enable access in Settings.")
        @unknown default:
            onStatus?("Location unavailable.")
        }
    }
}

// CLLocationManager calls its delegate on the run loop where it was created.
extension LocationTracker: @MainActor CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard trackingRequested else { return }
        for location in locations {
            onLocation?(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onStatus?(error.localizedDescription)
    }
}
