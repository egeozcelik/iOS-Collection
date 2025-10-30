//
//  Photo.swift
//  Memoerase
//
//  Created by Ege on 5.07.2025.
//

import Photos
import Foundation

struct Photo: Identifiable, Equatable {
    let id: String
    let asset: PHAsset
    let creationDate: Date?
    let modificationDate: Date?
    let size: Int64
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.creationDate = asset.creationDate
        self.modificationDate = asset.modificationDate
        
        let resources = PHAssetResource.assetResources(for: asset)
        self.size = resources.first?.value(forKey: "fileSize") as? Int64 ?? 0
    }
    
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.id == rhs.id
    }
}


enum FilterMode: String, CaseIterable {
    case random = "Random"
    case oldestFirst = "Oldest First"
    case newestFirst = "Newest First"
    
    var icon: String {
        switch self {
        case .random:
            return "shuffle"
        case .oldestFirst:
            return "clock.arrow.2.clockwise"
        case .newestFirst:
            return "clock.arrow.2.circlepath"
        }
    }
    
    var description: String {
        switch self {
        case .random:
            return "Photos appear randomly"
        case .oldestFirst:
            return "From oldest to newest"
        case .newestFirst:
            return "From newest to oldest"
        }
    }
}

enum SwipeDirection {
    case left
    case right
    case none
}

extension Photo {
    var formattedDate: String {
        guard let date = creationDate else { return "Unknown date" }
        return date.formatted()
    }
    
    var timeAgo: String {
        guard let date = creationDate else { return "Unknown" }
        return date.timeAgo()
    }
    
    var formattedSize: String {
        return size.formatAsFileSize()
    }
}
