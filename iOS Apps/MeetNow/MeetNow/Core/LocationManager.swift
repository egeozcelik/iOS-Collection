import Foundation
import CoreLocation
import SwiftUI
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var isLocationEnabled = false
    @Published var locationError: String?
    @Published var isUpdatingLocation = false
    
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private let errorSubject = PassthroughSubject<LocationError, Never>()
    private let locationRequestSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var retryCount = 0
    private let maxRetries = 3
    private var locationTimeout: Timer?
    private let locationTimeoutDuration: TimeInterval = 15.0
    
    static let eventSearchRadius: Double = 50000
    
    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }
    
    var locationErrorPublisher: AnyPublisher<LocationError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    deinit {
        locationTimeout?.invalidate()
        cancellables.removeAll()
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 1000
        checkLocationAuthorization()
        
        setupLocationSubscription()
    }
    
    private func setupLocationSubscription() {
        locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.currentLocation = location
                self?.locationError = nil
            }
            .store(in: &cancellables)
        
        locationErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.locationError = error.localizedDescription
            }
            .store(in: &cancellables)
        
        locationRequestSubject
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.performLocationRequest()
            }
            .store(in: &cancellables)
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        case .authorizedWhenInUse, .authorizedAlways:
            getCurrentLocationOnce()
        @unknown default:
            break
        }
    }
    
    func getCurrentLocationOnce() {
        guard isLocationAuthorized else {
            errorSubject.send(.permissionDenied)
            return
        }
        
        guard !isUpdatingLocation else { return }
        
        locationRequestSubject.send(())
    }
    
    private func performLocationRequest() {
        guard isLocationAuthorized else { return }
        guard !isUpdatingLocation else { return }
        
        isUpdatingLocation = true
        retryCount = 0
        startLocationTimeout()
        locationManager.requestLocation()
    }
    
    private func startLocationTimeout() {
        locationTimeout?.invalidate()
        locationTimeout = Timer.scheduledTimer(withTimeInterval: locationTimeoutDuration, repeats: false) { [weak self] _ in
            self?.handleLocationTimeout()
        }
    }
    
    private func handleLocationTimeout() {
        guard isUpdatingLocation else { return }
        
        if retryCount < maxRetries {
            retryCount += 1
            let delay = Double(retryCount)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.locationManager.requestLocation()
                self.startLocationTimeout()
            }
        } else {
            DispatchQueue.main.async {
                self.isUpdatingLocation = false
                self.retryCount = 0
                self.locationTimeout?.invalidate()
            }
            errorSubject.send(.locationUnavailable)
        }
    }
    
    private func stopLocationRequest() {
        locationTimeout?.invalidate()
        isUpdatingLocation = false
        retryCount = 0
    }
    
    func startLocationUpdates() {
        guard isLocationAuthorized else { return }
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func isLocationWithinRadius(_ location: CLLocation, from center: CLLocation, radius: Double = LocationManager.eventSearchRadius) -> Bool {
        let distance = center.distance(from: location)
        return distance <= radius
    }
    
    func getCoordinateBounds(center: CLLocation, radius: Double = LocationManager.eventSearchRadius) -> (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        let radiusInDegrees = radius / 111000.0
        
        let minLat = center.coordinate.latitude - radiusInDegrees
        let maxLat = center.coordinate.latitude + radiusInDegrees
        
        let latRadians = center.coordinate.latitude * .pi / 180
        let lonRadiusInDegrees = radiusInDegrees / cos(latRadians)
        
        let minLon = center.coordinate.longitude - lonRadiusInDegrees
        let maxLon = center.coordinate.longitude + lonRadiusInDegrees
        
        return (minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
    }
    
    private func checkLocationAuthorization() {
        authorizationStatus = locationManager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationEnabled = true
            locationError = nil
        case .denied, .restricted:
            isLocationEnabled = false
            errorSubject.send(.permissionDenied)
        case .notDetermined:
            isLocationEnabled = false
            errorSubject.send(.permissionRequired)
        @unknown default:
            isLocationEnabled = false
            errorSubject.send(.unknown)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        if isLocationAccurate(location) {
            DispatchQueue.main.async {
                self.stopLocationRequest()
            }
            
            locationSubject.send(location)
        } else if retryCount < maxRetries {
            retryCount += 1
            let delay = Double(retryCount)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.locationManager.requestLocation()
                self.startLocationTimeout()
            }
        } else {
            DispatchQueue.main.async {
                self.stopLocationRequest()
            }
            
            locationSubject.send(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if retryCount < maxRetries {
            retryCount += 1
            let delay = Double(retryCount) * 2.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.locationManager.requestLocation()
                self.startLocationTimeout()
            }
            return
        }
        
        DispatchQueue.main.async {
            self.stopLocationRequest()
        }
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                errorSubject.send(.permissionDenied)
            case .network:
                errorSubject.send(.networkError)
            case .locationUnknown:
                errorSubject.send(.locationUnavailable)
            default:
                errorSubject.send(.general(error.localizedDescription))
            }
        } else {
            errorSubject.send(.general(error.localizedDescription))
        }
    }
    
    private func isLocationAccurate(_ location: CLLocation) -> Bool {
        let age = abs(location.timestamp.timeIntervalSinceNow)
        let accuracy = location.horizontalAccuracy
        
        return age < 30 && accuracy < 1000 && accuracy > 0
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            self.checkLocationAuthorization()
            
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.getCurrentLocationOnce()
            }
        }
    }
    
    var isLocationAuthorized: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    var hasValidLocation: Bool {
        return currentLocation != nil && isLocationAuthorized
    }
    
    var locationPermissionNeeded: Bool {
        return !isLocationAuthorized
    }
    
    var locationDisplayText: String {
        guard let location = currentLocation else {
            return "Location unavailable"
        }
        return String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude)
    }
    
    func distanceFromCurrentLocation(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: targetLocation)
    }
    
    func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

enum LocationError: LocalizedError {
    case permissionDenied
    case permissionRequired
    case locationUnavailable
    case networkError
    case unknown
    case general(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied"
        case .permissionRequired:
            return "Location permission required"
        case .locationUnavailable:
            return "Location unavailable"
        case .networkError:
            return "Network error"
        case .unknown:
            return "Unknown location error"
        case .general(let message):
            return message
        }
    }
}
