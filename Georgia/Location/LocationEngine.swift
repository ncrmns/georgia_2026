import Foundation
import CoreLocation
import Combine

final class LocationEngine: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LocationEngine()

    @Published private(set) var travelPhases: [String: TravelPhase] = [:]

    private let manager = CLLocationManager()
    private var trackedEvents: [Event] = []
    private var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking(events: [Event]) {
        trackedEvents = events.filter { $0.type == .travel && $0.locationRule != .none }
        if !trackedEvents.isEmpty {
            manager.startUpdatingLocation()
        }
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        trackedEvents = []
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        recomputePhases(for: location)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if !trackedEvents.isEmpty { manager.startUpdatingLocation() }
        default:
            manager.stopUpdatingLocation()
        }
    }

    // MARK: - Phase computation

    private func recomputePhases(for location: CLLocation) {
        var updated: [String: TravelPhase] = travelPhases

        for event in trackedEvents {
            let phase = computePhase(for: event, userLocation: location)
            updated[event.id] = phase
        }

        if updated != travelPhases {
            DispatchQueue.main.async {
                self.travelPhases = updated
            }
        }
    }

    private func computePhase(for event: Event, userLocation: CLLocation) -> TravelPhase {
        let now = Date.now

        if let origin = event.originPoint {
            let distanceToOrigin = userLocation.distance(from: origin.clLocation)
            if distanceToOrigin <= origin.radiusMeters && now < event.startAt {
                return .notDeparted
            }
        }

        if let destination = event.destinationPoint {
            let distanceToDestination = userLocation.distance(from: destination.clLocation)
            if distanceToDestination <= destination.radiusMeters {
                return .arrived
            }
        }

        // Check if delayed: past target arrival and not yet arrived
        if let end = event.effectiveEndAt, now > end {
            return .delayed
        }

        return .enRoute
    }
}
