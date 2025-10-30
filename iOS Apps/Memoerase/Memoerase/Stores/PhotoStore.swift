// PhotoStore.swift - Updated with BatchManager Integration
import SwiftUI
import Combine
import Photos

@MainActor
class PhotoStore: ObservableObject {
    static let shared = PhotoStore()
    
    // Published properties
    @Published var currentPhoto: Photo?
    @Published var filterMode: FilterMode = .random
    @Published var appStats: AppStats = AppStats.load()
    @Published var isInitialLoading: Bool = true
    @Published var isLoadingNextPhoto: Bool = false
    @Published var hasPermission: Bool = false
    
    // Batch manager - YENİ
    @Published var batchManager = PhotoBatchManager.shared
    
    // Private properties
    private var currentLoadingTask: Task<Void, Never>?
    
    // Managers
    private let photoLibraryManager = PhotoLibraryManager.shared
    private let permissionManager = PermissionManager.shared
    private let storageManager = StorageManager.shared
    
    private init() {
        setupBindings()
        checkPermissionAndLoadPhotos()
    }
    
    private func setupBindings() {
        // Permission status değişikliklerini dinle
        permissionManager.$hasFullAccess
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasAccess in
                self?.hasPermission = hasAccess
                if hasAccess {
                    self?.quickLoadPhotos()
                }
            }
            .store(in: &cancellables)
        
        // Batch manager loading state'ini dinle
        batchManager.$isInitialLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.isInitialLoading = isLoading
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Permission & Loading
    func checkPermissionAndLoadPhotos() {
        permissionManager.checkCurrentStatus()
        
        if permissionManager.hasFullAccess {
            quickLoadPhotos()
        } else if permissionManager.needsPermission {
            requestPermission()
        }
    }
    
    func requestPermission() {
        permissionManager.requestPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.quickLoadPhotos()
                } else {
                    print("❌ Photo permission denied")
                }
            }
        }
    }
    
    // MARK: - YENİ: Quick Loading System - DÜZELTME
    func quickLoadPhotos() {
        currentLoadingTask?.cancel()
        
        currentLoadingTask = Task {
            print("🚀 Quick photo loading başlıyor...")
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Batch manager ile hızlı başlangıç
            await batchManager.quickStart()
            
            // SADECE batch manager hazırsa ilk fotoğrafı yükle
            if batchManager.hasMorePhotos {
                await loadNextPhoto()
            } else {
                print("❌ No photos available after batch loading")
            }
            
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            print("⚡ Quick loading tamamlandı: \(String(format: "%.2f", totalTime))s")
            
            // Stats güncelle
            updateStats()
        }
    }
    
    // MARK: - Photo Navigation - GÜNCELLENDI
    func loadNextPhoto() async {
        guard !isLoadingNextPhoto else { return }
        isLoadingNextPhoto = true
        
        let nextPhoto = await batchManager.getNextPhoto(for: filterMode)
        
        currentPhoto = nextPhoto
        isLoadingNextPhoto = false
        
        if let photo = nextPhoto {
            print("📷 Next photo loaded: \(photo.id.prefix(8)) - \(photo.formattedDate) - \(photo.formattedSize)")
        } else {
            print("🏁 No more photos available")
        }
    }
    
    // MARK: - Filter Management - GÜNCELLENDI
    func changeFilterMode() {
        let allModes = FilterMode.allCases
        if let currentIndex = allModes.firstIndex(of: filterMode) {
            let nextIndex = (currentIndex + 1) % allModes.count
            filterMode = allModes[nextIndex]
            
            // Filter değiştiğinde batch manager'ı güncelle
            Task {
                await batchManager.applyFilter(filterMode)
                await loadNextPhoto()
            }
            
            print("🔄 Filter changed to: \(filterMode.rawValue)")
        }
    }
    
    // MARK: - Photo Deletion - GÜNCELLENDI
    func deleteCurrentPhoto(completion: @escaping (Bool) -> Void) {
        guard let photo = currentPhoto else {
            completion(false)
            return
        }
        
        print("🗑️ Attempting to delete photo: \(photo.formattedSize)")
        
        // Photo'nun gerçek boyutunu al
        getActualPhotoSize(for: photo) { [weak self] actualSize in
            guard let self = self else { return }
            
            // Photo'yu sil
            self.photoLibraryManager.deletePhoto(photo) { success, error in
                Task { @MainActor in
                    if success {
                        // StorageManager'ı güncelle
                        self.storageManager.recordPhotoDeletion(photoSize: actualSize)
                        
                        // Batch manager'dan kaldır
                        self.batchManager.photoDeleted(photo)
                        
                        // Local state'i güncelle
                        self.handleSuccessfulDeletion(photo)
                        
                        // Sonraki fotoğrafı yükle
                        await self.loadNextPhoto()
                        
                        completion(true)
                    } else {
                        print("❌ Deletion failed: \(error?.localizedDescription ?? "Unknown error")")
                        completion(false)
                    }
                }
            }
        }
    }
    
    // MARK: - Gerçek Photo Size Hesaplama
    private func getActualPhotoSize(for photo: Photo, completion: @escaping (Int64) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        // Asset resource'ları kontrol et
        let resources = PHAssetResource.assetResources(for: photo.asset)
        
        if let resource = resources.first {
            if let size = resource.value(forKey: "fileSize") as? Int64, size > 0 {
                completion(size)
                return
            }
        }
        
        // Fallback: Image data ile hesaplama
        PHImageManager.default().requestImageDataAndOrientation(for: photo.asset, options: options) { data, _, _, _ in
            let size = Int64(data?.count ?? 0)
            completion(size)
        }
    }
    
    private func handleSuccessfulDeletion(_ deletedPhoto: Photo) {
        // Update old stats (backward compatibility için)
        appStats.recordDeletion(size: deletedPhoto.size)
        appStats.save()
        
        print("✅ Photo deleted successfully")
    }
    
    // MARK: - Session Management
    func startNewSession() {
        appStats.startNewSession()
        appStats.save()
        
        // StorageManager'da session'ı sıfırla
        Task { @MainActor in
            storageManager.sessionDeleted = 0
        }
        
        print("🚀 New session started - Total sessions: \(appStats.sessionsCount)")
    }
    
    // MARK: - Stats Update - GÜNCELLENDI
    private func updateStats() {
        // Batch manager'dan gerçek sayıları al
        let totalCount = batchManager.totalPhotoCount
        let estimatedSize = Int64(totalCount) * 1024 * 1024 // 1MB average estimation
        
        appStats.updateLibraryInfo(size: estimatedSize, count: totalCount)
        appStats.save()
        
        print("📊 Stats updated: \(totalCount) photos")
    }
    
    // MARK: - Skip Photo (swipe right) - YENİ
    func skipCurrentPhoto() {
        Task { @MainActor in
            await loadNextPhoto()
        }
        print("⏭️ Photo skipped")
    }
    
    // MARK: - Error Handling
    @Published var lastError: String?
    
    private func handleError(_ error: Error, context: String) {
        lastError = "\(context): \(error.localizedDescription)"
        print("❌ \(context): \(error.localizedDescription)")
        
        // Auto-clear error after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.lastError = nil
        }
    }
    
    func clearError() {
        lastError = nil
    }
    
    // MARK: - Debug Helper
    func debugStatus() {
        Task { @MainActor in
            storageManager.debugStorageInfo()
            print(batchManager.getDebugInfo())
            print("""
            📱 PHOTOSTORE DEBUG:
            ├── Current photo: \(currentPhoto?.formattedSize ?? "none")
            ├── Filter mode: \(filterMode.rawValue)
            ├── Has permission: \(hasPermission)
            └── Initial loading: \(isInitialLoading)
            """)
        }
    }
    
    // MARK: - Computed Properties
    var hasPhotos: Bool {
        batchManager.hasMorePhotos
    }
    
    var photosRemaining: Int {
        batchManager.totalPhotoCount
    }
    
    var currentPhotoProgress: String {
        let loadedCount = batchManager.loadedBatches * 30 // BATCH_SIZE
        let progress = batchManager.loadingProgress * 100
        return "Loaded: \(loadedCount)/\(batchManager.totalPhotoCount) (\(String(format: "%.1f", progress))%)"
    }
    
    // MARK: - Backward Compatibility Properties
    var librarySize: String {
        return "0 bytes" // Deprecated
    }
    
    var deletedSize: String {
        return "0 bytes" // Deprecated
    }
    
    // MARK: - Legacy Methods (artık kullanılmıyor ama compatibility için)
    func loadPhotos() {
        quickLoadPhotos()
    }
    
    func applyCurrentFilter() {
        Task {
            await batchManager.applyFilter(filterMode)
        }
    }
}
