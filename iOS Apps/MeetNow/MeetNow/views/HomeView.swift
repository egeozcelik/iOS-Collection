import SwiftUI
import CoreLocation

struct HomeView: View {
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var appStateManager: AppStateManager
    
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()
                
                if eventManager.allEvents.isEmpty && !eventManager.isLoading && !isRefreshing {
                  ScrollView{
                      EmptyStateView()
                  }
                  .refreshable {
                      await refreshEvents()
                  }
                    
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if let location = locationManager.currentLocation {
                                LocationHeaderView(
                                    location: location,
                                    eventCount: eventManager.allEvents.count
                                )
                                .padding(.horizontal)
                                //.padding(.top, 8)
                            }
                            
                         

                            ForEach(eventManager.allEvents, id: \.id) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCard(event: event, userLocation: locationManager.currentLocation)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle()) // Buton görünümünü kaldır
                                .onAppear {
                                    eventManager.loadMoreEventsIfNeeded(currentEvent: event)
                                }
                            }
                            
                            if eventManager.isLoadingMore {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    
                                    Text("Loading more events...")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding()
                            }
                            
                            Spacer().frame(height: 100)
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await refreshEvents()
                    }
                }
                
               
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        ProfileImageView()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    LocationStatusButton()
                }
            }
        }
        .onAppear {
            if eventManager.allEvents.isEmpty && !eventManager.isLoading {
                eventManager.loadInitialEvents()
            }
        }
    }
    
    @MainActor
    private func refreshEvents() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        async let minDelay = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        eventManager.refreshEvents()
    
        await minDelay.value
        
        isRefreshing = false
    }
}


struct LocationHeaderView: View {
    let location: CLLocation
    let eventCount: Int
    
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.white.opacity(1))
                    .font(.caption)
                
                Text("\(eventCount) events")
                    .font(.caption)
                    .foregroundColor(.white.opacity(1))
                
                Spacer()
                Text("MeetNow")
                    .foregroundColor(.white.opacity(1))
                    .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.2))
        .cornerRadius(8)
    }
}

struct LoadingView: View {
    let message: String
    
    var body: some View {
        EmptyView()
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.circle")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Events will load soon")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("No active events found nearby.\nPull to refresh to check for new events.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct LocationStatusButton: View {
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        Button(action: {
            if locationManager.isLocationAuthorized {
                locationManager.getCurrentLocationOnce()
            
            } else {
                locationManager.requestLocationPermission()
            }
        }) {
            Image(systemName: locationManager.isUpdatingLocation ? "location.fill" : "location")
                .foregroundColor(locationManager.isLocationAuthorized ? .green : .orange)
                .font(.title3)
                .symbolEffect(.pulse, isActive: locationManager.isUpdatingLocation)
        }
    }
}

struct ProfileImageView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        AsyncImage(url: URL(string: authManager.currentUser?.profileImageURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                )
        }
        .frame(width: 35, height: 35)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "4300FF"), Color(hex: "00CAFF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
}
