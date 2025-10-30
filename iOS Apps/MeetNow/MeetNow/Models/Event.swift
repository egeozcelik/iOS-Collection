//
//  Event.swift
//  MeetNow
//  Enhanced version with location hidden support and better distance calculation
//

import SwiftUI
import CoreLocation

struct EventModel: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let organizer: User
    let location: Location
    let dateTime: Date
    let timeType: TimeType
    let currentParticipants: Int
    let maxParticipants: Int
    let isActive: Bool
    let isLocationHidden: Bool
    
    init(id: String, title: String, description: String, icon: String, organizer: User, location: Location, dateTime: Date, timeType: TimeType, currentParticipants: Int, maxParticipants: Int, isActive: Bool, isLocationHidden: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.organizer = organizer
        self.location = location
        self.dateTime = dateTime
        self.timeType = timeType
        self.currentParticipants = currentParticipants
        self.maxParticipants = maxParticipants
        self.isActive = isActive
        self.isLocationHidden = isLocationHidden
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: EventModel, rhs: EventModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.currentParticipants == rhs.currentParticipants &&
               lhs.maxParticipants == rhs.maxParticipants &&
               lhs.isActive == rhs.isActive
    }
    
    var timeText: String {
        switch timeType {
        case .immediate:
            return "Şimdi"
        case .flexible:
            return "Bugün"
        case .afterTime(let time):
            return "Saat \(time) sonrası"
        case .specificTime:
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return formatter.string(from: dateTime)
        }
    }
    
    func distanceText(from userLocation: CLLocation?) -> String {
        guard let userLocation = userLocation else { return "? km" }
        
        let eventLocation = CLLocation(
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        let distanceInMeters = userLocation.distance(from: eventLocation)
        
        if distanceInMeters < 1000 {
            return String(format: "%.0f m uzakta", distanceInMeters)
        } else {
            return String(format: "%.1f km uzakta", distanceInMeters / 1000)
        }
    }
    
    func walkingTimeText(from userLocation: CLLocation?) -> String {
        guard let userLocation = userLocation else { return "? dk" }
        
        let eventLocation = CLLocation(
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        let distanceInMeters = userLocation.distance(from: eventLocation)
        
        // Average walking speed: 5 km/h = 1.39 m/s
        let walkingTimeInSeconds = distanceInMeters / 1.39
        let walkingTimeInMinutes = Int(walkingTimeInSeconds / 60)
        
        if walkingTimeInMinutes < 1 {
            return "1 dk yürüyüş"
        } else if walkingTimeInMinutes < 60 {
            return "\(walkingTimeInMinutes) dk yürüyüş"
        } else {
            let hours = walkingTimeInMinutes / 60
            let remainingMinutes = walkingTimeInMinutes % 60
            if remainingMinutes == 0 {
                return "\(hours) saat yürüyüş"
            } else {
                return "\(hours)s \(remainingMinutes)dk yürüyüş"
            }
        }
    }
    
    var participantStatusText: String {
        if maxParticipants == 0 {
            return "\(currentParticipants) kişi katılıyor"
        } else {
            return "\(currentParticipants)/\(maxParticipants) kişi"
        }
    }
    
    var isNearlyFull: Bool {
        guard maxParticipants > 0 else { return false }
        let fillRatio = Double(currentParticipants) / Double(maxParticipants)
        return fillRatio >= 0.8
    }
    
    var isFull: Bool {
        guard maxParticipants > 0 else { return false }
        return currentParticipants >= maxParticipants
    }
    
    var urgencyLevel: EventUrgency {
        switch timeType {
        case .immediate:
            return .immediate
        case .flexible:
            let now = Date()
            let endOfDay = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
            let timeRemaining = endOfDay.timeIntervalSince(now)
            
            if timeRemaining < 3600 { // 1 hour
                return .urgent
            } else if timeRemaining < 7200 { // 2 hours
                return .moderate
            } else {
                return .low
            }
        case .afterTime(_):
            let now = Date()
            let timeUntilStart = dateTime.timeIntervalSince(now)
            
            if timeUntilStart < 900 { // 15 minutes
                return .immediate
            } else if timeUntilStart < 3600 { // 1 hour
                return .urgent
            } else {
                return .moderate
            }
        case .specificTime:
            let now = Date()
            let timeUntilStart = dateTime.timeIntervalSince(now)
            
            if timeUntilStart < 1800 { // 30 minutes
                return .urgent
            } else if timeUntilStart < 7200 { // 2 hours
                return .moderate
            } else {
                return .low
            }
        }
    }
    
    static let mockEvent = EventModel(
        id: "1",
        title: "Kahve & Sohbet",
        description: "Birisiyle kahve içip güzel bir sohbet etmek istiyorum",
        icon: "cup.and.saucer.fill",
        organizer: User.mockUser,
        location: Location.mockLocation,
        dateTime: Date(),
        timeType: .immediate,
        currentParticipants: 2,
        maxParticipants: 4,
        isActive: true,
        isLocationHidden: false
    )
}

enum EventUrgency {
    case immediate
    case urgent
    case moderate
    case low
    
    var color: Color {
        switch self {
        case .immediate:
            return .red
        case .urgent:
            return .orange
        case .moderate:
            return .yellow
        case .low:
            return .green
        }
    }
    
    var text: String {
        switch self {
        case .immediate:
            return "ŞİMDİ"
        case .urgent:
            return "YAKINDA"
        case .moderate:
            return "BUGÜN"
        case .low:
            return "PLANLI"
        }
    }
}

enum TimeType: Equatable {
    case immediate
    case flexible
    case afterTime(String)
    case specificTime
}
