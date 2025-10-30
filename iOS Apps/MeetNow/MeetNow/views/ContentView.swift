//
//  ContentView.swift
//  MeetNow
//  Updated to use new EventManager interface
//

import SwiftUI
import CoreLocation


struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var appStateManager: AppStateManager
    @StateObject private var eventManager: EventManager
    
    init() {
        let authManager = AuthenticationManager()
        let locationManager = LocationManager()
        let appStateManager = AppStateManager(authManager: authManager, locationManager: locationManager)
        let eventManager = EventManager(authManager: authManager, locationManager: locationManager)
        
        self._authManager = StateObject(wrappedValue: authManager)
        self._locationManager = StateObject(wrappedValue: locationManager)
        self._appStateManager = StateObject(wrappedValue: appStateManager)
        self._eventManager = StateObject(wrappedValue: eventManager)
    }
    
    var body: some View {
        ZStack {
            switch appStateManager.currentStage {
            case .splash:
                SplashView()
                    
            case .auth:
                AuthenticationView()
                    .environmentObject(authManager)
                    
            case .locationPermission:
                LocationPermissionView()
                    .environmentObject(locationManager)
                    
            case .loadingEvents:
                LoadingEventsView()
                    .environmentObject(locationManager)
                    .environmentObject(eventManager)
                    .environmentObject(appStateManager)
                    
            case .main:
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(locationManager)
                    .environmentObject(eventManager)
                    .environmentObject(appStateManager)
            }
            
            if appStateManager.isLoading && appStateManager.currentStage != .loadingEvents {
                LoadingOverlayCustom(message: appStateManager.loadingMessage)
            }
            
            if let errorState = appStateManager.errorState {
                ErrorOverlay(
                    errorState: errorState,
                    onRetry: {
                        appStateManager.retryCurrentOperation()
                    },
                    onDismiss: {
                        appStateManager.clearErrorState()
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appStateManager.currentStage)
        .onAppear {
            appStateManager.setEventManager(eventManager)
            eventManager.setAppStateManager(appStateManager)
        }
    }
}

struct LoadingEventsView: View {
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "4300FF"),
                    Color(hex: "0065F8"),
                    Color(hex: "00CAFF")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 2.0).repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                        
                        Image(systemName: getCurrentIcon())
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Text(getCurrentTitle())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(getCurrentSubtitle())
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack {
                        Image(systemName: getStatusIcon())
                            .foregroundColor(getStatusColor())
                        Text(getStatusText())
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                }
                
                Spacer()
                
            }
        }
        .onAppear {
            isAnimating = true
            startLocationCheck()
        }

        .onReceive(locationManager.locationPublisher) { _ in
            if locationManager.hasValidLocation &&
               appStateManager.currentStage == .loadingEvents &&
               eventManager.allEvents.isEmpty {
                eventManager.loadInitialEvents()
            }
        }

    }
    
    private func startLocationCheck() {
        if !locationManager.hasValidLocation {
            locationManager.getCurrentLocationOnce()
        }
    }
    
    private func getCurrentIcon() -> String {
        if locationManager.hasValidLocation {
            return "checkmark.circle.fill"
        } else {
            return "location.magnifyingglass"
        }
    }
    
    private func getCurrentTitle() -> String {
        if locationManager.hasValidLocation {
            return "Getting ready..."
        } else {
            return "Getting your location..."
        }
    }
    
    private func getCurrentSubtitle() -> String {
        if locationManager.hasValidLocation {
            return "Loading nearby events"
        } else {
            return "GPS signal required"
        }
    }
    
    private func getStatusIcon() -> String {
        if locationManager.hasValidLocation {
            return "checkmark.circle.fill"
        } else {
            return "location.circle"
        }
    }
    
    private func getStatusColor() -> Color {
        if locationManager.hasValidLocation {
            return .green
        } else {
            return .orange
        }
    }
    
    private func getStatusText() -> String {
        if locationManager.hasValidLocation {
            return "Location ready"
        } else {
            return "Getting location"
        }
    }
}

struct LoadingOverlayCustom: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
            }
        }
    }
}

struct ErrorOverlay: View {
    let errorState: ErrorState
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text(errorState.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(errorState.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    if errorState.canRetry {
                        Button("Retry") {
                            onRetry()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.gray)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .padding(.horizontal, 40)
        }
    }
}

struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 24) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Text("MeetNow")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            isAnimating = true
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var isAnimating = false
    @State private var showCreateSheet = false
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Home")
                    }
                    .tag(0)
                
                Text("")
                    .tabItem {
                        Text("")
                    }
                    .tag(1)
                
                MapView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "map.fill" : "map")
                        Text("Map")
                    }
                    .tag(2)
            }
            .onChange(of: selectedTab) { newTab in
                if newTab == 1 {
                    selectedTab = 0
                }
            }
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    CreateEventButton(
                        isAnimating: $isAnimating,
                        action: {
                            triggerCreateEvent()
                        }
                    )
                    
                    Spacer()
                }
                .offset(y: -15)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateEventView()
        }
        .alert("Çıkış Hatası", isPresented: .constant(!authManager.errorMessage.isEmpty && authManager.isSigningOut)) {
            Button("Tamam") {
                authManager.resetAuthState()
            }
        } message: {
            Text(authManager.errorMessage)
        }
    }
    
    private func triggerCreateEvent() {
        guard locationManager.hasValidLocation else {
            locationManager.getCurrentLocationOnce()
            return
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                isAnimating = false
            }
            showCreateSheet = true
        }
    }
}

struct CreateEventButton: View {
    @Binding var isAnimating: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "00FFDE"), Color(hex: "00CAFF"), Color(hex: "0065F8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(hex: "4300FF").opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "plus")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isAnimating ? 180 : 0))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                
                if isAnimating {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "00CAFF"), Color(hex: "00FFDE")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 110, height: 110)
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .opacity(isAnimating ? 0 : 1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isAnimating ? 0.9 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)
    }
}

#Preview {
    ContentView()
}
