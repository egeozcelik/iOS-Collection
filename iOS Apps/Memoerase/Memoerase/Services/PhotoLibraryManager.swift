//
//  PhotoLibraryManager.swift
//  Memoerase
//
//  Created by Ege on 5.07.2025.
//

import Photos
import UIKit

class PhotoLibraryManager: ObservableObject {
    static let shared = PhotoLibraryManager()
    
    @Published var totalPhotos: Int = 0
    @Published var totalSize: Int64 = 0
    @Published var isLoading: Bool = false
    
    private init() {}
    
    // MARK: - Fetch Photos
    func fetchAllPhotos(completion: @escaping ([Photo]) -> Void) {
        guard PermissionManager.shared.hasFullAccess else {
            print("❌ No photo library access")
            completion([])
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            
            let assets = PHAsset.fetchAssets(with: fetchOptions)
            var photos: [Photo] = []
            var totalSizeCalculated: Int64 = 0
            
            assets.enumerateObjects { (asset, _, _) in
                let photo = Photo(asset: asset)
                photos.append(photo)
                totalSizeCalculated += photo.size
            }
            
            DispatchQueue.main.async {
                self.totalPhotos = photos.count
                self.totalSize = totalSizeCalculated
                self.isLoading = false
                
                print("📊 Loaded \(photos.count) photos, total size: \(totalSizeCalculated.formatAsFileSize())")
                completion(photos)
            }
        }
    }
    
    // MARK: - Delete Photo
    func deletePhoto(_ photo: Photo, completion: @escaping (Bool, Error?) -> Void) {
        guard PermissionManager.shared.hasFullAccess else {
            completion(false, PhotoLibraryError.noPermission)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([photo.asset] as NSArray)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Photo deleted successfully: \(photo.formattedSize)")
                    self.totalPhotos -= 1
                    self.totalSize -= photo.size
                } else {
                    print("❌ Failed to delete photo: \(error?.localizedDescription ?? "Unknown error")")
                }
                completion(success, error)
            }
        }
    }
    
    // MARK: - Load Image
    func loadImage(for photo: Photo, targetSize: CGSize = CGSize(width: 300, height: 400), completion: @escaping (UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        
        imageManager.requestImage(
            for: photo.asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: requestOptions
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    // MARK: - Utility Methods
    func calculateLibraryStats() -> (count: Int, size: String) {
        return (totalPhotos, totalSize.formatAsFileSize())
    }
    
    func refreshLibraryInfo() {
        fetchAllPhotos { photos in
            // We only need the count and size, photos array is discarded
            print("📊 Library refreshed: \(photos.count) photos")
        }
    }
}

// MARK: - Error Types
enum PhotoLibraryError: LocalizedError {
    case noPermission
    case deletionFailed
    case loadingFailed
    
    var errorDescription: String? {
        switch self {
        case .noPermission:
            return "No permission to access photo library"
        case .deletionFailed:
            return "Failed to delete photo"
        case .loadingFailed:
            return "Failed to load photos"
        }
    }
}
