import MapKit
import SwiftUI

/// A simple overlay that covers the entire world for the heat map.
final class HeatMapOverlay: NSObject, MKOverlay {
  // Apple Maps requires a coordinate for the overlay.
  var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)

  // boundingMapRect covers the entire Earth.
  var boundingMapRect: MKMapRect = MKMapRect.world
}

/// The custom renderer draws heat spots based on visit frequency using a logarithmic scale.
final class HeatMapOverlayRenderer: MKOverlayRenderer {
  /// Thread-safe copy of location data
  private struct LocationData {
    let latitude: Double
    let longitude: Double
    let visits: Int

    init(from location: VisitedLocation) {
      self.latitude = location.latitude ?? 0
      self.longitude = location.longitude ?? 0
      self.visits = location.visits
    }
  }
  
  /// Thread-safe copy of the visited locations displayed as heat spots.
  private var visitedLocations: [LocationData]

  init(overlay: MKOverlay, visitedLocations: [VisitedLocation]) {
    self.visitedLocations = visitedLocations.compactMap { location in
      guard location.latitude != nil, location.longitude != nil else { return nil }
      return LocationData(from: location)
    }
    super.init(overlay: overlay)
  }

  override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
    guard ((overlay as? HeatMapOverlay) != nil) else { return }

    // Find min and max visits for logarithmic scaling
    let minVisits = visitedLocations.map { $0.visits }.min() ?? 1
    let maxVisits = visitedLocations.map { $0.visits }.max() ?? 1

    // Ensure we don't take log of 0 or negative numbers
    let safeMinVisits = max(1, minVisits)
    let safeMaxVisits = max(safeMinVisits + 1, maxVisits)

    // Calculate logarithmic range
    let logMinVisits = log(Double(safeMinVisits))
    let logMaxVisits = log(Double(safeMaxVisits))
    let logRange = logMaxVisits - logMinVisits

    // Sort locations by visit count (ascending) to draw most visited on top
    let sortedLocations = visitedLocations.sorted {
      ($0.visits) < ($1.visits)
    }

    // Draw each location with a color based on logarithmic visit frequency
    for location in sortedLocations {
      let mapPoint = MKMapPoint(CLLocationCoordinate2D(
        latitude: location.latitude,
        longitude: location.longitude))

      let point = rect(for: MKMapRect(origin: mapPoint, size: MKMapSize(width: 0, height: 0)))

      // Calculate normalized value using logarithmic scale
      let safeVisits = max(1, location.visits) // Ensure we don't take log of 0
      let logVisits = log(Double(safeVisits))

      // Normalize on logarithmic scale (0-1)
      let normalizedLogValue = logRange > 0 ? (logVisits - logMinVisits) / logRange : 0

      // Create a gradient color based on logarithmic visit frequency
      let color = heatMapColor(for: normalizedLogValue)

      // Set the fill color
      context.setFillColor(color.cgColor)

      let circlePath = UIBezierPath(ovalIn: point.insetBy(dx: -600, dy: -600))

      // Set alpha based on logarithmic visit frequency
      context.setAlpha(min(0.7, 0.3 + (normalizedLogValue * 0.4)))

      context.addPath(circlePath.cgPath)
      context.fillPath()
    }
  }

  // Helper function to generate a color based on normalized value (0-1)
  private func heatMapColor(for value: Double) -> UIColor {
    // Create a gradient from blue (cold) to red (hot)
    switch value {
    case 0.0..<0.25:
      // Blue to Cyan
      let t = value * 4
      return UIColor(
        red: 0,
        green: CGFloat(t),
        blue: 1.0,
        alpha: 1.0
      )
    case 0.25..<0.5:
      // Cyan to Green
      let t = (value - 0.25) * 4
      return UIColor(
        red: 0,
        green: 1.0,
        blue: CGFloat(1.0 - t),
        alpha: 1.0
      )
    case 0.5..<0.75:
      // Green to Yellow
      let t = (value - 0.5) * 4
      return UIColor(
        red: CGFloat(t),
        green: 1.0,
        blue: 0,
        alpha: 1.0
      )
    default:
      // Yellow to Red
      let t = (value - 0.75) * 4
      return UIColor(
        red: 1.0,
        green: CGFloat(1.0 - t),
        blue: 0,
        alpha: 1.0
      )
    }
  }
}


struct HeatMapLegendView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Heat Map")
        .font(.body)
        .padding(.bottom, 4)

      HStack(spacing: 0) {
        ForEach(0..<5) { i in
          Rectangle()
            .fill(legendColor(for: Double(i) / 4.0))
            .frame(height: 10)
        }
      }
      .frame(width: 150)
      .cornerRadius(5)

      HStack {
        Text("Less")
          .font(.caption)
        Spacer()
        Text("More")
          .font(.caption)
      }
      .frame(width: 150)
    }
    .padding()
    .background(Material.regularMaterial)
    .cornerRadius(10)
  }

  private func legendColor(for value: Double) -> Color {
    switch value {
    case 0.0..<0.25:
      // Blue to Cyan
      let t = value * 4
      return Color(red: 0, green: t, blue: 1.0)
    case 0.25..<0.5:
      // Cyan to Green
      let t = (value - 0.25) * 4
      return Color(red: 0, green: 1.0, blue: 1.0 - t)
    case 0.5..<0.75:
      // Green to Yellow
      let t = (value - 0.5) * 4
      return Color(red: t, green: 1.0, blue: 0)
    default:
      // Yellow to Red
      let t = (value - 0.75) * 4
      return Color(red: 1.0, green: 1.0 - t, blue: 0)
    }
  }
}
