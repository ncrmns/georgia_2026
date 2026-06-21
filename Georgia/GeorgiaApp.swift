import SwiftUI

@main
struct GeorgiaApp: App {
    @StateObject private var coordinator = TripCoordinator.shared

    var body: some Scene {
        WindowGroup {
            TripEditorView()
                .onAppear {
                    coordinator.start()
                }
        }
    }
}
