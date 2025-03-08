import SwiftUI
import MapKit

struct AppleMapsView: UIViewRepresentable {
  /// Whether we're in debug mode (tapping the map manually adds visited locations)
  var debugMode: Bool

  /// The current map mode (fog of war or heat map)
  var mapMode: MapMode

  /// Closure called whenever the user taps the map (if debugMode == true)
  var onMapTap: (CLLocationCoordinate2D) -> Void

  /// Visited locations for the fog-of-war overlay
  var visitedLocations: [VisitedLocation]

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView(frame: .zero)
    mapView.showsUserLocation = true
    mapView.isRotateEnabled = true
    mapView.isPitchEnabled = false
    mapView.showsUserTrackingButton = true
    mapView.showsScale = true

    mapView.delegate = context.coordinator

    let config = MKStandardMapConfiguration(emphasisStyle: .muted)
    config.pointOfInterestFilter = .excludingAll
    mapView.preferredConfiguration = config
    mapView.userTrackingMode = .follow

    // Add the appropriate overlay based on the current mode
    addOverlay(to: mapView, mode: mapMode)

    // Add a tap gesture
    let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
    mapView.addGestureRecognizer(tapGesture)

    return mapView
  }

  func updateUIView(_ uiView: MKMapView, context: Context) {
    // Update the visitedLocations in our coordinator so the overlay renderer can use them
    context.coordinator.visitedLocations = visitedLocations
    context.coordinator.debugMode = debugMode
    context.coordinator.mapMode = mapMode

    // Remove existing overlays
    uiView.removeOverlays(uiView.overlays)

    // Add the appropriate overlay based on the current mode
    addOverlay(to: uiView, mode: mapMode)
  }

  private func addOverlay(to mapView: MKMapView, mode: MapMode) {
    switch mode {
    case .fogOfWar:
      mapView.addOverlay(FogOverlay(), level: .aboveLabels)
    case .heatMap:
      mapView.addOverlay(HeatMapOverlay(), level: .aboveLabels)
    }
  }

  class Coordinator: NSObject, MKMapViewDelegate {
    var parent: AppleMapsView
    var visitedLocations: [VisitedLocation] = []
    var debugMode: Bool
    var mapMode: MapMode = .fogOfWar
    let onMapTap: (CLLocationCoordinate2D) -> Void

    init(_ parent: AppleMapsView) {
      self.parent = parent
      self.debugMode = parent.debugMode
      self.onMapTap = parent.onMapTap
      self.mapMode = parent.mapMode
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if let fogOverlay = overlay as? FogOverlay {
        return FogOverlayRenderer(overlay: fogOverlay, visitedLocations: visitedLocations)
      } else if let heatMapOverlay = overlay as? HeatMapOverlay {
        return HeatMapOverlayRenderer(overlay: heatMapOverlay, visitedLocations: visitedLocations)
      }
      return MKOverlayRenderer(overlay: overlay)
    }

    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
      guard debugMode else { return } // Only handle taps in debug mode

      let mapView = gesture.view as! MKMapView
      let tapPoint = gesture.location(in: mapView)
      let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)

      // Inform the parent
      onMapTap(coordinate)
    }
  }
}
