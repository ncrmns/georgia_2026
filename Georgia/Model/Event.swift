import Foundation
import CoreLocation

// MARK: - Enums

enum EventType: String, Codable {
    case deadline
    case travel
    case activity
}

enum LocationRule: String, Codable {
    case none
    case atOrigin
    case atDestination
    case insideRegion
}

enum CompletionMode: String, Codable {
    case manual
    case timeBased
    case locationBased
    case hybrid
}

enum EventStatus: String, Codable {
    case upcoming
    case active
    case late
    case done
    case skipped
    case arrived
}

// MARK: - Supporting types

struct GeoPoint: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let radiusMeters: Double

    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Event

struct Event: Identifiable, Codable, Equatable {
    let id: String
    let type: EventType
    let title: String
    let startAt: Date
    let endAt: Date?
    let durationMinutes: Int?

    // Location
    let locationRule: LocationRule
    let originPoint: GeoPoint?
    let destinationPoint: GeoPoint?

    // Completion
    let completionMode: CompletionMode
    let gracePeriodMinutes: Int

    // Mutable state
    var status: EventStatus
    var manuallyCompleted: Bool

    // Display
    let displayPriority: Int
    let notes: String?

    init(
        id: String = UUID().uuidString,
        type: EventType,
        title: String,
        startAt: Date,
        endAt: Date? = nil,
        durationMinutes: Int? = nil,
        locationRule: LocationRule = .none,
        originPoint: GeoPoint? = nil,
        destinationPoint: GeoPoint? = nil,
        completionMode: CompletionMode = .timeBased,
        gracePeriodMinutes: Int = 0,
        status: EventStatus = .upcoming,
        manuallyCompleted: Bool = false,
        displayPriority: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.startAt = startAt
        self.endAt = endAt ?? (durationMinutes.map { startAt.addingTimeInterval(Double($0) * 60) })
        self.durationMinutes = durationMinutes
        self.locationRule = locationRule
        self.originPoint = originPoint
        self.destinationPoint = destinationPoint
        self.completionMode = completionMode
        self.gracePeriodMinutes = gracePeriodMinutes
        self.status = status
        self.manuallyCompleted = manuallyCompleted
        self.displayPriority = displayPriority
        self.notes = notes
    }

    var effectiveEndAt: Date? {
        endAt ?? durationMinutes.map { startAt.addingTimeInterval(Double($0) * 60) }
    }
}

// MARK: - Trip

struct Trip: Identifiable, Codable {
    let id: String
    var title: String
    var events: [Event]
    var exportedAt: Date?

    init(id: String = UUID().uuidString, title: String, events: [Event] = []) {
        self.id = id
        self.title = title
        self.events = events
    }

    var sortedEvents: [Event] {
        events.sorted { $0.startAt < $1.startAt }
    }
}
