//
//  EventManager.swift
//  MeetNow
//  Optimized and simplified event loading system
//
/*
import Foundation
import FirebaseFirestore
import CoreLocation
import Combine

class EventManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var allEvents: [EventModel] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var lastUpdateTime = Date()
    
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20
    @Published var hasMoreEvents = true
    @Published var isLoadingMore = false
    
    // MARK: - Dependencies
    private let db = Firestore.firestore()
    private let authManager: AuthenticationManager
    private let locationManager: LocationManager
    
    // MARK: - Loading Types
    enum LoadType {
        case initial    // App açılış + mevcut kullanıcı
        case refresh    // Pull-to-refresh
        case pagination // Scroll pagination
    }
    
    init(authManager: AuthenticationManager, locationManager: LocationManager) {
        self.authManager = authManager
        self.locationManager = locationManager
    }
    
    
    func loadEvents(type: LoadType = .initial) {
        
        guard !isCurrentlyLoading() else {
            return
        }
        
        if type == .initial || type == .refresh {
            resetPagination()
        }
        
        setLoadingState(for: type, loading: true)
        refreshLocationThenFetch(type: type)
    }
    
    
    private func refreshLocationThenFetch(type: LoadType) {
        
        DispatchQueue.main.async {
            self.locationManager.getCurrentLocationOnce()  // ✅ Main thread'den çağır
        }
        
        var attempts = 0
        let maxAttempts = 10
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            attempts += 1
            
            if self.locationManager.hasValidLocation {
                timer.invalidate()
                self.fetchEventsFromDB(type: type)
                
            } else if attempts >= maxAttempts {
                timer.invalidate()
                
                if self.locationManager.currentLocation != nil {
                    self.fetchEventsFromDB(type: type)
                } else {
                    self.handleLocationError(type: type)
                }
            }
        }
    }
    
    
    private func fetchEventsFromDB(type: LoadType) {
        guard let userLocation = locationManager.currentLocation else {
            handleLocationError(type: type)
            return
        }
        print("📍 Fetching events with location:")
        print("   Lat: \(userLocation.coordinate.latitude)")
        print("   Lng: \(userLocation.coordinate.longitude)")
        print("   Type: \(type)")
        self.setLoadingState(for: type, loading: false)

        
    }
    
    private func isCurrentlyLoading() -> Bool {
        return isLoading || isLoadingMore
    }
    
    private func setLoadingState(for type: LoadType, loading: Bool) {
        DispatchQueue.main.async {
            switch type {
            case .initial, .refresh:
                self.isLoading = loading
            case .pagination:
                self.isLoadingMore = loading
            }
            
            if !loading {
                self.errorMessage = ""
            }
        }
    }
    
    private func resetPagination() {
        lastDocument = nil
        DispatchQueue.main.async {
            self.hasMoreEvents = true
        }
        
        if isLoading {
            allEvents = []
        }
    }
    
    private func handleLocationError(type: LoadType) {
        DispatchQueue.main.async {
            self.setLoadingState(for: type, loading: false)
            self.errorMessage = "Konum bilgisi alınamadı"
            print("❌ Location error - cannot fetch events")
        }
    }
    
    
    private func generateMockEvents(for type: LoadType, near location: CLLocation) -> [EventModel] {
        return []
    }
    
    
    func loadInitialEvents() {
        loadEvents(type: .initial)
    }
    
    func refreshEvents() {
        loadEvents(type: .refresh)
    }
    
    func loadMoreEventsIfNeeded(currentEvent: EventModel?) {
        guard let currentEvent = currentEvent,
              hasMoreEvents,
              !isLoadingMore else { return }
        
        let thresholdIndex = allEvents.index(allEvents.endIndex, offsetBy: -5)
        if let eventIndex = allEvents.firstIndex(where: { $0.id == currentEvent.id }),
           eventIndex >= thresholdIndex {
            loadEvents(type: .pagination)
        }
    }
    
    
    func refreshAfterEventCreation() {
        print("🎉 Event created - refreshing list")
        loadEvents(type: .refresh)
    }
    
    @Published var isCreating = false
    
    func createEvent(
        title: String,
        description: String,
        icon: EventIcon,
        timeType: TimeType,
        selectedTime: Date,
        selectedDateTime: Date,
        useCurrentLocation: Bool,
        selectedLocation: Location?,
        maxParticipants: Int,
        isLocationHidden: Bool = false
    ) {
        guard let currentUser = authManager.currentUser else {
            errorMessage = "Kullanıcı girişi gerekli"
            return
        }
        
        guard let userLocation = locationManager.currentLocation else {
            errorMessage = "Konum bilgisi bulunamadı"
            return
        }
        
        isCreating = true
        errorMessage = ""
        
        print("🎉 Creating event: \(title)")
        
        let eventData = prepareEventData(
            title: title,
            description: description,
            icon: icon,
            timeType: timeType,
            selectedTime: selectedTime,
            selectedDateTime: selectedDateTime,
            useCurrentLocation: useCurrentLocation,
            selectedLocation: selectedLocation,
            maxParticipants: maxParticipants,
            organizerId: currentUser.id,
            userLocation: userLocation,
            isLocationHidden: isLocationHidden
        )
        
        // Create event in Firestore
        db.collection("events").addDocument(data: eventData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isCreating = false
                
                if let error = error {
                    self?.errorMessage = "Etkinlik oluşturulamadı: \(error.localizedDescription)"
                    print("❌ Event creation error: \(error.localizedDescription)")
                    return
                }
                
                print("✅ Event created successfully!")
                
                // Auto refresh to show new event
                self?.refreshAfterEventCreation()
            }
        }
    }
    
    
    private func prepareEventData(
        title: String,
        description: String,
        icon: EventIcon,
        timeType: TimeType,
        selectedTime: Date,
        selectedDateTime: Date,
        useCurrentLocation: Bool,
        selectedLocation: Location?,
        maxParticipants: Int,
        organizerId: String,
        userLocation: CLLocation,
        isLocationHidden: Bool
    ) -> [String: Any] {
        
        let eventDateTime: Date
        switch timeType {
        case .immediate: eventDateTime = Date()
        case .flexible: eventDateTime = Calendar.current.startOfDay(for: Date())
        case .afterTime(_): eventDateTime = selectedTime
        case .specificTime: eventDateTime = selectedDateTime
        }
        
        let calendar = Calendar.current
        let eventDay = calendar.startOfDay(for: eventDateTime)
        let expiresAt = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: eventDay) ?? eventDateTime
        
        let geoPoint: GeoPoint
        let locationData: [String: Any]
        
        if useCurrentLocation || isLocationHidden {
            geoPoint = GeoPoint(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
            
            if isLocationHidden {
                locationData = [
                    "name": "Konum belirtilmemiş",
                    "geoPoint": geoPoint,
                    "address": "Gizli konum",
                    "isHidden": true
                ]
            } else {
                locationData = [
                    "name": "Mevcut Konum",
                    "geoPoint": geoPoint,
                    "address": "Kullanıcı konumu",
                    "isHidden": false
                ]
            }
        } else if let location = selectedLocation {
            geoPoint = GeoPoint(latitude: location.latitude, longitude: location.longitude)
            locationData = [
                "name": location.name,
                "geoPoint": geoPoint,
                "address": location.address,
                "isHidden": false
            ]
        } else {
            geoPoint = GeoPoint(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
            locationData = [
                "name": "Varsayılan Konum",
                "geoPoint": geoPoint,
                "address": "",
                "isHidden": false
            ]
        }
        
        let geohash = GeohashHelper.encode(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        
        let timeTypeString: String
        switch timeType {
        case .immediate: timeTypeString = "immediate"
        case .flexible: timeTypeString = "flexible"
        case .afterTime(let time): timeTypeString = "afterTime_\(time)"
        case .specificTime: timeTypeString = "specificTime"
        }
        
        var eventData: [String: Any] = [
            "title": title,
            "description": description,
            "icon": icon.rawValue,
            "organizerId": organizerId,
            "location": locationData,
            "geohash": geohash,
            "dateTime": Timestamp(date: eventDateTime),
            "timeType": timeTypeString,
            "maxParticipants": maxParticipants,
            "isActive": true,
            "createdAt": Timestamp(),
            "expiresAt": Timestamp(date: expiresAt),
            "attendeeCount": 1
        ]
        
        if maxParticipants > 0 && maxParticipants <= 10 {
            eventData["participants"] = [organizerId]
        } else {
            eventData["participants"] = []
        }
        
        return eventData
    }
}

struct GeohashHelper {
    static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")
    
    static func encode(latitude: Double, longitude: Double, precision: Int = 9) -> String {
        var latInterval: (Double, Double) = (-90.0, 90.0)
        var lonInterval: (Double, Double) = (-180.0, 180.0)
        var geohash = ""
        var isEven = true
        var bit = 0
        var ch = 0
        
        while geohash.count < precision {
            let mid: Double
            if isEven {
                mid = (lonInterval.0 + lonInterval.1) / 2
                if longitude > mid {
                    ch |= (1 << (4 - bit))
                    lonInterval.0 = mid
                } else {
                    lonInterval.1 = mid
                }
            } else {
                mid = (latInterval.0 + latInterval.1) / 2
                if latitude > mid {
                    ch |= (1 << (4 - bit))
                    latInterval.0 = mid
                } else {
                    latInterval.1 = mid
                }
            }
            
            isEven.toggle()
            
            if bit < 4 {
                bit += 1
            } else {
                geohash.append(base32[ch])
                bit = 0
                ch = 0
            }
        }
        
        return geohash
    }
}
*/
import Foundation
import FirebaseFirestore
import CoreLocation
import Combine

class EventManager: ObservableObject {
    
    @Published var allEvents: [EventModel] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20
    @Published var hasMoreEvents = true
    @Published var isLoadingMore = false
    @Published var isCreating = false
    
    private let db = Firestore.firestore()
    private let authManager: AuthenticationManager
    private let locationManager: LocationManager
    private var appStateManager: AppStateManager?
    
    private var cancellables = Set<AnyCancellable>()
    
    enum LoadType {
        case initial
        case refresh
        case pagination
    }
    
    init(authManager: AuthenticationManager, locationManager: LocationManager) {
        self.authManager = authManager
        self.locationManager = locationManager
        
        setupLocationSubscription()
    }
    
    func setAppStateManager(_ appStateManager: AppStateManager) {
        self.appStateManager = appStateManager
    }
    
    private func setupLocationSubscription() {
        locationManager.locationPublisher
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] location in
                print("📍 EventManager received location update: \(location.coordinate)")
                if self?.allEvents.isEmpty == true {
                    print("🔄 Loading initial events due to location update")
                    self?.loadEvents(type: .initial)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadEvents(type: LoadType = .initial) {
        guard !isCurrentlyLoading() else {
            return
        }
        
        guard locationManager.hasValidLocation else {
            handleLocationError(type: type)
            return
        }
        
        if type == .initial || type == .refresh {
            resetPagination()
        }
        
        setLoadingState(for: type, loading: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.fetchEventsFromDB(type: type)
        }
    }
    
    private func fetchEventsFromDB(type: LoadType) {
        guard let userLocation = locationManager.currentLocation else {
            handleLocationError(type: type)
            return
        }
        
        print("🔍 Fetching events with location:")
        print("   Lat: \(userLocation.coordinate.latitude)")
        print("   Lng: \(userLocation.coordinate.longitude)")
        print("   Type: \(type)")
        
        let mockEvents = generateMockEvents(for: type, near: userLocation)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.handleEventsResponse(mockEvents, type: type)
        }
    }
    
    private func handleEventsResponse(_ events: [EventModel], type: LoadType) {
        DispatchQueue.main.async {
            switch type {
            case .initial, .refresh:
                self.allEvents = events
                
            case .pagination:
                self.allEvents.append(contentsOf: events)
            }
            
            self.hasMoreEvents = events.count == self.pageSize
            self.setLoadingState(for: type, loading: false)
            
            print("✅ Events loaded: \(events.count), Total: \(self.allEvents.count)")
            
            if type == .initial && !events.isEmpty {
                print("🎯 Notifying AppStateManager: events loaded")
                self.appStateManager?.eventsDidLoad()
            }
        }
    }
    
    private func generateMockEvents(for type: LoadType, near location: CLLocation) -> [EventModel] {
        let eventCount = type == .pagination ? min(pageSize, 8) : min(pageSize, 15)
        let startIndex = type == .pagination ? allEvents.count : 0
        
        return (0..<eventCount).compactMap { index in
            let actualIndex = startIndex + index
            
            let icons = EventIcon.allCases
            let titles = [
                "Coffee & Chat", "Morning Run", "Movie Night", "Study Session",
                "Gaming Tournament", "Art Gallery Visit", "Food Tasting", "Book Club",
                "Hiking Adventure", "Photography Walk", "Music Jam", "Cooking Class",
                "Beach Volleyball", "Yoga Session", "Tech Meetup", "Dance Class"
            ]
            
            let descriptions = [
                "Join us for a relaxing coffee and great conversation",
                "Early morning run through the beautiful park trails",
                "Watch the latest blockbuster with fellow movie enthusiasts",
                "Focused study session with motivated students",
                "Compete in friendly gaming matches",
                "Explore contemporary art exhibitions together",
                "Discover local flavors and cuisines",
                "Discuss this month's book selection"
            ]
            
            let timeTypes: [TimeType] = [.immediate, .flexible, .afterTime("19:00"), .specificTime]
            
            let latOffset = Double.random(in: -0.01...0.01)
            let lonOffset = Double.random(in: -0.01...0.01)
            
            let eventLocation = Location(
                id: "loc_\(actualIndex)",
                name: "Location \(actualIndex + 1)",
                latitude: location.coordinate.latitude + latOffset,
                longitude: location.coordinate.longitude + lonOffset,
                address: "Address \(actualIndex + 1), Izmir"
            )
            
            return EventModel(
                id: "event_\(actualIndex)",
                title: titles[actualIndex % titles.count],
                description: descriptions[actualIndex % descriptions.count],
                icon: icons[actualIndex % icons.count].rawValue,
                organizer: User.mockUser,
                location: eventLocation,
                dateTime: Date().addingTimeInterval(Double.random(in: 0...7200)),
                timeType: timeTypes[actualIndex % timeTypes.count],
                currentParticipants: Int.random(in: 1...8),
                maxParticipants: Int.random(in: 4...12),
                isActive: true
            )
        }
    }
    
    private func isCurrentlyLoading() -> Bool {
        return isLoading || isLoadingMore
    }
    
    private func setLoadingState(for type: LoadType, loading: Bool) {
        DispatchQueue.main.async {
            switch type {
            case .initial, .refresh:
                self.isLoading = loading
            case .pagination:
                self.isLoadingMore = loading
            }
            
            if !loading {
                self.errorMessage = ""
            }
        }
    }
    
    private func resetPagination() {
        lastDocument = nil
        DispatchQueue.main.async {
            self.hasMoreEvents = true
        }
        
        if isLoading {
            allEvents = []
        }
    }
    
    private func handleLocationError(type: LoadType) {
        DispatchQueue.main.async {
            self.setLoadingState(for: type, loading: false)
            self.errorMessage = "Location information unavailable"
            print("❌ Location error - cannot fetch events")
            
            self.appStateManager?.setError(.locationError(.locationUnavailable))
        }
    }
    
    func loadInitialEvents() {
        loadEvents(type: .initial)
    }
    
    func refreshEvents() {
        loadEvents(type: .refresh)
    }
    
    func loadMoreEventsIfNeeded(currentEvent: EventModel?) {
        guard let currentEvent = currentEvent,
              hasMoreEvents,
              !isLoadingMore else { return }
        
        let thresholdIndex = allEvents.index(allEvents.endIndex, offsetBy: -5)
        if let eventIndex = allEvents.firstIndex(where: { $0.id == currentEvent.id }),
           eventIndex >= thresholdIndex {
            loadEvents(type: .pagination)
        }
    }
    
    func refreshAfterEventCreation() {
        print("🎉 Event created - refreshing list")
        loadEvents(type: .refresh)
    }
    
    func createEvent(
        title: String,
        description: String,
        icon: EventIcon,
        timeType: TimeType,
        selectedTime: Date,
        selectedDateTime: Date,
        useCurrentLocation: Bool,
        selectedLocation: Location?,
        maxParticipants: Int,
        isLocationHidden: Bool = false
    ) {
        guard let currentUser = authManager.currentUser else {
            DispatchQueue.main.async {
                self.appStateManager?.setError(.authError("User login required"))
            }
            return
        }
        
        guard let userLocation = locationManager.currentLocation else {
            DispatchQueue.main.async {
                self.appStateManager?.setError(.locationError(.locationUnavailable))
            }
            return
        }
        
        isCreating = true
        errorMessage = ""
        
        print("🎉 Creating event: \(title)")
        
        let eventData = prepareEventData(
            title: title,
            description: description,
            icon: icon,
            timeType: timeType,
            selectedTime: selectedTime,
            selectedDateTime: selectedDateTime,
            useCurrentLocation: useCurrentLocation,
            selectedLocation: selectedLocation,
            maxParticipants: maxParticipants,
            organizerId: currentUser.id,
            userLocation: userLocation,
            isLocationHidden: isLocationHidden
        )
        
        db.collection("events").addDocument(data: eventData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isCreating = false
                
                if let error = error {
                    self?.appStateManager?.setError(.generalError("Event could not be created: \(error.localizedDescription)"))
                    print("❌ Event creation error: \(error.localizedDescription)")
                    return
                }
                
                print("✅ Event created successfully!")
                self?.refreshAfterEventCreation()
            }
        }
    }
    
    private func prepareEventData(
        title: String,
        description: String,
        icon: EventIcon,
        timeType: TimeType,
        selectedTime: Date,
        selectedDateTime: Date,
        useCurrentLocation: Bool,
        selectedLocation: Location?,
        maxParticipants: Int,
        organizerId: String,
        userLocation: CLLocation,
        isLocationHidden: Bool
    ) -> [String: Any] {
        
        let eventDateTime: Date
        switch timeType {
        case .immediate: eventDateTime = Date()
        case .flexible: eventDateTime = Calendar.current.startOfDay(for: Date())
        case .afterTime(_): eventDateTime = selectedTime
        case .specificTime: eventDateTime = selectedDateTime
        }
        
        let calendar = Calendar.current
        let eventDay = calendar.startOfDay(for: eventDateTime)
        let expiresAt = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: eventDay) ?? eventDateTime
        
        let geoPoint: GeoPoint
        let locationData: [String: Any]
        
        if useCurrentLocation || isLocationHidden {
            geoPoint = GeoPoint(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
            
            if isLocationHidden {
                locationData = [
                    "name": "Location not specified",
                    "geoPoint": geoPoint,
                    "address": "Hidden location",
                    "isHidden": true
                ]
            } else {
                locationData = [
                    "name": "Current Location",
                    "geoPoint": geoPoint,
                    "address": "User location",
                    "isHidden": false
                ]
            }
        } else if let location = selectedLocation {
            geoPoint = GeoPoint(latitude: location.latitude, longitude: location.longitude)
            locationData = [
                "name": location.name,
                "geoPoint": geoPoint,
                "address": location.address,
                "isHidden": false
            ]
        } else {
            geoPoint = GeoPoint(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
            locationData = [
                "name": "Default Location",
                "geoPoint": geoPoint,
                "address": "",
                "isHidden": false
            ]
        }
        
        let geohash = GeohashHelper.encode(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        
        let timeTypeString: String
        switch timeType {
        case .immediate: timeTypeString = "immediate"
        case .flexible: timeTypeString = "flexible"
        case .afterTime(let time): timeTypeString = "afterTime_\(time)"
        case .specificTime: timeTypeString = "specificTime"
        }
        
        var eventData: [String: Any] = [
            "title": title,
            "description": description,
            "icon": icon.rawValue,
            "organizerId": organizerId,
            "location": locationData,
            "geohash": geohash,
            "dateTime": Timestamp(date: eventDateTime),
            "timeType": timeTypeString,
            "maxParticipants": maxParticipants,
            "isActive": true,
            "createdAt": Timestamp(),
            "expiresAt": Timestamp(date: expiresAt),
            "attendeeCount": 1
        ]
        
        if maxParticipants > 0 && maxParticipants <= 10 {
            eventData["participants"] = [organizerId]
        } else {
            eventData["participants"] = []
        }
        
        return eventData
    }
}

struct GeohashHelper {
    static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")
    
    static func encode(latitude: Double, longitude: Double, precision: Int = 9) -> String {
        var latInterval: (Double, Double) = (-90.0, 90.0)
        var lonInterval: (Double, Double) = (-180.0, 180.0)
        var geohash = ""
        var isEven = true
        var bit = 0
        var ch = 0
        
        while geohash.count < precision {
            let mid: Double
            if isEven {
                mid = (lonInterval.0 + lonInterval.1) / 2
                if longitude > mid {
                    ch |= (1 << (4 - bit))
                    lonInterval.0 = mid
                } else {
                    lonInterval.1 = mid
                }
            } else {
                mid = (latInterval.0 + latInterval.1) / 2
                if latitude > mid {
                    ch |= (1 << (4 - bit))
                    latInterval.0 = mid
                } else {
                    latInterval.1 = mid
                }
            }
            
            isEven.toggle()
            
            if bit < 4 {
                bit += 1
            } else {
                geohash.append(base32[ch])
                bit = 0
                ch = 0
            }
        }
        
        return geohash
    }
}
