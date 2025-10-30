//
//  MapView.swift
//  MeetNow
//  Enhanced version with user location and optimized event display
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedEvent: EventModel?
    @State private var dragOffset = CGSize.zero
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.4237, longitude: 27.1428),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $mapRegion,
                    showsUserLocation: true,
                    userTrackingMode: .constant(.none),
                    annotationItems: eventManager.allEvents) { event in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: event.location.latitude,
                        longitude: event.location.longitude
                    )) {
                        EventMapAnnotation(
                            event: event,
                            isSelected: selectedEvent?.id == event.id,
                            userLocation: locationManager.currentLocation
                        ) {
                            withAnimation(.spring()) {
                                selectedEvent = event
                                // Center map on selected event
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    mapRegion.center = CLLocationCoordinate2D(
                                        latitude: event.location.latitude,
                                        longitude: event.location.longitude
                                    )
                                }
                            }
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)
                .onTapGesture {
                    // Haritaya tıklandığında kartı kapat
                    if selectedEvent != nil {
                        withAnimation(.spring()) {
                            selectedEvent = nil
                        }
                    }
                }
                
                // User location controls
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            LocationControlButton(
                                icon: "location.fill",
                                isActive: locationManager.isUpdatingLocation,
                                action: {
                                    centerOnUserLocation()
                                }
                            )
                            
                            LocationControlButton(
                                icon: "arrow.clockwise",
                                isActive: eventManager.isLoading,
                                action: {
                                    refreshEvents()
                                }
                            )
                        }
                        .padding(.trailing)
                        .padding(.top, 100)
                    }
                    
                    Spacer()
                }
                
                // Event card at bottom
                VStack {
                    Spacer()
                    
                    if let selectedEvent = selectedEvent {
                        EventCardWithGesture(
                            event: selectedEvent,
                            userLocation: locationManager.currentLocation,
                            dragOffset: $dragOffset
                        ) {
                            // Navigation to detail
                        } onDismiss: {
                            withAnimation(.spring()) {
                                self.selectedEvent = nil
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                // Loading overlay
                if eventManager.isLoading && eventManager.allEvents.isEmpty {
                    LoadingOverlayView()
                }
                
                // Location status overlay
                if !locationManager.isLocationAuthorized {
                    LocationPermissionOverlay()
                }
                
                // Error overlay
                if !eventManager.errorMessage.isEmpty {
                    ErrorOverlayView(
                        message: eventManager.errorMessage,
                        onDismiss: {
                            eventManager.errorMessage = ""
                        },
                        onRetry: {
                            refreshEvents()
                        }
                    )
                }
            }
            .navigationTitle("Harita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        ProfileImageView()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    MapInfoButton(
                        eventCount: eventManager.allEvents.count,
                        isLoading: eventManager.isLoading
                    )
                }
            }
        }
        .onAppear {
            setupMapView()
        }
        .onChange(of: locationManager.currentLocation) { location in
            updateMapForLocation(location)
        }
        .onChange(of: eventManager.allEvents) {
            adjustMapRegionForEvents(eventManager.allEvents)
        }
    }
    
    private func setupMapView() {
        if let userLocation = locationManager.currentLocation {
            mapRegion.center = userLocation.coordinate
        }
        
        locationManager.startLocationUpdates()
        if eventManager.allEvents.isEmpty {
           // eventManager.refreshEvents()
        }
    }
    
    private func updateMapForLocation(_ location: CLLocation?) {
        guard let location = location else { return }
        
        // Update map center with animation
        withAnimation(.easeInOut(duration: 1.0)) {
            mapRegion.center = location.coordinate
        }
    }
    
    private func centerOnUserLocation() {
        guard let userLocation = locationManager.currentLocation else {
            locationManager.getCurrentLocationOnce()
            return
        }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            mapRegion.center = userLocation.coordinate
            mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }
    }
    
    private func refreshEvents() {
        //eventManager.refreshEvents()
    }
    
    private func adjustMapRegionForEvents(_ events: [EventModel]) {
        guard !events.isEmpty, let userLocation = locationManager.currentLocation else { return }
        
        // Calculate bounding box for all events within 10km (for better UX)
        let nearbyEvents = events.filter { event in
            let eventLocation = CLLocation(latitude: event.location.latitude, longitude: event.location.longitude)
            return userLocation.distance(from: eventLocation) <= 10000 // 10km
        }
        
        guard nearbyEvents.count > 1 else { return }
        
        var minLat = nearbyEvents.first!.location.latitude
        var maxLat = nearbyEvents.first!.location.latitude
        var minLon = nearbyEvents.first!.location.longitude
        var maxLon = nearbyEvents.first!.location.longitude
        
        for event in nearbyEvents {
            minLat = min(minLat, event.location.latitude)
            maxLat = max(maxLat, event.location.latitude)
            minLon = min(minLon, event.location.longitude)
            maxLon = max(maxLon, event.location.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5, // Add padding
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        withAnimation(.easeInOut(duration: 1.5)) {
            mapRegion = MKCoordinateRegion(center: center, span: span)
        }
    }
}

struct EventMapAnnotation: View {
    let event: EventModel
    let isSelected: Bool
    let userLocation: CLLocation?
    let onTap: () -> Void
    @State private var isAnimating = false
    
    private var annotationColors: [Color] {
        let colorSets = [
            [Color(hex: "6B73FF"), Color(hex: "000DFF")],
            [Color(hex: "00C9FF"), Color(hex: "92FE9D")],
            [Color(hex: "FC466B"), Color(hex: "3F5EFB")],
            [Color(hex: "FDBB2D"), Color(hex: "22C1C3")],
            [Color(hex: "667eea"), Color(hex: "764ba2")],
            [Color(hex: "f093fb"), Color(hex: "f5576c")],
            [Color(hex: "4facfe"), Color(hex: "00f2fe")],
            [Color(hex: "a8edea"), Color(hex: "fed6e3")],
            [Color(hex: "ff9a9e"), Color(hex: "fecfef")],
            [Color(hex: "ffecd2"), Color(hex: "fcb69f")]
        ]
        let index = abs(event.id.hashValue) % colorSets.count
        return colorSets[index]
    }
    
    private var distance: String? {
        guard let userLocation = userLocation else { return nil }
        let eventLocation = CLLocation(latitude: event.location.latitude, longitude: event.location.longitude)
        let distanceInMeters = userLocation.distance(from: eventLocation)
        
        if distanceInMeters < 1000 {
            return String(format: "%.0fm", distanceInMeters)
        } else {
            return String(format: "%.1fkm", distanceInMeters / 1000)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer pulse ring
                if isSelected {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: annotationColors.map { $0.opacity(0.1) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0.3 : 0.6)
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                // Middle ring
                Circle()
                    .fill(
                        LinearGradient(
                            colors: annotationColors.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isSelected ? 80 : 60, height: isSelected ? 80 : 60)
                    .animation(.spring(response: 0.3), value: isSelected)
                
                // Inner circle with icon
                Circle()
                    .fill(
                        LinearGradient(
                            colors: annotationColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isSelected ? 3 : 2)
                    )
                    .animation(.spring(response: 0.3), value: isSelected)
                
                Image(systemName: event.icon)
                    .font(.system(size: isSelected ? 20 : 16, weight: .bold))
                    .foregroundColor(.white)
                    .animation(.spring(response: 0.3), value: isSelected)
                
                // Distance label
                if let distance = distance, !isSelected {
                    VStack {
                        Spacer()
                        Text(distance)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .offset(y: 25)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isSelected {
                isAnimating = true
            }
        }
        .onChange(of: isSelected) { selected in
            isAnimating = selected
        }
    }
}

struct LocationControlButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isActive ? .white : .primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isActive ? Color.blue : Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
                .symbolEffect(.pulse, isActive: isActive)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EventCardWithGesture: View {
    let event: EventModel
    let userLocation: CLLocation?
    @Binding var dragOffset: CGSize
    let onTap: () -> Void
    let onDismiss: () -> Void
    @State private var cardOffset: CGFloat = 0
    @EnvironmentObject var locationManager: LocationManager
    
    private var distance: String {
        return event.distanceText(from: userLocation)
    }
    
    var body: some View {
        ZStack {
            // Ana event kartı
            NavigationLink(destination: EventDetailView(event: event)) {
                VStack(spacing: 0) {
                    EventCard(event: event, userLocation: userLocation)
                    
                    // Distance and action footer
                    HStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(distance)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Katıl") {
                            // Join event action
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.95))
                }
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
            .offset(y: cardOffset)
            
            // Çarpı (kapatma) butonu
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 8)
                }
                
                Spacer()
            }
        }
    }
}

struct LoadingOverlayView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Yakındaki etkinlikler yükleniyor...")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
            }
        }
    }
}

struct LocationPermissionOverlay: View {
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "location.slash.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text("Konum İzni Gerekli")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Haritada etkinlikleri görmek için konum iznine ihtiyacımız var")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Konum İznini Ver") {
                    locationManager.requestLocationPermission()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
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

struct ErrorOverlayView: View {
    let message: String
    let onDismiss: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hata")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(message)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Tekrar", action: onRetry)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Button("✕", action: onDismiss)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
}

struct MapInfoButton: View {
    let eventCount: Int
    let isLoading: Bool
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                if isLoading {
                    Text("Yükleniyor...")
                        .font(.caption2)
                        .foregroundColor(.blue)
                } else {
                    Text("\(eventCount) etkinlik")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.4237, longitude: 27.1428),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @Published var isTrackingUser = false
    @Published var mapType: MKMapType = .standard
    
    func updateRegionForLocation(_ location: CLLocation) {
        DispatchQueue.main.async {
            self.region.center = location.coordinate
        }
    }
    
    func zoomToLocation(_ coordinate: CLLocationCoordinate2D, span: MKCoordinateSpan? = nil) {
        let newSpan = span ?? MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        region = MKCoordinateRegion(center: coordinate, span: newSpan)
    }
}
