import Foundation

struct EventSummary: Codable, Equatable {
    let id: String
    let title: String
    let type: EventType
    let status: EventStatus
    let startAt: Date
    let endAt: Date?
    let timeText: String
    let phaseText: String
}

struct LiveActivitySnapshot: Codable, Equatable {
    let previous: EventSummary?
    let current: EventSummary?
    let next: EventSummary?

    let currentProgress: Double
    let currentPhaseLabel: String
    let locationDerivedState: String?
    let updatedAt: Date

    static let empty = LiveActivitySnapshot(
        previous: nil,
        current: nil,
        next: nil,
        currentProgress: 0,
        currentPhaseLabel: "",
        locationDerivedState: nil,
        updatedAt: .now
    )
}
