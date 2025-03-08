import SwiftUI
import SwiftData
import CloudKit

@main
struct FogMapApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  // SwiftData ModelContainer to store VisitedLocation.
  // This container is used throughout the app to persist data.
  @State private var modelContainer: ModelContainer = {
    do {
      // Create a CloudKit schema configuration
      let schema = Schema([VisitedLocation.self])

      // Configure for CloudKit sync
      let modelConfiguration = ModelConfiguration(
        cloudKitDatabase: .private("iCloud.me.dutour.mathieu.fowirl")
      )

      // Create container with CloudKit configuration
      let container = try ModelContainer(
        for: schema,
        configurations: [modelConfiguration]
      )

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
