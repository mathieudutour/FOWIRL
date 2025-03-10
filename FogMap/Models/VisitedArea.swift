import Foundation
import SwiftData

/// A simple SwiftData model storing latitude and longitude.
@Model
final class VisitedLocation {
  var latitude: Double?
  var longitude: Double?
  var firstVisited: Date?
  var lastVisited: Date?
  var visits: Int = 1

  init(latitude: Double, longitude: Double) {
    self.latitude = latitude
    self.longitude = longitude
    self.firstVisited = Date()
    self.lastVisited = Date()
  }

  func visit() {
    visits += 1
    lastVisited = Date()
  }
}
