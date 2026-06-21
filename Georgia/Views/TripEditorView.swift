import SwiftUI

struct TripEditorView: View {
    @ObservedObject private var store = TripStore.shared
    @ObservedObject private var coordinator = TripCoordinator.shared

    @State private var showingNewEvent = false
    @State private var editingEvent: Event? = nil
    @State private var showingExportSheet = false
    @State private var exportedData: Data? = nil
    @State private var showingImporter = false
    @State private var tripTitle = ""
    @State private var isEditingTitle = false

    var body: some View {
        NavigationStack {
            Group {
                if let trip = store.trip, !trip.sortedEvents.isEmpty {
                    eventList(trip: trip)
                } else {
                    emptyState
                }
            }
            .navigationTitle(store.trip?.title ?? "Trip")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showingNewEvent) {
                EventEditorView { event in
                    addEvent(event)
                }
            }
            .sheet(item: $editingEvent) { event in
                EventEditorView(existing: event) { updated in
                    updateEvent(updated)
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportedData {
                    ShareSheet(data: data, filename: "\(store.trip?.title ?? "trip").json")
                }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                importTrip(result: result)
            }
        }
    }

    // MARK: - Subviews

    private func eventList(trip: Trip) -> some View {
        List {
            snapshotBanner

            ForEach(groupedEvents(trip.sortedEvents), id: \.0) { day, events in
                Section(header: Text(day)) {
                    ForEach(events) { event in
                        EventRowView(event: event)
                            .contentShape(Rectangle())
                            .onTapGesture { editingEvent = event }
                            .swipeActions(edge: .leading) {
                                Button {
                                    store.updateEventStatus(id: event.id, status: .done, manuallyCompleted: true)
                                } label: {
                                    Label("Done", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteEvent(id: event.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var snapshotBanner: some View {
        let snap = coordinator.snapshot
        if let current = snap.current {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("NOW")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(snap.currentPhaseLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(current.title)
                        .font(.headline)
                    ProgressView(value: snap.currentProgress)
                        .tint(current.status == .late ? .red : .blue)
                    if let next = snap.next {
                        Text("Next: \(next.title) at \(next.timeText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Events", systemImage: "calendar.badge.plus")
        } description: {
            Text("Add your first event or import a trip.")
        } actions: {
            Button("Add Event") { showingNewEvent = true }
                .buttonStyle(.borderedProminent)
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Button("Import Trip", systemImage: "square.and.arrow.down") {
                    showingImporter = true
                }
                Button("Export Trip", systemImage: "square.and.arrow.up") {
                    exportTrip()
                }
                Divider()
                Button("New Trip", systemImage: "plus.square") {
                    newTrip()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showingNewEvent = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - Actions

    private func addEvent(_ event: Event) {
        if store.trip == nil {
            store.save(Trip(title: "My Trip", events: [event]))
        } else {
            var trip = store.trip!
            trip.events.append(event)
            store.save(trip)
        }
    }

    private func updateEvent(_ event: Event) {
        guard var trip = store.trip else { return }
        guard let idx = trip.events.firstIndex(where: { $0.id == event.id }) else { return }
        trip.events[idx] = event
        store.save(trip)
    }

    private func deleteEvent(id: String) {
        guard var trip = store.trip else { return }
        trip.events.removeAll { $0.id == id }
        store.save(trip)
    }

    private func exportTrip() {
        exportedData = try? store.export()
        if exportedData != nil { showingExportSheet = true }
    }

    private func importTrip(result: Result<URL, Error>) {
        guard let url = try? result.get(),
              url.startAccessingSecurityScopedResource(),
              let data = try? Data(contentsOf: url) else { return }
        url.stopAccessingSecurityScopedResource()
        try? store.import(from: data)
    }

    private func newTrip() {
        store.save(Trip(title: "New Trip"))
    }

    private func groupedEvents(_ events: [Event]) -> [(String, [Event])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        let dict = Dictionary(grouping: events) { formatter.string(from: $0.startAt) }
        return dict.sorted { a, b in
            let af = events.first { formatter.string(from: $0.startAt) == a.0 }?.startAt ?? .distantPast
            let bf = events.first { formatter.string(from: $0.startAt) == b.0 }?.startAt ?? .distantPast
            return af < bf
        }
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
