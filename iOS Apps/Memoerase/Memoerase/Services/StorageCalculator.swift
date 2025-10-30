//
//  StorageManager.swift
//  Memoerase
//
//  FileManager ile Photos Directory Okuma - YENİ VERSİYON
//

import Photos
import Foundation

@MainActor
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    // MARK: - Published Properties
    @Published var totalLibrarySize: Int64 = 0
    @Published var currentLibrarySize: Int64 = 0  // Real-time güncellenen
    @Published var isLoadingStorage: Bool = false
    @Published var storageError: String?
    
    // Session & Lifetime stats
    @Published var sessionDeleted: Int64 = 0
    
    // Lifetime stats - Int64 için manual UserDefaults
    private var lifetimeDeleted: Int64 {
        get {
            return UserDefaults.standard.object(forKey: "lifetimeDeletedSize") as? Int64 ?? 0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lifetimeDeletedSize")
        }
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Asenkron olarak library storage'ını FileManager ile oku
    func loadTotalLibrarySize() async {
        isLoadingStorage = true
        storageError = nil
        
        do {
            let size = await calculatePhotoLibrarySize()
            
            totalLibrarySize = size
            currentLibrarySize = size  // İlk başta aynı
            isLoadingStorage = false
            
            print("📊 Total Library Size loaded: \(size.formatAsFileSize())")
            
        } catch {
            storageError = "Storage calculation failed: \(error.localizedDescription)"
            isLoadingStorage = false
            print("❌ Storage calculation error: \(error)")
        }
    }
    
    /// Foto silindiğinde storage'ı güncelle
    func recordPhotoDeletion(photoSize: Int64) {
        currentLibrarySize -= photoSize
        sessionDeleted += photoSize
        lifetimeDeleted += photoSize
        
        print("🗑️ Photo deleted: \(photoSize.formatAsFileSize()) - Remaining: \(currentLibrarySize.formatAsFileSize())")
    }
    
    /// Manual refresh
    func refreshStorageInfo() {
        Task {
            await loadTotalLibrarySize()
        }
    }
    
    // MARK: - Computed Properties
    
    var lifetimeDeletedSize: Int64 {
        lifetimeDeleted
    }
    
    var deletionPercentage: Double {
        guard totalLibrarySize > 0 else { return 0 }
        return (Double(sessionDeleted) / Double(totalLibrarySize)) * 100
    }
    
    var formattedTotalSize: String {
        totalLibrarySize.formatAsFileSize()
    }
    
    var formattedCurrentSize: String {
        currentLibrarySize.formatAsFileSize()
    }
    
    var formattedSessionDeleted: String {
        sessionDeleted.formatAsFileSize()
    }
    
    var formattedLifetimeDeleted: String {
        lifetimeDeleted.formatAsFileSize()
    }
    
    // MARK: - Device Storage Info
    func getDeviceStorageInfo() -> (total: Int64, free: Int64, used: Int64) {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) else {
            return (0, 0, 0)
        }
        
        let totalSpace = systemAttributes[.systemSize] as? Int64 ?? 0
        let freeSpace = systemAttributes[.systemFreeSize] as? Int64 ?? 0
        let usedSpace = totalSpace - freeSpace
        
        return (totalSpace, freeSpace, usedSpace)
    }
    
    func getStorageInfoForDisplay() -> (free: String, total: String, freePercentage: Double) {
        let info = getDeviceStorageInfo()
        let freePercentage = info.total > 0 ? (Double(info.free) / Double(info.total)) * 100 : 0
        
        return (
            free: info.free.formatAsFileSize(),
            total: info.total.formatAsFileSize(),
            freePercentage: freePercentage
        )
    }
}

// MARK: - FileManager ile Photos Storage Calculation

extension StorageManager {
    
    /// EN HIZLI: Sadece Photos app'in gerçek storage'ını oku
    private func calculatePhotoLibrarySize() async -> Int64 {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                
                print("📱 Looking for Photos app specific storage...")
                
                var totalSize: Int64 = 0
                
                // Önce Photos app'in gerçek data path'ini bul
                if let photosDataPath = self.getPhotosAppDataPath() {
                    totalSize = self.calculateDirectorySize(at: photosDataPath)
                    print("📁 Photos App Data: \(photosDataPath) = \(totalSize.formatAsFileSize())")
                }
                
                // Eğer bulamazsak, bilinen Photos-specific cache'leri dene
                if totalSize == 0 {
                    print("🔍 Searching Photos-specific directories...")
                    
                    let photosSpecificPaths = [
                        // Sadece Photos'a özgü cache'ler
                        NSHomeDirectory() + "/Library/Caches/com.apple.mobileslideshow",
                        NSHomeDirectory() + "/Library/Caches/com.apple.Photos"
                    ]
                    
                    for path in photosSpecificPaths {
                        let size = self.calculateDirectorySize(at: path)
                        if size > 0 {
                            totalSize += size
                            print("📁 \(path): \(size.formatAsFileSize())")
                        }
                    }
                }
                
                print("📊 Photos App Storage Total: \(totalSize.formatAsFileSize())")
                
                // Hala 0 ise fallback kullan
                if totalSize == 0 {
                    print("⚠️ No Photos directories found, using PHAsset estimation...")
                    self.estimateFromPHAssets { estimatedSize in
                        continuation.resume(returning: estimatedSize)
                    }
                } else {
                    continuation.resume(returning: totalSize)
                }
            }
        }
    }
    
    private func getPhotosAppDataPath() -> String? {
        let bundleId = "com.apple.mobileslideshow"
        let systemPaths = [
            "/private/var/mobile/Containers/Data/Application",
            "/var/mobile/Containers/Data/Application"
        ]
        
        for systemPath in systemPaths {
            if let photosPath = self.findPhotosContainer(in: systemPath, bundleId: bundleId) {
                return photosPath
            }
        }
        
        return nil
    }
    
    /// Photos container'ını belirli bir system path içinde ara
    private func findPhotosContainer(in systemPath: String, bundleId: String) -> String? {
        guard FileManager.default.fileExists(atPath: systemPath) else {
            return nil
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: systemPath)
            
            for containerDir in contents {
                let containerPath = (systemPath as NSString).appendingPathComponent(containerDir)
                let plistPath = (containerPath as NSString).appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
                
                // Container'ın bundle ID'sini kontrol et
                if FileManager.default.fileExists(atPath: plistPath) {
                    if let plistData = NSDictionary(contentsOfFile: plistPath),
                       let identifier = plistData["MCMMetadataIdentifier"] as? String,
                       identifier == bundleId {
                        return (containerPath as NSString).appendingPathComponent("Documents")
                    }
                }
            }
        } catch {
            print("❌ Cannot search in \(systemPath): \(error)")
        }
        
        return nil
    }
    
    /// PHAsset ile estimation (sadece yerel fotoğraflar)
    private func estimateFromPHAssets(completion: @escaping (Int64) -> Void) {
        print("📊 Estimating from local PHAssets...")
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        fetchOptions.fetchLimit = 20  // Daha az sample (hız için)
        
        let sampleAssets = PHAsset.fetchAssets(with: fetchOptions)
        var sampleSize: Int64 = 0
        var localCount = 0
        let group = DispatchGroup()
        
        for i in 0..<min(sampleAssets.count, 20) {
            group.enter()
            let asset = sampleAssets.object(at: i)
            
            self.getLocalAssetSize(for: asset) { size in
                if size > 0 {
                    sampleSize += size
                    localCount += 1
                }
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.global()) {
            if localCount > 0 {
                let avgSize = sampleSize / Int64(localCount)
                
                // Tüm yerel fotoğrafları say
                let allPhotos = PHAsset.fetchAssets(with: PHFetchOptions())
                let estimatedLocalCount = allPhotos.count / 3  // Kabaca 1/3'ü yerel olabilir
                let estimated = avgSize * Int64(estimatedLocalCount)
                
                print("📊 Estimation: \(localCount) local samples, avg \(avgSize.formatAsFileSize()), estimated total: \(estimated.formatAsFileSize())")
                completion(estimated)
            } else {
                print("❌ No local photos found in samples")
                completion(0)
            }
        }
    }
    
    /// Directory boyutunu recursive olarak hesapla
    private func calculateDirectorySize(at path: String) -> Int64 {
        guard FileManager.default.fileExists(atPath: path) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        do {
            // Directory attributes
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
            
            // Directory contents
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            
            for item in contents {
                let itemPath = (path as NSString).appendingPathComponent(item)
                
                do {
                    let itemAttributes = try FileManager.default.attributesOfItem(atPath: itemPath)
                    
                    if let fileType = itemAttributes[.type] as? FileAttributeType {
                        if fileType == .typeDirectory {
                            // Recursive directory scan (max 2 levels deep)
                            if path.components(separatedBy: "/").count < 8 {
                                totalSize += calculateDirectorySize(at: itemPath)
                            }
                        } else if fileType == .typeRegular {
                            if let fileSize = itemAttributes[.size] as? Int64 {
                                totalSize += fileSize
                            }
                        }
                    }
                } catch {
                    // Permission denied veya diğer hatalar - skip
                    continue
                }
            }
            
        } catch {
            print("❌ Cannot access directory \(path): \(error.localizedDescription)")
            return 0
        }
        
        return totalSize
    }
    
    /// Photos app group container path'ini bul
    private func getPhotosGroupContainerPath() -> String? {
        // System group containers
        let possibleGroups = [
            "group.com.apple.photos",
            "group.com.apple.Photos",
            "group.com.apple.mobileslideshow"
        ]
        
        for groupId in possibleGroups {
            if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) {
                return containerURL.path
            }
        }
        
        return nil
    }
    
    /// Fallback: System API'lerinden Photos app storage bilgisini al - SİLİNDİ
    /// getPhotosAppStorageFromSystem metodu artık gerekli değil
    
    /// Tek bir asset'in YEREL boyutunu hesapla (fallback için)
    private func getLocalAssetSize(for asset: PHAsset, completion: @escaping (Int64) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false  // Sadece yerel
        options.isSynchronous = false
        
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
            guard let imageData = data else {
                completion(0)  // iCloud'daki için 0
                return
            }
            
            let size = Int64(imageData.count)
            completion(size)
        }
    }
}

// MARK: - Testing & Debug Helpers

extension StorageManager {
    
    /// Test için storage bilgilerini logla
    func debugStorageInfo() {
        print("""
        📊 STORAGE DEBUG INFO:
        ├── Total Library: \(formattedTotalSize)
        ├── Current Library: \(formattedCurrentSize)
        ├── Session Deleted: \(formattedSessionDeleted)
        ├── Lifetime Deleted: \(formattedLifetimeDeleted)
        ├── Deletion %: \(String(format: "%.1f", deletionPercentage))%
        └── Loading: \(isLoadingStorage)
        """)
    }
    
    /// Manually reset stats (test için)
    func resetStats() {
        sessionDeleted = 0
        lifetimeDeleted = 0
        currentLibrarySize = totalLibrarySize
        print("🔄 Storage stats reset")
    }
}
