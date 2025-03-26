//
//  CameraPermissionPageView.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 14/03/25.
//

import SwiftUI

struct CameraPermissionPageView: View {
    @Binding var cameraPermissionGranted: Bool
    @State private var showSettingsAlert = false
    @State private var permissionDenied = false
    @StateObject private var permissionsManager = PermissionsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Camera Access Needed")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Deliberate needs camera access to scan stickers. This is how you'll control app blocking.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Mocked camera view
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.05))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 120))
                    .foregroundColor(Color.blue.opacity(0.2))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .padding(.vertical, 20)
            
            if permissionDenied {
                VStack {
                    Text("Camera access was denied.")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Please enable camera access in Settings to continue.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 30)
                    
                    Button(action: {
                        showSettingsAlert = true
                    }) {
                        HStack {
                            Image(systemName: "gear")
                                .font(.body)
                            Text("Open Settings")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.top, 10)
                    .alert(isPresented: $showSettingsAlert) {
                        Alert(
                            title: Text("Open Settings"),
                            message: Text("Would you like to open Settings to enable camera access?"),
                            primaryButton: .default(Text("Open Settings")) {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .padding(.bottom, 40)
            } else {
                Button(action: {
                    Task {
                        let granted = await permissionsManager.requestCameraPermission()
                        cameraPermissionGranted = granted
                        permissionDenied = !granted
                    }
                }) {
                    HStack {
                        Image(systemName: cameraPermissionGranted ? "checkmark.circle.fill" : "camera.fill")
                            .font(.body)
                        
                        Text(cameraPermissionGranted ? "Camera Access Granted" : "Allow Camera Access")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .opacity(cameraPermissionGranted ? 0.6 : 1.0)
                }
                .disabled(cameraPermissionGranted)
                .padding(.bottom, 40)
            }
            Spacer()
        }
        .padding(.horizontal, 30)
        .onAppear {
            // Check if permission is already granted
            Task {
                await permissionsManager.checkCameraPermission()
                cameraPermissionGranted = permissionsManager.cameraPermissionStatus == .authorized
                permissionDenied = permissionsManager.cameraPermissionStatus == .denied
            }
        }
    }
}
