import SwiftUI
import MapKit

struct AppleMapsView: UIViewRepresentable {
  /// Whether we're in debug mode (tapping the map manually adds visited locations)
  var debugMode: Bool

  /// Closure called whenever the user taps the map (if debugMode == true)
  var onMapTap: (CLLocationCoordinate2D) -> Void

  /// Visited locations for the fog-of-war overlay
  var visitedLocations: [VisitedLocation]

  func makeCoordinator() -> Coordinator {
    Coordinator(self, debugMode: debugMode, onMapTap: onMapTap)
  }

  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView(frame: .zero)
    mapView.showsUserLocation = true
    mapView.isRotateEnabled = true
    mapView.isPitchEnabled = false
    mapView.showsUserTrackingButton = true
    mapView.delegate = context.coordinator

    let config = MKStandardMapConfiguration(emphasisStyle: .muted)
    config.pointOfInterestFilter = .excludingAll
    mapView.preferredConfiguration = config
    mapView.userTrackingMode = .follow

    // Set the region initially
//    mapView.setRegion(initialRegion, animated: false)

    // Add the custom fog overlay
    let fogOverlay = FogOverlay()
    mapView.addOverlay(fogOverlay, level: .aboveLabels)

    // Add a tap gesture
    let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
    mapView.addGestureRecognizer(tapGesture)

    return mapView
  }

  func updateUIView(_ uiView: MKMapView, context: Context) {
    // Update the visitedLocations in our coordinator so the overlay renderer can use them
    context.coordinator.visitedLocations = visitedLocations
    context.coordinator.debugMode = debugMode

    // Refresh the overlay so it includes new visited locations
    if let oldFog = uiView.overlays.first(where: { $0 is FogOverlay }) {
      uiView.removeOverlay(oldFog)
    }
    uiView.addOverlay(FogOverlay())
  }

  class Coordinator: NSObject, MKMapViewDelegate {
    var parent: AppleMapsView
    var visitedLocations: [VisitedLocation] = []
    var debugMode: Bool
    let onMapTap: (CLLocationCoordinate2D) -> Void

    init(_ parent: AppleMapsView, debugMode: Bool, onMapTap: @escaping (CLLocationCoordinate2D) -> Void) {
      self.parent = parent
      self.debugMode = debugMode
      self.onMapTap = onMapTap
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if let fogOverlay = overlay as? FogOverlay {
        return FogOverlayRenderer(overlay: fogOverlay, visitedLocations: visitedLocations)
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
