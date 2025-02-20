import SwiftUI
import SwiftData

@main
struct FogMapApp: App {
  // SwiftData ModelContainer to store VisitedLocation.
  // This container is used throughout the app to persist data.
  @State private var modelContainer: ModelContainer = {
    do {
      let container = try ModelContainer(for: VisitedLocation.self)
      return container
    } catch {
      fatalError("Failed to create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .modelContainer(modelContainer) // Inject SwiftData container
    }
  }
}
