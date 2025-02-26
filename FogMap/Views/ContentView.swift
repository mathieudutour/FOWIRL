import SwiftUI
import BottomSheet
import MapKit
import SwiftData

struct ContentView: View {
  private var debugMode = false
  @StateObject private var locationManager = LocationManager()

  // Fetch all visited locations from SwiftData
  @Query(filter: Self.predicate()) private var visitedLocations: [VisitedLocation]

  // Access SwiftData’s ModelContext for creating new records
  @Environment(\.modelContext) private var context

  @State var bottomSheetPosition: BottomSheetPosition = .relative(0.125)

  // Example coverage percentage
  @State private var coveragePercentage: Double = 0.0

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
    .bottomSheet(bottomSheetPosition: self.$bottomSheetPosition, switchablePositions: [
      .relative(0.125),
      .relativeTop(0.975)
    ], title: "Your Stats") {
      StatsView(
        visitedLocations: visitedLocations
      )
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

    let alreadyVisited = visitedLocations.first(where: { visited in
      guard let latitude = visited.latitude, let longitude = visited.longitude else { return false }
      return abs(latitude - coordinate.latitude) < threshold &&
      abs(longitude - coordinate.longitude) < threshold
    })
    if let alreadyVisited {
      alreadyVisited.visit()
    } else {
      let newSpot = VisitedLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
      context.insert(newSpot)
    }
    do {
      try context.save()
    } catch {
      print("Error saving visited location: \(error)")
    }
  }

  static func predicate() -> Predicate<VisitedLocation> {
    return #Predicate<VisitedLocation> { location in
      location.latitude != nil && location.longitude != nil
    }
  }
}
