//
//  ContentView.swift
//  FreeFlowSystemWatchOS Watch App
//
//  Created by Ege on 14.05.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectionManager: WatchConnectionManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Bağlantı durumu
                HStack {
                    Image(systemName: connectionManager.accessoryConnected ? "circle.fill" : "circle")
                        .foregroundColor(connectionManager.accessoryConnected ? .green : .red)
                    
                    Text(connectionManager.connectedAccessoryName ?? "Bağlı Değil")
                        .font(.system(.headline))
                }
                
                Spacer()
                
                // UWB durumu ve mesafe
                if connectionManager.uwbActive, let distance = connectionManager.distance {
                    Text(String(format: "%.2f m", distance))
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(distanceColor(distance))
                } else {
                    Text(connectionManager.statusMessage)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Butonlar
                if connectionManager.accessoryConnected && !connectionManager.uwbActive {
                    Button("UWB Başlat") {
                        connectionManager.initialize()
                    }
                    .buttonStyle(.borderedProminent)
                } else if connectionManager.uwbActive {
                    Button("UWB Durdur") {
                        connectionManager.sendStopMessage()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Button("Yenile") {
                        connectionManager.startScan()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("FreeFlow")
        }
    }
    
    private func distanceColor(_ distance: Double) -> Color {
        if distance < 1.5 {
            return .green
        } else if distance < 3.0 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    @StateObject var connectionManager = WatchConnectionManager()
    ContentView()
        .environmentObject(connectionManager)
}
