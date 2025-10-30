//
//  PhotoBatchManager.swift
//  Memoerase
//
//  Lazy Photo Loading Sistemi - 10K fotoğraf için performans optimizasyonu
//

import Photos
import Foundation
import Combine

@MainActor
class PhotoBatchManager: ObservableObject {
    static let shared = PhotoBatchManager()
    
    // MARK: - Constants
    private let BATCH_SIZE = 30
    private let PRELOAD_THRESHOLD = 5  // 5 foto kala sonraki batch'i yükle
    private let MEMORY_LIMIT = 100     // Max 100 foto memory'de tut
    
    // MARK: - Loading Strategy
    enum LoadingStrategy {
        case random           // Her batch karışık
        case chronological    // Sıralı yükleme
        case smartRandom     // Akıllı karışık (default)
    }
    
    private var loadingStrategy: LoadingStrategy = .smartRandom
    
    // MARK: - Published Properties
    @Published var isInitialLoading = true
    @Published var totalPhotoCount = 0
    @Published var loadedBatches = 0
    @Published var currentBatchIndex = 0
    
    // MARK: - Private Properties
    private var allAssetRefs: [PHAsset] = []  // Sadece asset referansları
    private var loadedPhotos: [String: Photo] = [:]  // ID -> Photo cache
    private var currentPhotoQueue: [Photo] = []  // Aktif foto sırası
    private var isLoadingBatch = false
    private var loadingTask: Task<Void, Never>?
    
    // Managers
    private let permissionManager = PermissionManager.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// İlk yükleme: Hızlıca asset'leri index'le ve ilk batch'i yükle
    func quickStart() async {
        guard permissionManager.hasFullAccess else {
            print("❌ No photo library access")
            return
        }
        
        print("⚡ Quick Start: Asset indexing başlıyor...")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Phase 1: Hızlı asset indexing (UI için sayı hesabı)
        await indexAllAssets()
        
        let indexTime = CFAbsoluteTimeGetCurrent()
        print("📊 Asset indexing: \(String(format: "%.2f", indexTime - startTime))s - \(totalPhotoCount) photos")
        
        // Phase 2: İlk batch'i KESINLIKLE yükle
        if totalPhotoCount > 0 {
            await loadNextBatch()
            print("✅ Quick start - İlk batch yüklendi: \(currentPhotoQueue.count) photos ready")
        } else {
            print("❌ No photos found in library")
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent()
        print("🎯 Quick start tamamlandı: \(String(format: "%.2f", totalTime - startTime))s")
        
        isInitialLoading = false
    }
    
    /// Sonraki fotoğrafı al (lazy loading ile)
    func getNextPhoto(for filterMode: FilterMode) async -> Photo? {
        // Mevcut queue'dan al
        if !currentPhotoQueue.isEmpty {
            let photo = currentPhotoQueue.removeFirst()
            
            print("📷 Photo taken from queue: \(photo.id.prefix(8)) - Queue remaining: \(currentPhotoQueue.count)")
            
            // Preload threshold'una yaklaştıysak sonraki batch'i yükle
            if currentPhotoQueue.count <= PRELOAD_THRESHOLD && !isLoadingBatch {
                Task {
                    await loadNextBatch()
                }
            }
            
            return photo
        }
        
        // Queue boşsa yeni batch yükle
        await loadNextBatch()
        
        if !currentPhotoQueue.isEmpty {
            let photo = currentPhotoQueue.removeFirst()
            print("📷 Photo taken from new batch: \(photo.id.prefix(8))")
            return photo
        }
        
        return nil
    }
    
    /// Mevcut fotoğrafı skip et (queue'dan kaldırmadan sonrakini al) - YENİ
    func skipCurrentPhoto(currentPhotoId: String, for filterMode: FilterMode) async -> Photo? {
        print("⏭️ Skipping photo: \(currentPhotoId.prefix(8))")
        
        // Mevcut fotoğraf queue'da mı kontrol et
        if let currentIndex = currentPhotoQueue.firstIndex(where: { $0.id == currentPhotoId }) {
            // Queue'dan kaldır
            currentPhotoQueue.remove(at: currentIndex)
            print("🗑️ Removed skipped photo from queue")
        }
        
        // Cache'den de kaldır (memory temizliği için)
        loadedPhotos.removeValue(forKey: currentPhotoId)
        
        // Sonraki fotoğrafı al
        return await getNextPhoto(for: filterMode)
    }
    
    /// Fotoğraf silindi - cache'den kaldır ve senkronizasyonu koru
    func photoDeleted(_ photo: Photo) {
        print("🗑️ BatchManager: Removing photo \(photo.id.prefix(8)) from cache")
        
        // Cache'den kaldır
        loadedPhotos.removeValue(forKey: photo.id)
        
        // Asset listesinden kaldır
        allAssetRefs.removeAll { $0.localIdentifier == photo.id }
        totalPhotoCount -= 1
        
        // Queue'dan da kaldır (eğer henüz gösterilmediyse)
        currentPhotoQueue.removeAll { $0.id == photo.id }
        
        print("✅ Photo removed from all caches. Remaining: \(totalPhotoCount) total, \(currentPhotoQueue.count) in queue")
    }
    
    /// Filter değişti - queue'yu yeniden oluştur
    func applyFilter(_ filterMode: FilterMode) async {
        print("🔄 Filter uygulanıyor: \(filterMode.rawValue)")
        
        currentPhotoQueue.removeAll()
        currentBatchIndex = 0
        
        // İlk batch'i yeni filter ile yükle
        await loadNextBatch(with: filterMode)
    }
    
    /// Loading strategy'yi değiştir ve yeniden başlat
    func setLoadingStrategy(_ strategy: LoadingStrategy) async {
        guard strategy != loadingStrategy else { return }
        
        loadingStrategy = strategy
        print("🔄 Loading strategy changed to: \(strategy)")
        
        // Reset ve yeniden başlat
        reset()
        await quickStart()
    }
    
    /// Debug info
    func getDebugInfo() -> String {
        let queueIds = currentPhotoQueue.prefix(3).map { $0.id.prefix(8) }.joined(separator: ", ")
        return """
        📊 BATCH MANAGER DEBUG:
        ├── Total Assets: \(totalPhotoCount)
        ├── Loaded Batches: \(loadedBatches)
        ├── Cache Size: \(loadedPhotos.count)
        ├── Queue Size: \(currentPhotoQueue.count)
        ├── Queue Preview: [\(queueIds)...]
        ├── Current Batch Index: \(currentBatchIndex)
        ├── Loading Strategy: \(loadingStrategy)
        └── Loading: \(isLoadingBatch)
        """
    }
    
    // MARK: - Private Methods
    
    /// Tüm asset'leri hızlıca index'le (metadata yükleme)
    private func indexAllAssets() async {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                
                let assets = PHAsset.fetchAssets(with: fetchOptions)
                var assetRefs: [PHAsset] = []
                
                // Sadece asset referanslarını topla (metadata yükleme değil)
                assets.enumerateObjects { asset, _, _ in
                    assetRefs.append(asset)
                }
                
                // 🎲 LOADING STRATEGY'ye göre karıştır
                switch self.loadingStrategy {
                case .random, .smartRandom:
                    assetRefs.shuffle()
                    print("🎲 \(assetRefs.count) photos shuffled randomly")
                case .chronological:
                    print("📅 \(assetRefs.count) photos in chronological order")
                }
                
                DispatchQueue.main.async {
                    self.allAssetRefs = assetRefs
                    self.totalPhotoCount = assetRefs.count
                    continuation.resume()
                }
            }
        }
    }
    
    /// Sonraki batch'i yükle
    private func loadNextBatch(with filterMode: FilterMode = .random) async {
        guard !isLoadingBatch else { return }
        guard currentBatchIndex * BATCH_SIZE < allAssetRefs.count else {
            print("📝 Tüm batch'ler yüklendi")
            return
        }
        
        isLoadingBatch = true
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let startIndex = self.currentBatchIndex * self.BATCH_SIZE
                let endIndex = min(startIndex + self.BATCH_SIZE, self.allAssetRefs.count)
                
                let batchAssets = Array(self.allAssetRefs[startIndex..<endIndex])
                var batchPhotos: [Photo] = []
                
                print("📦 Batch \(self.currentBatchIndex) yükleniyor: \(startIndex)-\(endIndex)")
                
                // Photo objelerini oluştur
                for asset in batchAssets {
                    let photo = Photo(asset: asset)
                    batchPhotos.append(photo)
                    
                    // Cache'e ekle
                    DispatchQueue.main.async {
                        self.loadedPhotos[photo.id] = photo
                    }
                }
                
                // Filter uygula
                let filteredPhotos = self.applyFilterToBatch(batchPhotos, filterMode: filterMode)
                
                DispatchQueue.main.async {
                    // Queue'ya ekle
                    self.currentPhotoQueue.append(contentsOf: filteredPhotos)
                    
                    self.currentBatchIndex += 1
                    self.loadedBatches += 1
                    self.isLoadingBatch = false
                    
                    // Memory temizliği
                    self.cleanupMemoryIfNeeded()
                    
                    print("✅ Batch \(self.currentBatchIndex - 1) yüklendi: \(filteredPhotos.count) photos")
                    continuation.resume()
                }
            }
        }
    }
    
    /// Batch'e filter uygula
    private func applyFilterToBatch(_ photos: [Photo], filterMode: FilterMode) -> [Photo] {
        switch filterMode {
        case .random:
            return photos.shuffled()  // Her batch'i ayrıca karıştır
            
        case .oldestFirst:
            return photos.sorted {
                ($0.creationDate ?? Date.distantPast) < ($1.creationDate ?? Date.distantPast)
            }
            
        case .newestFirst:
            return photos.sorted {
                ($0.creationDate ?? Date.distantFuture) > ($1.creationDate ?? Date.distantFuture)
            }
        }
    }
    
    /// Memory temizliği (cache çok büyürse)
    private func cleanupMemoryIfNeeded() {
        guard loadedPhotos.count > MEMORY_LIMIT else { return }
        
        let excessCount = loadedPhotos.count - MEMORY_LIMIT
        let keysToRemove = Array(loadedPhotos.keys.prefix(excessCount))
        
        for key in keysToRemove {
            loadedPhotos.removeValue(forKey: key)
        }
        
        print("🧹 Memory cleanup: \(excessCount) photos removed from cache")
    }
    
    /// Reset everything
    func reset() {
        loadingTask?.cancel()
        allAssetRefs.removeAll()
        loadedPhotos.removeAll()
        currentPhotoQueue.removeAll()
        totalPhotoCount = 0
        loadedBatches = 0
        currentBatchIndex = 0
        isLoadingBatch = false
        isInitialLoading = true
    }
}

// MARK: - Batch Loading Extensions

extension PhotoBatchManager {
    
    /// Belirli bir foto ID'sini cache'den al
    func getCachedPhoto(id: String) -> Photo? {
        return loadedPhotos[id]
    }
    
    /// Queue durumunu kontrol et
    var hasMorePhotos: Bool {
        let hasQueuedPhotos = !currentPhotoQueue.isEmpty
        let hasMoreBatches = currentBatchIndex * BATCH_SIZE < allAssetRefs.count
        
        let result = hasQueuedPhotos || hasMoreBatches
        print("📊 hasMorePhotos: \(result) (Queue: \(currentPhotoQueue.count), More batches: \(hasMoreBatches))")
        return result
    }
    
    /// Yüklenen foto yüzdesi
    var loadingProgress: Double {
        guard totalPhotoCount > 0 else { return 0 }
        let loadedCount = loadedBatches * BATCH_SIZE
        return min(Double(loadedCount) / Double(totalPhotoCount), 1.0)
    }
    
    /// Preload bir sonraki batch'i (kullanıcı hızlı swipe yapıyorsa)
    func preloadNextBatch() {
        guard !isLoadingBatch else { return }
        
        Task {
            await loadNextBatch()
        }
    }
}
