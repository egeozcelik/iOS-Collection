//
//  LocationPermissionView.swift
//  MeetNow
//  Simplified location permission flow with better UX
//

import SwiftUI

struct LocationPermissionView: View {
    @EnvironmentObject var locationManager: LocationManager
    
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
                
                // Icon ve başlık
                VStack(spacing: 24) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    Text("Konum İzni Gerekli")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Yakındaki etkinlikleri görmek ve etkinlik oluşturmak için konum iznine ihtiyacımız var.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Permission status and action
                VStack(spacing: 20) {
                    // Current status
                    HStack {
                        Image(systemName: statusIcon)
                            .font(.title2)
                            .foregroundColor(statusColor)
                        
                        Text(statusText)
                            .font(.subheadline)
                            .foregroundColor(statusColor)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Action button
                    Button(action: handleLocationAction) {
                        HStack {
                            Image(systemName: buttonIcon)
                                .font(.headline)
                            
                            Text(buttonText)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(Color(hex: "4300FF"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 32)
                
                // Privacy note
                Text("Konum verileriniz güvenle saklanır ve sadece etkinlik özellikler için kullanılır.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                locationManager.requestLocationPermission()
            }
        }
    }
    
    private var statusIcon: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "location.circle"
        case .denied, .restricted:
            return "location.slash.circle"
        case .authorizedWhenInUse, .authorizedAlways:
            return "location.circle.fill"
        @unknown default:
            return "location.circle"
        }
    }
    
    private var statusColor: Color {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return .white.opacity(0.8)
        case .denied, .restricted:
            return .orange
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        @unknown default:
            return .white.opacity(0.8)
        }
    }
    
    private var statusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Konum izni henüz verilmedi"
        case .denied:
            return "Konum izni reddedildi"
        case .restricted:
            return "Konum erişimi kısıtlandı"
        case .authorizedWhenInUse:
            return "Konum izni verildi ✅"
        case .authorizedAlways:
            return "Konum izni verildi ✅"
        @unknown default:
            return "Konum durumu bilinmiyor"
        }
    }
    
    private var buttonIcon: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "location.fill"
        case .denied, .restricted:
            return "gearshape.fill"
        case .authorizedWhenInUse, .authorizedAlways:
            return "checkmark.circle.fill"
        @unknown default:
            return "location.fill"
        }
    }
    
    private var buttonText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Konum İznini Etkinleştir"
        case .denied, .restricted:
            return "Ayarlara Git"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Devam Et"
        @unknown default:
            return "Konum İznini Etkinleştir"
        }
    }
    
    // MARK: - Actions
    
    private func handleLocationAction() {
        print("📍 Location action triggered for status: \(locationManager.authorizationStatus)")
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestLocationPermission()
        case .denied, .restricted:
            // Open Settings
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission already granted, this should trigger transition in ContentView
            print("✅ Location permission already granted")
        @unknown default:
            locationManager.requestLocationPermission()
        }
    }
}
