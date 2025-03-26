//
//  PermissionsManager.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 13/03/25.
//
// >> "Can we block apps?" (permissions)

import Foundation
import AVFoundation
import FamilyControls
import SwiftUI

/// A singleton manager class that handles all permission-related functionality
class PermissionsManager: ObservableObject {
    // MARK: - Singleton
    static let shared = PermissionsManager()
    
    // MARK: - Published Properties
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var screenTimePermissionStatus: FamilyControls.AuthorizationStatus = .notDetermined
    
    // MARK: - Initialization
    private init() {
        // Check initial permission statuses
        Task {
            await checkCameraPermission()
            await checkScreenTimePermission()
        }
    }
    
    // MARK: - Camera Permission Methods
    
    /// Check the current camera permission status
    /// - Returns: The current authorization status
    @MainActor
    func checkCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        self.cameraPermissionStatus = status
    }
    
    /// Request camera permission from the user
    /// - Returns: Boolean indicating if permission was granted
    func requestCameraPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            self.cameraPermissionStatus = granted ? .authorized : .denied
        }
        return granted
    }
    
    // MARK: - Screen Time Permission Methods
    
    /// Check the current Screen Time permission status
    @MainActor
    func checkScreenTimePermission() async {
        self.screenTimePermissionStatus = AuthorizationCenter.shared.authorizationStatus
    }
    
    /// Request Screen Time permission from the user
    /// - Returns: Boolean indicating if the request was successful
    func requestScreenTimePermission() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            await MainActor.run {
                self.screenTimePermissionStatus = AuthorizationCenter.shared.authorizationStatus
            }
            return screenTimePermissionStatus == .approved
        } catch {
            print("Failed to request Screen Time authorization: \(error.localizedDescription)")
            await MainActor.run {
                self.screenTimePermissionStatus = AuthorizationCenter.shared.authorizationStatus
            }
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if all required permissions are granted
    /// - Returns: Boolean indicating if all permissions are granted
    var areAllPermissionsGranted: Bool {
        return cameraPermissionStatus == .authorized &&
               screenTimePermissionStatus == .approved
    }
    
    /// Get a user-friendly description of missing permissions
    /// - Returns: Array of strings describing missing permissions
    func getMissingPermissionsDescriptions() -> [String] {
        var missingPermissions: [String] = []
        
        if cameraPermissionStatus != .authorized {
            missingPermissions.append("Camera access is required for QR code scanning")
        }
        
        if screenTimePermissionStatus != .approved {
            missingPermissions.append("Screen Time access is required to block distracting apps")
        }
        
        return missingPermissions
    }
}
