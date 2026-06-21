import Foundation
import ActivityKit
import Combine

@MainActor
final class ActivityManager: ObservableObject {

    static let shared = ActivityManager()

    private var activity: Activity<VacationActivityAttributes>?
    private var updateTask: Task<Void, Never>?

    // Start a Live Activity for the given trip. Call once when the trip begins.
    func start(trip: Trip) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard activity == nil else { return }

        let snapshot = ScheduleEngine.snapshot(from: trip.sortedEvents)
        guard let current = snapshot.current else { return }

        let state = contentState(from: snapshot, current: current)
        let attributes = VacationActivityAttributes(tripTitle: trip.title)
        let content = ActivityContent(state: state, staleDate: .now.addingTimeInterval(300))

        do {
            activity = try Activity.request(attributes: attributes, content: content)
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    // Push a new snapshot into the active Live Activity.
    func update(snapshot: LiveActivitySnapshot, travelPhases: [String: TravelPhase]) {
        guard let activity, let current = snapshot.current else { return }
        let state = contentState(from: snapshot, current: current)
        let content = ActivityContent(state: state, staleDate: .now.addingTimeInterval(300))

        updateTask?.cancel()
        updateTask = Task {
            await activity.update(content)
        }
    }

    // End the Live Activity when the trip is over.
    func end(snapshot: LiveActivitySnapshot) {
        guard let activity else { return }

        let finalState: VacationActivityAttributes.ContentState
        if let current = snapshot.current {
            finalState = contentState(from: snapshot, current: current)
        } else if let prev = snapshot.previous {
            finalState = VacationActivityAttributes.ContentState(
                previousTitle: nil,
                previousTimeText: nil,
                previousStatus: nil,
                currentTitle: prev.title,
                currentPhaseLabel: "Done",
                currentTimeText: prev.timeText,
                currentProgressStart: prev.startAt,
                currentProgressEnd: prev.endAt ?? prev.startAt,
                isLate: false,
                nextTitle: nil,
                nextTimeText: nil
            )
        } else {
            return
        }

        let content = ActivityContent(state: finalState, staleDate: nil)
        Task {
            await activity.end(content, dismissalPolicy: .after(.now.addingTimeInterval(60)))
        }
        self.activity = nil
    }

    // MARK: - Private

    private func contentState(
        from snapshot: LiveActivitySnapshot,
        current: EventSummary
    ) -> VacationActivityAttributes.ContentState {
        let progressStart = current.startAt
        let progressEnd = current.endAt ?? current.startAt.addingTimeInterval(3600)

        return VacationActivityAttributes.ContentState(
            previousTitle: snapshot.previous?.title,
            previousTimeText: snapshot.previous?.timeText,
            previousStatus: snapshot.previous?.status,
            currentTitle: current.title,
            currentPhaseLabel: snapshot.currentPhaseLabel,
            currentTimeText: current.timeText,
            currentProgressStart: progressStart,
            currentProgressEnd: progressEnd,
            isLate: current.status == .late,
            nextTitle: snapshot.next?.title,
            nextTimeText: snapshot.next?.timeText
        )
    }
}
