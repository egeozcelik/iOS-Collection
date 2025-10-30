//
//  PermissionManager.swift
//  Memoerase
//
//  Created by Ege on 5.07.2025.
//

import Photos
import SwiftUI

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var hasFullAccess: Bool = false
    
    private init() {
        checkCurrentStatus()
    }
    
    func checkCurrentStatus() {
        DispatchQueue.main.async {
            if #available(iOS 14, *) {
                self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                self.hasFullAccess = self.authorizationStatus == .authorized
            } else {
                self.authorizationStatus = PHPhotoLibrary.authorizationStatus()
                self.hasFullAccess = self.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        print("🔐 Requesting photo library permission...")
        
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    self.authorizationStatus = status
                    self.hasFullAccess = status == .authorized
                    
                    let granted = status == .authorized || status == .limited
                    print("📸 Permission result: \(status.description) - Granted: \(granted)")
                    completion(granted)
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.authorizationStatus = status
                    self.hasFullAccess = status == .authorized
                    
                    let granted = status == .authorized
                    print("📸 Permission result: \(status.description) - Granted: \(granted)")
                    completion(granted)
                }
            }
        }
    }
    
    var needsPermission: Bool {
        return authorizationStatus == .notDetermined || authorizationStatus == .denied
    }
    
    var isDenied: Bool {
        return authorizationStatus == .denied || authorizationStatus == .restricted
    }
    
    var isLimited: Bool {
        if #available(iOS 14, *) {
            return authorizationStatus == .limited
        }
        return false
    }
    
    var statusMessage: String {
        switch authorizationStatus {
        case .authorized:
            return "Full access granted"
        case .limited:
            return "Limited access granted"
        case .denied:
            return "Access denied"
        case .restricted:
            return "Access restricted"
        case .notDetermined:
            return "Permission not requested"
        @unknown default:
            return "Unknown status"
        }
    }
}

// MARK: - PHAuthorizationStatus Extension
extension PHAuthorizationStatus {
    var description: String {
        switch self {
        case .authorized:
            return "Authorized"
        case .limited:
            return "Limited"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not Determined"
        @unknown default:
            return "Unknown"
        }
    }
}
