//
//  AppStats.swift
//  Memoerase
//
//  Created by Ege on 5.07.2025.
//

import Foundation

struct AppStats: Codable {
    var totalDeletedSize: Int64 = 0
    var totalDeletedCount: Int = 0
    var sessionsCount: Int = 0
    var lastSessionDate: Date?
    var totalLibrarySize: Int64 = 0
    var photoCount: Int = 0
    
    // Computed properties
    var formattedDeletedSize: String {
        totalDeletedSize.formatAsFileSize()
    }
    
    var formattedLibrarySize: String {
        totalLibrarySize.formatAsFileSize()
    }
    
    var deletionPercentage: Double {
        guard totalLibrarySize > 0 else { return 0 }
        return Double(totalDeletedSize) / Double(totalLibrarySize + totalDeletedSize) * 100
    }
    
    var averageDeletionPerSession: String {
        guard sessionsCount > 0 else { return "0 MB" }
        let average = totalDeletedSize / Int64(sessionsCount)
        return average.formatAsFileSize()
    }
    
    // MARK: - Update Methods
    mutating func recordDeletion(size: Int64) {
        totalDeletedSize += size
        totalDeletedCount += 1
    }
    
    mutating func startNewSession() {
        sessionsCount += 1
        lastSessionDate = Date()
    }
    
    mutating func updateLibraryInfo(size: Int64, count: Int) {
        totalLibrarySize = size
        photoCount = count
    }
}

// MARK: - UserDefaults Storage
extension AppStats {
    private static let userDefaultsKey = "MemoEraseAppStats"
    
    static func load() -> AppStats {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let stats = try? JSONDecoder().decode(AppStats.self, from: data) else {
            return AppStats()
        }
        return stats
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }
    
    static func reset() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
