import ActivityKit
import Foundation

struct VacationActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let previousTitle: String?
        let previousTimeText: String?
        let previousStatus: EventStatus?

        let currentTitle: String
        let currentPhaseLabel: String
        let currentTimeText: String
        let currentProgressStart: Date
        let currentProgressEnd: Date
        let isLate: Bool

        let nextTitle: String?
        let nextTimeText: String?
    }

    // Static: set once when the activity starts, never changes
    let tripTitle: String
}
