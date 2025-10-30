import SwiftUI
import Combine
import CoreLocation

@MainActor
class AppStateManager: ObservableObject {
    
    @Published var currentStage: AppStage = .splash
    @Published var loadingState: LoadingState = .none
    @Published var errorState: ErrorState?
    
    private let authManager: AuthenticationManager
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private var eventManager: EventManager?
    private var stateTransitionQueue = DispatchQueue(label: "app.state.transition", qos: .userInitiated)
    private var pendingStage: AppStage?
    private var isTransitioning = false
    
    init(authManager: AuthenticationManager, locationManager: LocationManager) {
        self.authManager = authManager
        self.locationManager = locationManager
        
        setupStateSubscriptions()
    }
    
    func setEventManager(_ eventManager: EventManager) {
        self.eventManager = eventManager
        setupEventManagerSubscriptions()
    }
    
    func eventsDidLoad() {
        print("🎉 AppStateManager: Events loaded callback received")
        
        DispatchQueue.main.async {
            print("📍 Current stage when events loaded: \(self.currentStage)")
            
            // Hangi stage'de olursa olsun, events yüklendiyse main'e geç
            if !self.isTransitioning {
                print("🚀 Force transitioning to main stage from \(self.currentStage)")
                self.performStageTransition(to: .main)
            } else {
                print("⏳ Currently transitioning, setting pending stage to main")
                self.pendingStage = .main
            }
        }
    }
    
    private func setupStateSubscriptions() {
        authManager.$isLoggedIn
            .combineLatest(locationManager.$authorizationStatus)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] isLoggedIn, locationStatus in
                self?.evaluateAppStage(isLoggedIn: isLoggedIn, locationStatus: locationStatus)
            }
            .store(in: &cancellables)
        
        locationManager.locationErrorPublisher
            .sink { [weak self] error in
                self?.handleLocationError(error)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(
            authManager.$isLoading,
            authManager.$isSigningOut
        )
        .map { isLoading, isSigningOut in
            if isLoading { return LoadingState.auth }
            if isSigningOut { return LoadingState.signOut }
            return LoadingState.none
        }
        .sink { [weak self] authLoadingState in
            self?.updateLoadingState(authLoading: authLoadingState)
        }
        .store(in: &cancellables)
        
        locationManager.$isUpdatingLocation
            .map { $0 ? LoadingState.location : LoadingState.none }
            .sink { [weak self] locationLoadingState in
                self?.updateLoadingState(locationLoading: locationLoadingState)
            }
            .store(in: &cancellables)
    }
    
    private func setupEventManagerSubscriptions() {
        guard let eventManager = eventManager else { return }
        
        Publishers.CombineLatest(
            eventManager.$isLoading,
            eventManager.$isLoadingMore
        )
        .map { isLoading, isLoadingMore in
            //if isLoading { return LoadingState.events }
            if isLoadingMore { return LoadingState.eventsMore }
            return LoadingState.none
        }
        .sink { [weak self] eventLoadingState in
            self?.updateLoadingState(eventLoading: eventLoadingState)
        }
        .store(in: &cancellables)
        
        // 🆕 YENİ - Events yüklenince signal
        eventManager.$allEvents
            .combineLatest(eventManager.$isLoading)
            .sink { [weak self] events, isLoading in
                // Events yüklendi ve şu an loading events stage'indeyiz
                if !isLoading &&
                   !events.isEmpty &&
                   self?.currentStage == .loadingEvents {
                    print("🎉 Events loaded, transitioning to main")
                    self?.performStageTransition(to: .main)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateLoadingState(authLoading: LoadingState? = nil, locationLoading: LoadingState? = nil, eventLoading: LoadingState? = nil) {
        let activeStates = [authLoading, locationLoading, eventLoading].compactMap { $0 }
        let nonNoneStates = activeStates.filter { $0 != .none }
        
        loadingState = nonNoneStates.first ?? .none
    }
    
    var isLoading: Bool {
        return loadingState != .none
    }
    
    var loadingMessage: String {
        return loadingState.message
    }
    
    private func evaluateAppStage(isLoggedIn: Bool, locationStatus: CLAuthorizationStatus) {
        let newStage = determineStage(isLoggedIn: isLoggedIn, locationStatus: locationStatus)
        
        guard newStage != currentStage else { return }
        
        if isTransitioning {
            pendingStage = newStage
            return
        }
        
        performStageTransition(to: newStage)
    }
    
    private func performStageTransition(to newStage: AppStage) {
        guard !isTransitioning else { return }
        
        isTransitioning = true
        pendingStage = nil
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStage = newStage
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.handleStageTransition(to: newStage)
            
            self.isTransitioning = false
            
            if let pendingStage = self.pendingStage {
                self.performStageTransition(to: pendingStage)
            }
        }
    }
    
    private func determineStage(isLoggedIn: Bool, locationStatus: CLAuthorizationStatus) -> AppStage {
        if currentStage == .splash {
            return .splash
        }
        
        if !isLoggedIn {
            return .auth
        }
        
        if !locationStatus.isAuthorized {
            return .locationPermission
        }
        
        if !locationManager.hasValidLocation {
            return .loadingEvents
        }
        
        return .main
    }
    
    private func handleStageTransition(to stage: AppStage) {
        switch stage {
        case .splash:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard self.currentStage == .splash else { return }
                
                let nextStage = self.determineStage(
                    isLoggedIn: self.authManager.isLoggedIn,
                    locationStatus: self.locationManager.authorizationStatus
                )
                
                if nextStage != .splash {
                    self.performStageTransition(to: nextStage)
                }
            }
            
        case .auth:
            clearErrorState()
            
        case .locationPermission:
            clearErrorState()
            
        case .loadingEvents:
            startLocationAcquisition()
            
            // 🆕 Events zaten yüklenmişse direkt main'e geç
            if let eventManager = eventManager,
               !eventManager.allEvents.isEmpty {
                print("🎉 Events already loaded, going to main immediately")
                performStageTransition(to: .main)
            }
            
        case .main:
            clearErrorState()
            completeAppLaunch()
        }
    }
    
    private func completeAppLaunch() {
        DispatchQueue.main.async {
            self.loadingState = .none
        }
    }
    
    private func startLocationAcquisition() {
        guard !locationManager.hasValidLocation else {
            performStageTransition(to: .main)
            return
        }
        
        locationManager.getCurrentLocationOnce()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            guard self.currentStage == .loadingEvents && !self.locationManager.hasValidLocation else { return }
            
            self.setError(.locationTimeout)
        }
    }
    
    private func handleLocationError(_ error: LocationError) {
        switch currentStage {
        case .loadingEvents:
            setError(.locationError(error))
        default:
            break
        }
    }
    
    func setError(_ error: ErrorState) {
        errorState = error
    }
    
    func clearErrorState() {
        errorState = nil
    }
    
    func retryCurrentOperation() {
        clearErrorState()
        
        switch currentStage {
        case .loadingEvents:
            locationManager.getCurrentLocationOnce()
        case .locationPermission:
            locationManager.requestLocationPermission()
        default:
            break
        }
    }
    
    func forceStageTransition(to stage: AppStage) {
        performStageTransition(to: stage)
    }
    
    func canTransitionTo(_ stage: AppStage) -> Bool {
        switch stage {
        case .splash:
            return currentStage == .splash
        case .auth:
            return true
        case .locationPermission:
            return authManager.isLoggedIn
        case .loadingEvents:
            return authManager.isLoggedIn && locationManager.authorizationStatus.isAuthorized
        case .main:
            return authManager.isLoggedIn && locationManager.authorizationStatus.isAuthorized && locationManager.hasValidLocation
        }
    }
}

enum AppStage: CaseIterable {
    case splash
    case auth
    case locationPermission
    case loadingEvents
    case main
    
    var displayName: String {
        switch self {
        case .splash: return "Loading"
        case .auth: return "Authentication"
        case .locationPermission: return "Location Permission"
        case .loadingEvents: return "Loading Events"
        case .main: return "Main"
        }
    }
}

enum ErrorState {
    case locationError(LocationError)
    case locationTimeout
    case networkError
    case authError(String)
    case generalError(String)
    
    static func == (lhs: ErrorState, rhs: ErrorState) -> Bool {
        switch (lhs, rhs) {
        case (.locationError(let lhsError), .locationError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.locationTimeout, .locationTimeout),
             (.networkError, .networkError):
            return true
        case (.authError(let lhsMsg), .authError(let rhsMsg)),
             (.generalError(let lhsMsg), .generalError(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
    
    var title: String {
        switch self {
        case .locationError: return "Location Error"
        case .locationTimeout: return "Location Timeout"
        case .networkError: return "Network Error"
        case .authError: return "Authentication Error"
        case .generalError: return "Error"
        }
    }
    
    var message: String {
        switch self {
        case .locationError(let error): return error.localizedDescription
        case .locationTimeout: return "Unable to get your location. Please check your GPS settings."
        case .networkError: return "Please check your internet connection."
        case .authError(let message): return message
        case .generalError(let message): return message
        }
    }
    
    var canRetry: Bool {
        switch self {
        case .locationError, .locationTimeout, .networkError: return true
        case .authError, .generalError: return false
        }
    }
}

enum LoadingState {
    case none
    case auth
    case signOut
    case location
    case events
    case eventsMore
    case creating
    
    var message: String {
        switch self {
        case .none: return ""
        case .auth: return "Signing in..."
        case .signOut: return "Signing out..."
        case .location: return "Getting location..."
        case .events: return "Loading events..."
        case .eventsMore: return "Loading more events..."
        case .creating: return "Creating event..."
        }
    }
    
    var showsProgressIndicator: Bool {
        return self != .none
    }
    
    var allowsUserInteraction: Bool {
        switch self {
        case .none, .eventsMore: return true
        default: return false
        }
    }
}

extension CLAuthorizationStatus {
    var isAuthorized: Bool {
        return self == .authorizedWhenInUse || self == .authorizedAlways
    }
}
