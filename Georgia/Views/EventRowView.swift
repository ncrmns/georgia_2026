import SwiftUI

struct EventRowView: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            typeIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.body)
                HStack(spacing: 4) {
                    Text(timeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let notes = event.notes {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            statusBadge
        }
        .padding(.vertical, 2)
    }

    private var typeIcon: some View {
        Image(systemName: iconName)
            .font(.body)
            .foregroundStyle(iconColor)
            .frame(width: 28)
    }

    private var statusBadge: some View {
        Group {
            switch event.status {
            case .late:
                Text("Late")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            case .done, .arrived:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .skipped:
                Image(systemName: "minus.circle")
                    .foregroundStyle(.secondary)
            default:
                EmptyView()
            }
        }
    }

    private var iconName: String {
        switch event.type {
        case .deadline: return "exclamationmark.circle.fill"
        case .travel:   return "car.fill"
        case .activity: return "mappin.circle.fill"
        }
    }

    private var iconColor: Color {
        switch event.type {
        case .deadline: return .orange
        case .travel:   return .blue
        case .activity: return .purple
        }
    }

    private var timeText: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        let start = f.string(from: event.startAt)
        if let end = event.effectiveEndAt {
            return "\(start) – \(f.string(from: end))"
        }
        return start
    }
}
