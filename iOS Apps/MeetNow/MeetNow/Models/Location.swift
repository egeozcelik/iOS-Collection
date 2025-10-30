//
//  Location.swift
//  MeetNow
//  Enhanced version with privacy support
//

import SwiftUI
import CoreLocation

struct Location: Equatable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String
    let isHidden: Bool
    
    init(id: String, name: String, latitude: Double, longitude: Double, address: String, isHidden: Bool = false) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.isHidden = isHidden
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.id == rhs.id &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.isHidden == rhs.isHidden
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var coreLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    var displayName: String {
        if isHidden {
            return "Konum belirtilmemiş"
        }
        return name
    }
    
    var displayAddress: String {
        if isHidden {
            return "Gizli konum"
        }
        return address
    }
    
    func distance(from userLocation: CLLocation) -> Double {
        return userLocation.distance(from: coreLocation)
    }
    
    func formattedDistance(from userLocation: CLLocation) -> String {
        let distance = distance(from: userLocation)
        
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    func estimatedWalkingTime(from userLocation: CLLocation) -> String {
        let distanceInMeters = distance(from: userLocation)
        
        // Average walking speed: 5 km/h = 1.39 m/s
        let walkingTimeInSeconds = distanceInMeters / 1.39
        let walkingTimeInMinutes = Int(walkingTimeInSeconds / 60)
        
        if walkingTimeInMinutes < 1 {
            return "1 dk"
        } else if walkingTimeInMinutes < 60 {
            return "\(walkingTimeInMinutes) dk"
        } else {
            let hours = walkingTimeInMinutes / 60
            let remainingMinutes = walkingTimeInMinutes % 60
            if remainingMinutes == 0 {
                return "\(hours) saat"
            } else {
                return "\(hours)s \(remainingMinutes)dk"
            }
        }
    }
    
    static let mockLocation = Location(
        id: "1",
        name: "Konak Meydanı",
        latitude: 38.4237,
        longitude: 27.1428,
        address: "Konak, İzmir",
        isHidden: false
    )
    
    static let hiddenLocation = Location(
        id: "2",
        name: "Gizli Konum",
        latitude: 38.4237,
        longitude: 27.1428,
        address: "Konum gizli",
        isHidden: true
    )
}
