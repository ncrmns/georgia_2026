import Foundation

enum TravelPhase: String {
    case notDeparted = "Not departed"
    case enRoute = "En route"
    case arrived = "Arrived"
    case delayed = "Delayed"
}

struct StatusEngine {

    // Compute the correct status for an event given the current time and optional travel phase.
    static func status(
        for event: Event,
        at now: Date = .now,
        travelPhase: TravelPhase? = nil
    ) -> EventStatus {
        if event.manuallyCompleted { return .done }
        if event.status == .skipped { return .skipped }

        switch event.type {
        case .deadline:
            return deadlineStatus(event: event, now: now)
        case .travel:
            return travelStatus(event: event, now: now, phase: travelPhase)
        case .activity:
            return activityStatus(event: event, now: now)
        }
    }

    // Compute 0.0–1.0 progress for the current event.
    static func progress(
        for event: Event,
        at now: Date = .now,
        travelPhase: TravelPhase? = nil
    ) -> Double {
        guard let end = event.effectiveEndAt else { return 0 }
        let total = end.timeIntervalSince(event.startAt)
        guard total > 0 else { return 1 }
        let elapsed = now.timeIntervalSince(event.startAt)
        return max(0, min(1, elapsed / total))
    }

    static func phaseLabel(for event: Event, travelPhase: TravelPhase? = nil) -> String {
        switch event.type {
        case .deadline: return "Deadline"
        case .activity: return "Activity"
        case .travel:   return travelPhase?.rawValue ?? "Travel"
        }
    }

    // MARK: - Private

    private static func deadlineStatus(event: Event, now: Date) -> EventStatus {
        if now < event.startAt { return .upcoming }
        let graceEnd = event.startAt.addingTimeInterval(Double(event.gracePeriodMinutes) * 60)
        if now <= graceEnd { return .active }
        if let end = event.effectiveEndAt, now <= end { return .active }
        return .late
    }

    private static func travelStatus(event: Event, now: Date, phase: TravelPhase?) -> EventStatus {
        if let phase {
            switch phase {
            case .notDeparted: return now < event.startAt ? .upcoming : .active
            case .enRoute:     return .active
            case .arrived:     return .arrived
            case .delayed:     return .late
            }
        }
        // Fallback: time-based
        if now < event.startAt { return .upcoming }
        guard let end = event.effectiveEndAt else { return .active }
        return now <= end ? .active : .late
    }

    private static func activityStatus(event: Event, now: Date) -> EventStatus {
        if now < event.startAt { return .upcoming }
        guard let end = event.effectiveEndAt else { return .active }
        if now <= end { return .active }
        let grace = end.addingTimeInterval(Double(event.gracePeriodMinutes) * 60)
        return now <= grace ? .done : .late
    }
}
