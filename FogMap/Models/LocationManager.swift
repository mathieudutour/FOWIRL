import Foundation
import CoreLocation
import SwiftUI

/// A delegate class managing the user's GPS location and notifying SwiftUI.
class LocationManager: NSObject, ObservableObject {
  private let locationManager = CLLocationManager()

  /// The user's current location, updated in real-time.
  @Published var currentLocation: CLLocation? = nil

  override init() {
    super.init()

    // Configure LocationManager
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = 10
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.showsBackgroundLocationIndicator = false
    locationManager.pausesLocationUpdatesAutomatically = false
    locationManager.delegate = self

    // Request authorization
    locationManager.requestAlwaysAuthorization()

    // Start updating location
    locationManager.startUpdatingLocation()
  }
}

extension LocationManager: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
      manager.startUpdatingLocation()
    default:
      // Handle unauthorized or restricted states
      manager.stopUpdatingLocation()
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    DispatchQueue.main.async {
      self.currentLocation = location
    }
  }
}
