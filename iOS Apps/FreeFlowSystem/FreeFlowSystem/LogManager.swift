//
//  LogManager.swift
//  FreeFlowSystem
//
//  Created by Ege on 17.03.2025.
//

import SwiftUI

// MARK: - Loglama islemleri
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let type: LogType
    let message: String
    let details: String?
    
    enum LogType: String {
        case ble = "Bluetooth"
        case uwb = "UWB"
        case system = "Sistem"
        case error = "Hata"
        
        var color: Color {
            switch self {
            case .ble: return .blue
            case .uwb: return .green
            case .system: return .gray
            case .error: return .red
            }
        }
    }
}

class LogManager: ObservableObject {
    static let shared = LogManager()
    @Published var logs: [LogEntry] = []
    
    func log(_ type: LogEntry.LogType, message: String, details: String? = nil) {
        let entry = LogEntry(timestamp: Date(), type: type, message: message, details: details)
        DispatchQueue.main.async {
            self.logs.insert(entry, at: 0)
            
            if self.logs.count > 200 {
                self.logs = Array(self.logs.prefix(200))
            }
        }
        print("[\(type)]: \(message)")
    }
    
    func exportLogs() -> String {
        var csvString = "Zaman,Tip,Mesaj,Detaylar\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        for log in logs {
            let timestamp = dateFormatter.string(from: log.timestamp)
            let type = log.type.rawValue
            let message = log.message.replacingOccurrences(of: "\"", with: "\"\"")
            let details = log.details?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            
            csvString += "\"\(timestamp)\",\"\(type)\",\"\(message)\",\"\(details)\"\n"
        }
        
        return csvString
    }
    
    func clearLogs() {
        logs.removeAll()
    }
}

struct UWBSessionInfo {
    var startTime: Date?
    var packetCount: Int = 0
    var lastUpdate: Date?
    var status: UWBSessionStatus = .notStarted
    
    enum UWBSessionStatus: String {
        case notStarted = "Başlatılmadı"
        case starting = "Başlatılıyor"
        case active = "Aktif"
        case paused = "Duraklatıldı"
        case error = "Hata"
        case stopped = "Durduruldu"
    }
    
    mutating func updateStatus(_ status: UWBSessionStatus) {
        self.status = status
        self.lastUpdate = Date()
        
        if status == .active && startTime == nil {
            startTime = Date()
        }
    }
    
    mutating func incrementPacketCount() {
        packetCount += 1
        lastUpdate = Date()
    }
    
    mutating func reset() {
        startTime = nil
        packetCount = 0
        lastUpdate = nil
        status = .notStarted
    }
}
