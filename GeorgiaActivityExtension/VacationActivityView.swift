import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Lock Screen / Notification banner

struct VacationLockScreenView: View {
    let state: VacationActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 6) {
            currentRow
            Divider().opacity(0.4)
            adjacentRow(
                label: "PREV",
                title: state.previousTitle,
                timeText: state.previousTimeText,
                isLate: state.previousStatus == .late
            )
            adjacentRow(
                label: "NEXT",
                title: state.nextTitle,
                timeText: state.nextTimeText,
                isLate: false
            )
        }
        .padding(12)
    }

    private var currentRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(state.currentPhaseLabel, systemImage: phaseIcon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(state.currentTimeText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(state.currentTitle)
                .font(.headline)
                .foregroundStyle(state.isLate ? .red : .primary)
            ProgressView(
                timerInterval: state.currentProgressStart...state.currentProgressEnd,
                countsDown: false
            )
            .tint(state.isLate ? .red : .blue)
        }
    }

    private func adjacentRow(label: String, title: String?, timeText: String?, isLate: Bool) -> some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 32, alignment: .leading)
            Text(title ?? "—")
                .font(.caption)
                .foregroundStyle(isLate ? .red : .secondary)
            Spacer()
            Text(timeText ?? "")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var phaseIcon: String {
        switch state.currentPhaseLabel {
        case "En route":  return "car.fill"
        case "Deadline":  return "exclamationmark.circle.fill"
        case "Arrived":   return "checkmark.circle.fill"
        default:          return "clock.fill"
        }
    }
}

// MARK: - Dynamic Island compact

struct VacationDynamicIslandCompactLeading: View {
    let state: VacationActivityAttributes.ContentState

    var body: some View {
        Image(systemName: phaseIcon)
            .foregroundStyle(state.isLate ? .red : .blue)
    }

    private var phaseIcon: String {
        switch state.currentPhaseLabel {
        case "En route": return "car.fill"
        case "Deadline": return "exclamationmark.circle"
        default:         return "clock"
        }
    }
}

struct VacationDynamicIslandCompactTrailing: View {
    let state: VacationActivityAttributes.ContentState

    var body: some View {
        Text(state.currentTitle)
            .font(.caption2)
            .lineLimit(1)
    }
}

// MARK: - Dynamic Island expanded

struct VacationDynamicIslandExpandedView: View {
    let state: VacationActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(state.currentTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(state.isLate ? .red : .primary)
                Spacer()
                Text(state.currentPhaseLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(
                timerInterval: state.currentProgressStart...state.currentProgressEnd,
                countsDown: false
            )
            .tint(state.isLate ? .red : .blue)
            HStack {
                if let prev = state.previousTitle {
                    Text("← \(prev)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let next = state.nextTitle {
                    Text("\(next) →")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
