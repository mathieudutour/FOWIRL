import Foundation
import CoreLocation
import SwiftUI

/// A delegate class managing the user's GPS location and notifying SwiftUI.
class LocationManager: NSObject, ObservableObject {
  private let locationManager = CLLocationManager()

  override init() {
    super.init()

    // Configure LocationManager
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = 10
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.showsBackgroundLocationIndicator = false
    locationManager.pausesLocationUpdatesAutomatically = false
    locationManager.activityType = .otherNavigation
    locationManager.delegate = self

    // Request authorization
    locationManager.requestAlwaysAuthorization()

    // Start updating location
    locationManager.startUpdatingLocation()
  }

  // Add a method to restart location updates if needed
  func restartLocationUpdates() {
    locationManager.stopUpdatingLocation()
    locationManager.startUpdatingLocation()
  }

  func setAccuracyMode(_ mode: LocationAccuracyMode) {
    locationManager.desiredAccuracy = mode.desiredAccuracy
    locationManager.distanceFilter = mode.distanceFilter
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
    guard let location = locations.last, location.horizontalAccuracy >= 0, location.horizontalAccuracy < 50 else { return }

    // Process the location update in the data manager
    // This happens independently of the SwiftUI view lifecycle
    LocationDataManager.shared.processLocationUpdate(location.coordinate)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location manager failed with error: \(error.localizedDescription)")

    // If we get a location-unknown error, restart after a delay
    if let error = error as? CLError, error.code == .locationUnknown {
      DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        self.restartLocationUpdates()
      }
    }
  }
}

enum LocationAccuracyMode {
  case high    // For when the app is in foreground
  case medium  // For typical background use
  case low     // For battery saving

  var desiredAccuracy: CLLocationAccuracy {
    switch self {
    case .high: return kCLLocationAccuracyBest
    case .medium: return kCLLocationAccuracyNearestTenMeters
    case .low: return kCLLocationAccuracyHundredMeters
    }
  }

  var distanceFilter: CLLocationDistance {
    switch self {
    case .high: return 10
    case .medium: return 20
    case .low: return 50
    }
  }
}

