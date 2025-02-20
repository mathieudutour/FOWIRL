import SwiftUI
import MapKit
import SwiftData

struct ContentView: View {
  private var debugMode = false
  @StateObject private var locationManager = LocationManager()

  // Fetch all visited locations from SwiftData
  @Query private var visitedLocations: [VisitedLocation]

  // Access SwiftData’s ModelContext for creating new records
  @Environment(\.modelContext) private var context

  var body: some View {
    ZStack {
      // 1. Apple Maps with Fog Overlay
      AppleMapsView(
        debugMode: debugMode,
        onMapTap: { coordinate in
          addVisitedLocationIfNeeded(coordinate: coordinate)
        },
        visitedLocations: visitedLocations
      )
      .edgesIgnoringSafeArea(.all)

      // 2. Simple HUD
//      VStack {
//        Spacer()
//        HStack {
//          Spacer()
//          VStack(alignment: .leading) {
//            Text("Visited: \(visitedLocations.count)")
//              .foregroundColor(.white)
//              .padding(8)
//              .background(Color.black.opacity(0.7))
//              .cornerRadius(8)
//            if let loc = locationManager.currentLocation {
//              Text(
//                String(
//                  format: "Lat: %.4f\nLon: %.4f",
//                  loc.coordinate.latitude,
//                  loc.coordinate.longitude
//                )
//              )
//              .foregroundColor(.white)
//              .padding(8)
//              .background(Color.black.opacity(0.7))
//              .cornerRadius(8)
//            }
//          }
//          .padding()
//        }
//      }
    }
    .onReceive(locationManager.$currentLocation) { newLocation in
      guard let newLocation else { return }
      // Check if we should store a new visited location
      addVisitedLocationIfNeeded(coordinate: newLocation.coordinate)
    }
  }

  // MARK: - Insert new visited location if we haven't saved one nearby
  private func addVisitedLocationIfNeeded(coordinate: CLLocationCoordinate2D) {
    // ~55m radius at the equator
    let threshold = 0.0005

    let isAlreadyVisited = visitedLocations.contains { visited in
      abs(visited.latitude - coordinate.latitude) < threshold &&
      abs(visited.longitude - coordinate.longitude) < threshold
    }
    if !isAlreadyVisited {
      let newSpot = VisitedLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
      do {
        context.insert(newSpot)
        try context.save()
      } catch {
        print("Error saving new visited location: \(error)")
      }
    }
  }
}
