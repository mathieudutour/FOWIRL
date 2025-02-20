import Foundation
import CoreLocation

struct MapHelper {
    
    static func distanceBetween(_ start: CLLocationCoordinate2D, _ end: CLLocationCoordinate2D) -> CLLocationDistance {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation)
    }
    
    static func coordinatesToString(_ coordinates: CLLocationCoordinate2D) -> String {
        return "Latitude: \(coordinates.latitude), Longitude: \(coordinates.longitude)"
    }
    
    static func isCoordinateWithinRegion(_ coordinate: CLLocationCoordinate2D, regionCenter: CLLocationCoordinate2D, radius: CLLocationDistance) -> Bool {
        let distance = distanceBetween(coordinate, regionCenter)
        return distance <= radius
    }
}