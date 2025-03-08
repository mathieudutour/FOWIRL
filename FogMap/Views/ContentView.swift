import SwiftUI
import MapKit
import SwiftData

enum MapMode {
  case fogOfWar
  case heatMap
}

struct ContentView: View {
  private var debugMode = false

  @StateObject private var locationManager = LocationManager()

  // Fetch all visited locations from SwiftData
  @Query(filter: Self.predicate()) private var visitedLocations: [VisitedLocation]

  // Access SwiftData’s ModelContext for creating new records
  @Environment(\.modelContext) private var context

  // State to control sheet presentation
  @State private var isShowingStats = false

  // State to control map mode
  @State private var mapMode: MapMode = .fogOfWar

  var body: some View {
    ZStack {
      AppleMapsView(
        debugMode: debugMode,
        mapMode: mapMode,
        onMapTap: { coordinate in
          LocationDataManager.shared.processLocationUpdate(coordinate)
        },
        visitedLocations: visitedLocations
      )
      .edgesIgnoringSafeArea(.all)

      // 2. Stats Button (positioned at the bottom)
      HStack {
        Spacer()
        VStack {
          Spacer()
          Button {
            switch mapMode {
            case .fogOfWar:
              mapMode = .heatMap
            case .heatMap:
              mapMode = .fogOfWar
            }
          } label: {
            Image(systemName: mapMode == .fogOfWar ? "cloud.fog" : "flame")
              .padding(16)
          }
          .frame(width: 44, height: 44)
          .background(Material.regularMaterial)
          .cornerRadius(10)
          .shadow(radius: 3)

          Button {
            isShowingStats = true
          } label: {
            Image(systemName: "chart.bar.xaxis.ascending")
              .padding(16)
          }
          .frame(width: 44, height: 44)
          .background(Material.regularMaterial)
          .cornerRadius(10)
          .shadow(radius: 3)
        }
        .padding(8)
      }

      if mapMode == .heatMap {
        VStack {
          Spacer()
          HStack {
            HeatMapLegendView()
              .padding(8)
            Spacer()
          }
        }
      }
    }
    .sheet(isPresented: $isShowingStats) {
      NavigationStack {
        StatsView(visitedLocations: visitedLocations)
          .navigationTitle("Your Stats")
          .navigationBarTitleDisplayMode(.large)
      }
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
    }
    // Add to ContentView
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
      // App moving to background
      locationManager.setAccuracyMode(.medium)
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
      // App moving to foreground
      locationManager.setAccuracyMode(.high)
    }
  }

  static func predicate() -> Predicate<VisitedLocation> {
    return #Predicate<VisitedLocation> { location in
      location.latitude != nil && location.longitude != nil
    }
  }
}
