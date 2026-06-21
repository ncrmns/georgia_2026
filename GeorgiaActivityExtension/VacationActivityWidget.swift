import SwiftUI
import WidgetKit
import ActivityKit

@main
struct VacationActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VacationActivityAttributes.self) { context in
            VacationLockScreenView(state: context.state)
                .activityBackgroundTint(.black.opacity(0.8))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VacationDynamicIslandExpandedView(state: context.state)
                }
            } compactLeading: {
                VacationDynamicIslandCompactLeading(state: context.state)
            } compactTrailing: {
                VacationDynamicIslandCompactTrailing(state: context.state)
            } minimal: {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.blue)
            }
        }
    }
}
