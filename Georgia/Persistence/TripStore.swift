import Foundation

private let appGroupID = "group.com.yourapp.georgia"
private let tripKey = "active_trip"

final class TripStore: ObservableObject {

    static let shared = TripStore()

    @Published private(set) var trip: Trip?

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    init() {
        load()
    }

    func save(_ trip: Trip) {
        self.trip = trip
        guard let data = try? JSONEncoder().encode(trip) else { return }
        defaults?.set(data, forKey: tripKey)
    }

    func load() {
        guard
            let data = defaults?.data(forKey: tripKey),
            let trip = try? JSONDecoder().decode(Trip.self, from: data)
        else { return }
        self.trip = trip
    }

    func updateEventStatus(id: String, status: EventStatus, manuallyCompleted: Bool = false) {
        guard var trip else { return }
        guard let idx = trip.events.firstIndex(where: { $0.id == id }) else { return }
        trip.events[idx].status = status
        trip.events[idx].manuallyCompleted = manuallyCompleted
        save(trip)
    }

    // MARK: - Export / Import

    func export() throws -> Data {
        guard var trip else { throw TripStoreError.noTrip }
        var exported = trip
        exported.exportedAt = .now
        return try JSONEncoder().encode(exported)
    }

    func `import`(from data: Data) throws {
        let trip = try JSONDecoder().decode(Trip.self, from: data)
        save(trip)
    }
}

enum TripStoreError: Error {
    case noTrip
}
