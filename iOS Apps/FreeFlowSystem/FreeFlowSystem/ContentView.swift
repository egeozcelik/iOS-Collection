//
//  ContentView.swift
//  FreeFlowSystem
//
//  Created by Ege on 17.03.2025.
//

import SwiftUI
import NearbyInteraction
import UIKit

// MARK: UI


struct ContentView: View {
    @StateObject private var connectionManager = AccessoryConnectionManager()
    @ObservedObject var logManager = LogManager.shared
    @State private var showingSettings = false
    @State private var showingDebugInfo = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    companyLogoHeader
                    
                    VStack(spacing: 16) {
                        connectionStatusCard
                        
                        if connectionManager.accessoryConnected {
                            distanceCard
                        }
                        
                        infoCard
                        
                        if showingDebugInfo {
                            debugCard
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer().frame(height: 16)
                    
                    if connectionManager.accessoryConnected && !connectionManager.uwbActive {
                        actionButton
                        
                    } else if connectionManager.uwbActive && showingDebugInfo {
                        HStack(spacing: 16) {
                            Button(action: {
                                connectionManager.resetUWBSession()
                            }) {
                                Text("UWB Sıfırla")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.orange)
                                    .cornerRadius(16)
                            }
                            
                            Button(action: {
                                let stopMessage = Data([MessageId.stop.rawValue])
                                connectionManager.sendDataToAccessory(stopMessage)
                            }) {
                                Text("UWB Durdur")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    refreshButton
                        .padding(.top, 8)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarItems(
            trailing: HStack(spacing: 16) {
                Button(action: {
                    showingDebugInfo.toggle()
                }) {
                    Image(systemName: showingDebugInfo ? "ant.circle.fill" : "ant.circle")
                        .font(.system(size: 18))
                        .foregroundColor(showingDebugInfo ? .blue : .primary)
                }
                
                Button(action: {
                    showingSettings.toggle()
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                }
            }
        )
        .sheet(isPresented: $showingSettings) {
            SettingsView(connectionManager: connectionManager)
        }
    }
    
    private var companyLogoHeader: some View {
        VStack {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 60)
                .foregroundColor(.blue)
                .padding(.top, 20)
            
            Text("UWB Serbest Geçiş Sistemi")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Temassız geçiş teknolojisi")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .padding()
    }
    
    private var connectionStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Bağlantı Durumu")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(connectionManager.accessoryConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 28))
                            .foregroundColor(connectionManager.accessoryConnected ? .green : .red)
                    }
                    
                    Text("Bluetooth")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(connectionManager.accessoryConnected ? "Bağlı" : "Bağlı Değil")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(connectionManager.accessoryConnected ? .green : .red)
                }
                
                Divider().frame(height: 60)
                
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(connectionManager.uwbActive ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 28))
                            .foregroundColor(connectionManager.uwbActive ? .green : .red)
                    }
                    
                    Text("UWB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(connectionManager.uwbActive ? "Aktif" : "Pasif")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(connectionManager.uwbActive ? .green : .red)
                }
            }
            .padding()
            
            if let name = connectionManager.connectedAccessoryName {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.green)
                    
                    Text("Bağlı Cihaz: \(name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let rssi = connectionManager.rssiValue {
                        Spacer()
                        
                        Text("RSSI: \(rssi) dBm")
                            .font(.caption)
                            .foregroundColor(rssiColor(rssi))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var distanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Mesafe Bilgisi")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if let distance = connectionManager.distance {
                HStack {
                    
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: min(CGFloat(1.0 - (distance / 10)), 1.0))
                            .stroke(distanceColor(distance), lineWidth: 3)
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f", distance))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("metre")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Geçiş Durumu")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: distanceStatusIcon(distance))
                                .foregroundColor(distanceColor(distance))
                            
                            Text(distanceStatusText(distance))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(distanceColor(distance))
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .foregroundColor(Color.gray.opacity(0.2))
                                    .frame(height: 6)
                                    .cornerRadius(3)
                                
                                Rectangle()
                                    .foregroundColor(distanceColor(distance))
                                    .frame(width: min(CGFloat(5 - distance) / 5 * geometry.size.width, geometry.size.width), height: 6)
                                    .cornerRadius(3)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.leading, 16)
                }
                .padding()
            } else {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    
                    Text("Mesafe verisi bekleniyor...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
                .padding()
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Durum Bilgisi")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                Text(connectionManager.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var debugCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Debug Bilgisi")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
                
                Text("UWB Oturum Durumu: \(connectionManager.sessionInfo.status.rawValue)")
                    .font(.caption)
                    .foregroundColor(statusColor(connectionManager.sessionInfo.status))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Paket Sayısı:")
                        .font(.subheadline)
                    Text("\(connectionManager.sessionInfo.packetCount)")
                        .font(.subheadline)
                        .bold()
                }
                
                if let lastUpdate = connectionManager.sessionInfo.lastUpdate {
                    HStack {
                        Text("Son Güncelleme:")
                            .font(.subheadline)
                        Text(formatDate(lastUpdate))
                            .font(.subheadline)
                            .bold()
                    }
                }
                
                // Son 3 log kaydını tutması için
                if !logManager.logs.isEmpty {
                    Divider()
                    
                    Text("Son Loglar:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(logManager.logs.prefix(3))) { log in
                        HStack(alignment: .top, spacing: 4) {
                            Circle()
                                .fill(log.type.color)
                                .frame(width: 8, height: 8)
                                .padding(.top, 4)
                            
                            VStack(alignment: .leading) {
                                Text(log.message)
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                Text(formatTime(log.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Text("Tüm logları görüntüle")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var actionButton: some View {
        Button(action: {
            connectionManager.initialize()
        }) {
            HStack {
                if let distance = connectionManager.distance {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("UWB Oturumunu Yenile")
                } else{
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("UWB Oturumu Başlat")
                }
                
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            .padding(.horizontal)
        }
    }
    private var refreshButton: some View {
        Button(action: {
            if connectionManager.accessoryConnected {
                connectionManager.dataChannel.disconnect()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                do {
                    try connectionManager.dataChannel.startScan()
                    connectionManager.updateStatusMessage(with: "Yeniden tarama başlatıldı...")
                } catch {
                    connectionManager.updateStatusMessage(with: "Tarama başlatılamadı: \(error.localizedDescription)")
                }
            }
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Bağlantıyı Yenile")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 3)
            .padding(.horizontal)
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
    
    private func distanceStatusIcon(_ distance: Double) -> String {
        if distance < 1.5 {
            return "checkmark.circle.fill"
        } else if distance < 3.0 {
            return "exclamationmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private func distanceStatusText(_ distance: Double) -> String {
        if distance < 1.2 {
            return "Turnike Geçiş Alanı"
        } else if distance < 5.0 {
            return "UWB ile Hassas Konum Ölçüm Alanı. "
        } else {
            return "UWB Kapsam Dışı Bölümde"
        }
    }
    
    private func rssiColor(_ rssi: Int) -> Color {
        if rssi > -50 {
            return .green
        } else if rssi > -70 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func statusColor(_ status: UWBSessionInfo.UWBSessionStatus) -> Color {
        switch status {
        case .active: return .green
        case .starting, .paused: return .orange
        case .error, .stopped: return .red
        case .notStarted: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss - dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - SwiftUI Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContentView()
        }
    }
}
