import Foundation
import Combine

@MainActor
final class TripCoordinator: ObservableObject {

    static let shared = TripCoordinator()

    @Published private(set) var snapshot: LiveActivitySnapshot = .empty

    private let store = TripStore.shared
    private let location = LocationEngine.shared
    private let activity = ActivityManager.shared

    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    func start() {
        guard let trip = store.trip else { return }

        location.requestAuthorization()
        location.startTracking(events: trip.sortedEvents)
        activity.start(trip: trip)

        // Recompute snapshot every 30 seconds and on location changes
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { await self?.recompute() }
        }

        location.$travelPhases
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { await self?.recompute() }
            }
            .store(in: &cancellables)

        Task { await recompute() }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        cancellables.removeAll()
        location.stopTracking()
        activity.end(snapshot: snapshot)
    }

    func markCurrentDone() {
        guard let id = snapshot.current?.id else { return }
        store.updateEventStatus(id: id, status: .done, manuallyCompleted: true)
        Task { await recompute() }
    }

    // MARK: - Private

    private func recompute() async {
        guard let trip = store.trip else { return }
        let phases = location.travelPhases
        let newSnapshot = ScheduleEngine.snapshot(from: trip.sortedEvents, travelPhases: phases)
        snapshot = newSnapshot
        activity.update(snapshot: newSnapshot, travelPhases: phases)
    }
}
