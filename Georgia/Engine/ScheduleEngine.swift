import Foundation

struct ScheduleContext {
    let previous: Event?
    let current: Event?
    let next: Event?
}

struct ScheduleEngine {

    // Returns previous, current, and next events relative to `now`.
    static func context(
        from events: [Event],
        at now: Date = .now,
        travelPhases: [String: TravelPhase] = [:]
    ) -> ScheduleContext {
        let sorted = events.sorted { $0.startAt < $1.startAt }

        let currentIndex = sorted.firstIndex { event in
            let phase = travelPhases[event.id]
            let status = StatusEngine.status(for: event, at: now, travelPhase: phase)
            return status == .active || status == .arrived
        }

        if let idx = currentIndex {
            return ScheduleContext(
                previous: idx > 0 ? sorted[idx - 1] : nil,
                current: sorted[idx],
                next: idx + 1 < sorted.count ? sorted[idx + 1] : nil
            )
        }

        // No active event — find the next upcoming one
        let nextIndex = sorted.firstIndex { $0.startAt > now }

        if let idx = nextIndex {
            return ScheduleContext(
                previous: idx > 0 ? sorted[idx - 1] : nil,
                current: nil,
                next: sorted[idx]
            )
        }

        // All events are past
        return ScheduleContext(
            previous: sorted.last,
            current: nil,
            next: nil
        )
    }

    static func snapshot(
        from events: [Event],
        at now: Date = .now,
        travelPhases: [String: TravelPhase] = [:]
    ) -> LiveActivitySnapshot {
        let ctx = context(from: events, at: now, travelPhases: travelPhases)

        let travelPhase = ctx.current.flatMap { travelPhases[$0.id] }
        let progress = ctx.current.map { StatusEngine.progress(for: $0, at: now, travelPhase: travelPhase) } ?? 0
        let phaseLabel = ctx.current.map { StatusEngine.phaseLabel(for: $0, travelPhase: travelPhase) } ?? ""

        return LiveActivitySnapshot(
            previous: ctx.previous.map { summary(for: $0, at: now, travelPhase: travelPhases[$0.id]) },
            current:  ctx.current.map  { summary(for: $0, at: now, travelPhase: travelPhase) },
            next:     ctx.next.map     { summary(for: $0, at: now, travelPhase: travelPhases[$0.id]) },
            currentProgress: progress,
            currentPhaseLabel: phaseLabel,
            locationDerivedState: travelPhase?.rawValue,
            updatedAt: now
        )
    }

    // MARK: - Private

    private static func summary(for event: Event, at now: Date, travelPhase: TravelPhase?) -> EventSummary {
        let status = StatusEngine.status(for: event, at: now, travelPhase: travelPhase)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let start = formatter.string(from: event.startAt)
        let timeText: String
        if let end = event.effectiveEndAt {
            timeText = "\(start)–\(formatter.string(from: end))"
        } else {
            timeText = start
        }

        let phaseText: String
        switch status {
        case .upcoming: phaseText = timeText
        case .active:   phaseText = travelPhase?.rawValue ?? "Active"
        case .late:     phaseText = "Late"
        case .done:     phaseText = "Done"
        case .arrived:  phaseText = "Arrived"
        case .skipped:  phaseText = "Skipped"
        }

        return EventSummary(
            id: event.id,
            title: event.title,
            type: event.type,
            status: status,
            startAt: event.startAt,
            endAt: event.effectiveEndAt,
            timeText: timeText,
            phaseText: phaseText
        )
    }
}
