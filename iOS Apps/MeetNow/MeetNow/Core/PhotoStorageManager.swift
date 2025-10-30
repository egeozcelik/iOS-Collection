//
//  PhotoStorageManager.swift
//  MeetNow
//
//  Created by Ege Özçelik on 18.08.2025.
//

import Foundation
import FirebaseStorage
import UIKit
import Photos

class StorageManager {
    static let shared = StorageManager()
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Profile Image Upload
    func uploadProfileImage(
        _ image: UIImage,
        userId: String,
        completion: @escaping (Result<String, StorageError>) -> Void
    ) {
        // 1. Image'i compress et
        guard let imageData = compressImage(image) else {
            completion(.failure(.compressionFailed))
            return
        }
        
        // 2. Storage reference oluştur
        let fileName = "profile_\(userId)_\(Int(Date().timeIntervalSince1970)).jpg"
        let storageRef = storage.reference().child("profile_images/\(fileName)")
        
        // 3. Metadata tanımla
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "userId": userId,
            "uploadDate": ISO8601DateFormatter().string(from: Date())
        ]
        
        print("📤 Profile image upload başlıyor: \(fileName)")
        
        // 4. Upload task oluştur
        let uploadTask = storageRef.putData(imageData, metadata: metadata) { [weak self] metadata, error in
            if let error = error {
                print("❌ Upload error: \(error.localizedDescription)")
                completion(.failure(.uploadFailed(error.localizedDescription)))
                return
            }
            
            print("✅ Upload completed, getting download URL...")
            
            // 5. Download URL al
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Download URL error: \(error.localizedDescription)")
                    completion(.failure(.downloadURLFailed(error.localizedDescription)))
                    return
                }
                
                guard let downloadURL = url?.absoluteString else {
                    completion(.failure(.downloadURLFailed("URL nil")))
                    return
                }
                
                print("🎉 Profile image uploaded successfully: \(downloadURL)")
                completion(.success(downloadURL))
            }
        }
        
        // 6. Upload progress tracking (opsiyonel)
        uploadTask.observe(.progress) { snapshot in
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("📊 Upload progress: \(percentComplete)%")
        }
    }
    
    // MARK: - Event Image Upload
    func uploadEventImage(
        _ image: UIImage,
        eventId: String,
        completion: @escaping (Result<String, StorageError>) -> Void
    ) {
        guard let imageData = compressImage(image) else {
            completion(.failure(.compressionFailed))
            return
        }
        
        let fileName = "event_\(eventId)_\(Int(Date().timeIntervalSince1970)).jpg"
        let storageRef = storage.reference().child("event_images/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "eventId": eventId,
            "uploadDate": ISO8601DateFormatter().string(from: Date())
        ]
        
        uploadTask(storageRef: storageRef, imageData: imageData, metadata: metadata, completion: completion)
    }
    
    // MARK: - Helper Functions
    private func compressImage(_ image: UIImage) -> Data? {
        // 1. Maksimum boyut kontrolü (1080x1080)
        let maxSize: CGFloat = 1080
        let resizedImage = image.resized(to: CGSize(width: maxSize, height: maxSize))
        
        // 2. JPEG compression (0.8 quality)
        guard let data = resizedImage.jpegData(compressionQuality: 0.8) else {
            print("❌ Image compression failed")
            return nil
        }
        
        // 3. Dosya boyutu kontrolü (max 5MB)
        let maxSizeInBytes = 5 * 1024 * 1024 // 5MB
        if data.count > maxSizeInBytes {
            // Daha fazla sıkıştır
            return resizedImage.jpegData(compressionQuality: 0.6)
        }
        
        print("✅ Image compressed: \(data.count) bytes")
        return data
    }
    
    private func uploadTask(
        storageRef: StorageReference,
        imageData: Data,
        metadata: StorageMetadata,
        completion: @escaping (Result<String, StorageError>) -> Void
    ) {
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(.uploadFailed(error.localizedDescription)))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(.downloadURLFailed(error.localizedDescription)))
                    return
                }
                
                guard let downloadURL = url?.absoluteString else {
                    completion(.failure(.downloadURLFailed("URL nil")))
                    return
                }
                
                completion(.success(downloadURL))
            }
        }
    }
    
    func deleteProfileImage(url: String, completion: @escaping (Bool) -> Void) {
        guard !url.isEmpty,
              url.contains("firebasestorage.googleapis.com") else {
            print("🔄 URL is empty or not Firebase Storage, skipping deletion")
            completion(true)
            return
        }
        
        // URL'den filename çıkar
        let components = url.components(separatedBy: "/")
        guard let filename = components.last?.components(separatedBy: "?").first else {
            print("❌ Could not extract filename from URL")
            completion(false)
            return
        }
        
        // Filename decode et
        guard let decodedFilename = filename.removingPercentEncoding else {
            print("❌ Could not decode filename")
            completion(false)
            return
        }
        
        // Storage reference oluştur
        let storageRef = storage.reference().child("profile_images/\(decodedFilename)")
        
        storageRef.delete { error in
            if let error = error {
                print("❌ Delete error: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Image deleted successfully: \(decodedFilename)")
                completion(true)
            }
        }
    }
}

// MARK: - Storage Errors
enum StorageError: LocalizedError {
    case compressionFailed
    case uploadFailed(String)
    case downloadURLFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Fotoğraf sıkıştırılamadı"
        case .uploadFailed(let message):
            return "Upload hatası: \(message)"
        case .downloadURLFailed(let message):
            return "URL alma hatası: \(message)"
        }
    }
}


extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Aspect ratio koruyarak resize
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? self
    }
    
    func resizedToFill(targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = max(widthRatio, heightRatio)
        
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let scaledImage = renderer.image { _ in
            let origin = CGPoint(
                x: (targetSize.width - scaledImageSize.width) / 2.0,
                y: (targetSize.height - scaledImageSize.height) / 2.0
            )
            self.draw(in: CGRect(origin: origin, size: scaledImageSize))
        }
        
        return scaledImage
    }
}



class PhotoPermissionManager {
    static func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    static func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
}
