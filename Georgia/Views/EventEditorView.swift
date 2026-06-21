import SwiftUI

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss

    var existing: Event? = nil
    var onSave: (Event) -> Void

    // Basic
    @State private var title = ""
    @State private var type: EventType = .activity
    @State private var notes = ""

    // Time
    @State private var startAt = Date.now.roundedToNextHour()
    @State private var hasEndTime = false
    @State private var endAt = Date.now.roundedToNextHour().addingTimeInterval(3600)
    @State private var durationMinutes = 60

    // Deadline / Activity mode
    @State private var completionMode: CompletionMode = .timeBased
    @State private var gracePeriodMinutes = 0

    // Travel
    @State private var originName = ""
    @State private var destinationName = ""
    @State private var originLat = ""
    @State private var originLon = ""
    @State private var originRadius = 200.0
    @State private var destinationLat = ""
    @State private var destinationLon = ""
    @State private var destinationRadius = 200.0
    @State private var useLocationTracking = false

    var body: some View {
        NavigationStack {
            Form {
                basicSection
                timeSection
                if type == .travel { travelSection }
                if type != .travel { completionSection }
                if gracePeriodMinutes > 0 || type == .deadline { graceSection }
            }
            .navigationTitle(existing == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populate() }
        }
    }

    // MARK: - Sections

    private var basicSection: some View {
        Section("Event") {
            TextField("Title", text: $title)
            Picker("Type", selection: $type) {
                Label("Deadline", systemImage: "exclamationmark.circle.fill").tag(EventType.deadline)
                Label("Travel", systemImage: "car.fill").tag(EventType.travel)
                Label("Activity", systemImage: "mappin.circle.fill").tag(EventType.activity)
            }
            TextField("Notes (optional)", text: $notes)
                .foregroundStyle(.secondary)
        }
    }

    private var timeSection: some View {
        Section("Time") {
            DatePicker("Start", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
            if type == .travel || hasEndTime {
                DatePicker("End", selection: $endAt, in: startAt..., displayedComponents: [.date, .hourAndMinute])
            } else {
                Stepper("Duration: \(durationMinutes) min", value: $durationMinutes, in: 5...480, step: 5)
            }
            if type != .travel {
                Toggle("Set end time", isOn: $hasEndTime)
            }
        }
    }

    private var travelSection: some View {
        Section {
            Toggle("Enable location tracking", isOn: $useLocationTracking)
            if useLocationTracking {
                Group {
                    Text("Origin").font(.caption).foregroundStyle(.secondary)
                    TextField("Name (e.g. Hotel)", text: $originName)
                    HStack {
                        TextField("Lat", text: $originLat).keyboardType(.decimalPad)
                        TextField("Lon", text: $originLon).keyboardType(.decimalPad)
                    }
                    Stepper("Radius: \(Int(originRadius)) m", value: $originRadius, in: 50...1000, step: 50)
                }
                Group {
                    Text("Destination").font(.caption).foregroundStyle(.secondary)
                    TextField("Name (e.g. Airport)", text: $destinationName)
                    HStack {
                        TextField("Lat", text: $destinationLat).keyboardType(.decimalPad)
                        TextField("Lon", text: $destinationLon).keyboardType(.decimalPad)
                    }
                    Stepper("Radius: \(Int(destinationRadius)) m", value: $destinationRadius, in: 50...1000, step: 50)
                }
            }
        } header: {
            Text("Travel")
        } footer: {
            Text("Location tracking lets the app detect departure and arrival automatically.")
        }
    }

    private var completionSection: some View {
        Section("Completion") {
            Picker("Mode", selection: $completionMode) {
                Text("Time-based").tag(CompletionMode.timeBased)
                Text("Manual").tag(CompletionMode.manual)
            }
            .pickerStyle(.segmented)
        }
    }

    private var graceSection: some View {
        Section {
            Stepper("Grace period: \(gracePeriodMinutes) min", value: $gracePeriodMinutes, in: 0...60, step: 5)
        } footer: {
            Text("How long after the deadline before it's marked late.")
        }
    }

    // MARK: - Logic

    private func populate() {
        guard let e = existing else { return }
        title = e.title
        type = e.type
        notes = e.notes ?? ""
        startAt = e.startAt
        completionMode = e.completionMode
        gracePeriodMinutes = e.gracePeriodMinutes

        if let end = e.endAt {
            hasEndTime = true
            endAt = end
        } else if let dur = e.durationMinutes {
            durationMinutes = dur
        }

        if let origin = e.originPoint {
            useLocationTracking = true
            originLat = "\(origin.latitude)"
            originLon = "\(origin.longitude)"
            originRadius = origin.radiusMeters
        }
        if let dest = e.destinationPoint {
            destinationLat = "\(dest.latitude)"
            destinationLon = "\(dest.longitude)"
            destinationRadius = dest.radiusMeters
        }
    }

    private func save() {
        let resolvedEnd: Date? = (type == .travel || hasEndTime) ? endAt : nil
        let resolvedDuration: Int? = (!hasEndTime && type != .travel) ? durationMinutes : nil

        var originPoint: GeoPoint? = nil
        var destinationPoint: GeoPoint? = nil

        if type == .travel && useLocationTracking {
            if let lat = Double(originLat), let lon = Double(originLon) {
                originPoint = GeoPoint(latitude: lat, longitude: lon, radiusMeters: originRadius)
            }
            if let lat = Double(destinationLat), let lon = Double(destinationLon) {
                destinationPoint = GeoPoint(latitude: lat, longitude: lon, radiusMeters: destinationRadius)
            }
        }

        let event = Event(
            id: existing?.id ?? UUID().uuidString,
            type: type,
            title: title.trimmingCharacters(in: .whitespaces),
            startAt: startAt,
            endAt: resolvedEnd,
            durationMinutes: resolvedDuration,
            locationRule: originPoint != nil ? .atOrigin : .none,
            originPoint: originPoint,
            destinationPoint: destinationPoint,
            completionMode: type == .travel ? .locationBased : completionMode,
            gracePeriodMinutes: gracePeriodMinutes,
            status: existing?.status ?? .upcoming,
            manuallyCompleted: existing?.manuallyCompleted ?? false,
            notes: notes.isEmpty ? nil : notes
        )

        onSave(event)
        dismiss()
    }
}

// MARK: - Date helper

private extension Date {
    func roundedToNextHour() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: self)
        components.hour = (components.hour ?? 0) + 1
        components.minute = 0
        return Calendar.current.date(from: components) ?? self
    }
}
