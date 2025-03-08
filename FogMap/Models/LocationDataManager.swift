import Foundation
import CoreLocation
import SwiftData

// A singleton class to handle location updates and database operations
class LocationDataManager {
  static let shared = LocationDataManager()

  private var modelContext: ModelContext?

  // Set the model context from your SwiftUI app
  func setModelContext(_ context: ModelContext) {
    self.modelContext = context
  }

  // Process a new location update
  func processLocationUpdate(_ coordinate: CLLocationCoordinate2D) {
    guard let context = modelContext else {
      print("Error: ModelContext not set in LocationDataManager")
      return
    }

    // Run on a background thread to avoid UI blocking
    Task {
      await addVisitedLocationIfNeeded(coordinate: coordinate, context: context)
    }
  }

  // Add a new visited location if needed
  private func addVisitedLocationIfNeeded(coordinate: CLLocationCoordinate2D, context: ModelContext) async {
    // ~55m radius at the equator
    let threshold = 0.0005

    // Fetch existing locations that might be nearby
    // which are supported in SwiftData predicates
    let minLat = coordinate.latitude - threshold
    let maxLat = coordinate.latitude + threshold
    let minLon = coordinate.longitude - threshold
    let maxLon = coordinate.longitude + threshold

    let predicate = #Predicate<VisitedLocation> { visited in
      visited.latitude ?? -1000 >= minLat &&
      visited.latitude ?? 1000 <= maxLat &&
      visited.longitude ?? -1000.0 >= minLon &&
      visited.longitude ?? 1000.0 <= maxLon
    }

    let descriptor = FetchDescriptor<VisitedLocation>(predicate: predicate)

    do {
      // Perform database operations on the main thread
      let nearbyLocations = try await MainActor.run {
        try context.fetch(descriptor)
      }

      await MainActor.run {
        if let existingLocation = nearbyLocations.first {
          // Update existing location
          existingLocation.visit()
        } else {
          // Create new location
          let newSpot = VisitedLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
          context.insert(newSpot)
        }

        // Save changes
        do {
          try context.save()
        } catch {
          print("Error saving visited location: \(error)")
        }
      }
    } catch {
      print("Error fetching nearby locations: \(error)")
    }
  }
}
