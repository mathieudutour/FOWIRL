import Foundation
import SwiftData

/// A simple SwiftData model storing latitude and longitude.
@Model
class VisitedLocation {
  @Attribute(.unique) var id: UUID
  var latitude: Double
  var longitude: Double

  init(latitude: Double, longitude: Double) {
    self.id = UUID()
    self.latitude = latitude
    self.longitude = longitude
  }
}
