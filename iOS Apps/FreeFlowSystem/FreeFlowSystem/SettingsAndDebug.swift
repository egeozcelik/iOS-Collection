//
//  SettingsAndDebug.swift
//  FreeFlowSystem
//
//  Created by Ege on 17.03.2025.
//


import SwiftUI
import NearbyInteraction
import UniformTypeIdentifiers

// MARK: - Settings Page
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var logManager = LogManager.shared
    @ObservedObject var connectionManager: AccessoryConnectionManager
    
    init(connectionManager: AccessoryConnectionManager = AccessoryConnectionManager()) {
        self.connectionManager = connectionManager
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("UWB Oturum Yönetimi")) {
                    NavigationLink(destination: UWBSessionDetailView(connectionManager: connectionManager)) {
                        Label("UWB Oturum Bilgisi", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    
                    Button(action: {
                        connectionManager.resetUWBSession()
                    }) {
                        Label("UWB Oturumunu Sıfırla", systemImage: "arrow.clockwise")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Bluetooth Yönetimi")) {
                    NavigationLink(destination: BluetoothDetailView(connectionManager: connectionManager)) {
                        Label("Bluetooth Bağlantı Detayları", systemImage: "wave.3.right")
                    }
                    
                    Button(action: {
                        do {
                            try connectionManager.dataChannel.startScan()
                        } catch {
                            print("BLE tarama hatası: \(error)")
                        }
                    }) {
                        Label("BLE Taramasını Başlat", systemImage: "magnifyingglass")
                    }
                    
                    Button(action: {
                        connectionManager.dataChannel.stopScan()
                    }) {
                        Label("BLE Taramasını Durdur", systemImage: "stop.circle")
                    }
                }
                
                Section(header: Text("Hata Ayıklama")) {
                    NavigationLink(destination: LogsView(logManager: logManager)) {
                        Label("Log Kayıtları", systemImage: "doc.text")
                    }
                }
                
                Section(header: Text("Hakkında")) {
                    HStack {
                        Text("Uygulama Sürümü")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("UWB Teknolojisi")
                        Spacer()
                        Text("NXP SR150")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct UWBSessionDetailView: View {
    @ObservedObject var connectionManager: AccessoryConnectionManager
    
    var body: some View {
        List {
            Section(header: Text("Aktif Oturum Bilgisi")) {
                DetailRowView(title: "Durum", value: connectionManager.sessionInfo.status.rawValue, color: statusColor(connectionManager.sessionInfo.status))
                
                if let startTime = connectionManager.sessionInfo.startTime {
                    DetailRowView(title: "Başlangıç Zamanı", value: formatDate(startTime))
                }
                
                if let lastUpdate = connectionManager.sessionInfo.lastUpdate {
                    DetailRowView(title: "Son Güncelleme", value: formatDate(lastUpdate))
                }
                
                DetailRowView(title: "Paket Sayısı", value: "\(connectionManager.sessionInfo.packetCount)")
                
                if let distance = connectionManager.distance {
                    DetailRowView(title: "Mevcut Mesafe", value: String(format: "%.2f m", distance))
                }
                
                if let rssi = connectionManager.rssiValue {
                    DetailRowView(title: "Sinyal Gücü (RSSI)", value: "\(rssi) dBm", color: rssiColor(rssi))
                }
            }
            
            Section(header: Text("UWB Aksiyonları")) {
                if connectionManager.uwbActive {
                    Button(action: {
                        let stopMessage = Data([MessageId.stop.rawValue])
                        connectionManager.sendDataToAccessory(stopMessage)
                    }) {
                        Label("UWB Oturumunu Durdur", systemImage: "stop.fill")
                            .foregroundColor(.red)
                    }
                } else {
                    Button(action: {
                        connectionManager.initialize()
                    }) {
                        Label("UWB Oturumunu Başlat", systemImage: "play.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Button(action: {
                    connectionManager.resetUWBSession()
                }) {
                    Label("UWB Oturumunu Sıfırla", systemImage: "arrow.clockwise")
                        .foregroundColor(.orange)
                }
            }
        }
        .navigationTitle("UWB Oturum Detayları")
        .onAppear {
            connectionManager.dataChannel.readRSSI()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss - dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    private func statusColor(_ status: UWBSessionInfo.UWBSessionStatus) -> Color {
        switch status {
        case .active: return .green
        case .starting, .paused: return .orange
        case .error, .stopped: return .red
        case .notStarted: return .gray
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
}

struct BluetoothDetailView: View {
    @ObservedObject var connectionManager: AccessoryConnectionManager
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            Section(header: Text("Bluetooth Bağlantı Durumu")) {
                DetailRowView(title: "Bağlantı Durumu",
                             value: connectionManager.accessoryConnected ? "Bağlı" : "Bağlı Değil",
                             color: connectionManager.accessoryConnected ? .green : .red)
                
                if let deviceName = connectionManager.connectedAccessoryName {
                    DetailRowView(title: "Bağlı Cihaz", value: deviceName)
                }
                
                if let rssi = connectionManager.rssiValue {
                    DetailRowView(title: "Sinyal Gücü (RSSI)", value: "\(rssi) dBm", color: rssiColor(rssi))
                }
            }
            
            Section(header: Text("BLE Aksiyonları")) {
                Button(action: {
                    do {
                        try connectionManager.dataChannel.startScan()
                    } catch let error as BluetoothLECentralError {
                        switch error {
                        case .scanning:
                            alertMessage = "Tarama zaten devam ediyor."
                        case .notReady:
                            alertMessage = "Bluetooth hazır değil."
                        default:
                            alertMessage = "Bilinmeyen hata."
                        }
                        isShowingAlert = true
                    } catch {
                        alertMessage = "Hata: \(error.localizedDescription)"
                        isShowingAlert = true
                    }
                }) {
                    Label("Taramayı Başlat", systemImage: "magnifyingglass")
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    connectionManager.dataChannel.stopScan()
                }) {
                    Label("Taramayı Durdur", systemImage: "stop.circle")
                        .foregroundColor(.orange)
                }
                
                Button(action: {
                    connectionManager.dataChannel.disconnect()
                }) {
                    Label("Bağlantıyı Kes", systemImage: "xmark.circle")
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    connectionManager.dataChannel.readRSSI()
                }) {
                    Label("RSSI Değerini Yenile", systemImage: "arrow.clockwise")
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Bluetooth Detayları")
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("BLE Bilgisi"), message: Text(alertMessage), dismissButton: .default(Text("Tamam")))
        }
        .onAppear {
            connectionManager.dataChannel.readRSSI()
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
}

struct LogsView: View {
    @ObservedObject var logManager: LogManager
    @State private var searchText = ""
    @State private var selectedLogType: LogEntry.LogType? = nil
    @State private var showExportSheet = false
    @State private var exportedFileURL: URL?
    
    var filteredLogs: [LogEntry] {
        let typedLogs = selectedLogType == nil ? logManager.logs : logManager.logs.filter { $0.type == selectedLogType }
        
        if searchText.isEmpty {
            return typedLogs
        } else {
            return typedLogs.filter {
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                (($0.details ?? "").localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    selectedLogType = nil
                }) {
                    Text("Tümü")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(selectedLogType == nil ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedLogType == nil ? .white : .primary)
                        .cornerRadius(8)
                }
                
                ForEach([LogEntry.LogType.ble, .uwb, .system, .error], id: \.self) { type in
                    Button(action: {
                        selectedLogType = type
                    }) {
                        Text(type.rawValue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(selectedLogType == type ? type.color : Color.gray.opacity(0.2))
                            .foregroundColor(selectedLogType == type ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Loglarda ara...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            List {
                ForEach(filteredLogs) { log in
                    LogEntryRow(log: log)
                }
            }
            
            // Alt butonlar
            HStack {
                Button(action: {
                    logManager.clearLogs()
                }) {
                    Label("Logları Temizle", systemImage: "trash")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    exportLogs()
                }) {
                    Label("Dışa Aktar", systemImage: "square.and.arrow.up")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Log Kayıtları")
        .sheet(isPresented: $showExportSheet) {
            if let fileURL = exportedFileURL {
                ShareSheet(activityItems: [fileURL])
            }
        }
    }
    
    private func exportLogs() {
        let csvString = logManager.exportLogs()
        let fileName = "uwb_logs_\(Date().timeIntervalSince1970).csv"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            self.exportedFileURL = path
            self.showExportSheet = true
        } catch {
            print("Dosya yazma hatası: \(error)")
        }
    }
}

 // MARK: - Log Giriş Satırı
 struct LogEntryRow: View {
     var log: LogEntry
     @State private var showDetails = false
     
     var body: some View {
         VStack(alignment: .leading, spacing: 4) {
             HStack {
                 Circle()
                     .fill(log.type.color)
                     .frame(width: 10, height: 10)
                 
                 Text(formatDate(log.timestamp))
                     .font(.caption)
                     .foregroundColor(.secondary)
                 
                 Spacer()
                 
                 Text(log.type.rawValue)
                     .font(.caption)
                     .padding(.horizontal, 6)
                     .padding(.vertical, 2)
                     .background(log.type.color.opacity(0.2))
                     .cornerRadius(4)
             }
             
             Text(log.message)
                 .font(.body)
                 .lineLimit(showDetails ? nil : 1)
             
             if let details = log.details, !details.isEmpty {
                 if showDetails {
                     Text(details)
                         .font(.callout)
                         .foregroundColor(.secondary)
                         .padding(.top, 2)
                 } else {
                     Text("Detaylar için tıklayın")
                         .font(.caption)
                         .foregroundColor(.blue)
                         .padding(.top, 2)
                 }
             }
         }
         .padding(.vertical, 4)
         .contentShape(Rectangle())
         .onTapGesture {
             withAnimation {
                 showDetails.toggle()
             }
         }
     }
     
     private func formatDate(_ date: Date) -> String {
         let formatter = DateFormatter()
         formatter.dateFormat = "HH:mm:ss"
         return formatter.string(from: date)
     }
 }

 struct DetailRowView: View {
     var title: String
     var value: String
     var color: Color = .primary
     
     var body: some View {
         HStack {
             Text(title)
                 .foregroundColor(.secondary)
             Spacer()
             Text(value)
                 .foregroundColor(color)
         }
     }
 }

 struct ShareSheet: UIViewControllerRepresentable {
     var activityItems: [Any]
     var applicationActivities: [UIActivity]? = nil
     
     func makeUIViewController(context: Context) -> UIActivityViewController {
         let controller = UIActivityViewController(
             activityItems: activityItems,
             applicationActivities: applicationActivities
         )
         return controller
     }
     
     func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
         
     }
 }

                 
