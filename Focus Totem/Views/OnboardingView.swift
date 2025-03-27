//
//  OnboardingView.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 11/03/25.
//

import SwiftUI
import AVFoundation
import VisionKit
import SafariServices
import Vision

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var hasCompletedOnboarding: Bool
    @StateObject private var permissionsManager = PermissionsManager.shared
    @State private var currentPage = 0
    @State private var cameraPermissionGranted = false
    @State private var totemCaptured = false
    @State private var isScanning = false
    @State private var isLoading = false
        
    // Get screen width for dynamic offsets
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Content with custom transition
                ZStack {
                    // All views are in the hierarchy, but only the active one is visible
                    WelcomePageView()
                        .opacity(currentPage == 0 ? 1 : 0)
                        .offset(x: currentPage == 0 ? 0 : (currentPage < 0 ? screenWidth : -screenWidth))
                    
                    CameraPermissionPageView(cameraPermissionGranted: $cameraPermissionGranted)
                        .opacity(currentPage == 1 ? 1 : 0)
                        .offset(x: currentPage == 1 ? 0 : (currentPage < 1 ? screenWidth : -screenWidth))
                        .onChange(of: cameraPermissionGranted) { oldValue, newValue in
                            // Only advance if we're on the camera permission page AND permission was just granted
                            if currentPage == 1 && !oldValue && newValue {
                                // Permission was just granted, advance to next page
                                advanceToScannerPage()
                            }
                        }
                    
                    TotemScanningPageView(
                        isScanning: $isScanning,
                        totemCaptured: $totemCaptured,
                        isLoading: $isLoading
                    )
                    .modelContext(modelContext)
                    .opacity(currentPage == 2 ? 1 : 0)
                    .offset(x: currentPage == 2 ? 0 : (currentPage < 2 ? screenWidth : -screenWidth))
                }
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Navigation controls
                HStack(alignment: .center) {
                    // Back button (hidden on first page)
                    Button(action: {
                        if currentPage > 0 {
                            if currentPage == 2 {
                                isScanning = false
                            }
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.body)
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .opacity(currentPage == 0 ? 0 : 1)
                    }
                    .disabled(currentPage == 0)
                    
                    Spacer()

                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }

                    Spacer()
                    
                    // Next/Done button
                    Button(action: {
                        if currentPage == 0 {
                            withAnimation {
                                currentPage = 1
                            }
                        } else if currentPage == 1 && cameraPermissionGranted {
                            // First show loading state
                            isLoading = true
                            
                            withAnimation {
                                currentPage = 2
                            }
                            
                            // Start scanning after a slight delay to allow view transition
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isScanning = true
                                isLoading = false
                            }
                        } else if currentPage == 2 && totemCaptured {
                            // Save onboarding completion status to UserDefaults
                            UserDefaults.standard.set(true, forKey: "onboardingCompleted")
                            
                            // Store the completion date
                            UserDefaults.standard.set(Date(), forKey: "onboardingCompletionDate")
                            
                            // Complete onboarding
                            hasCompletedOnboarding = true
                        }
                    }) {
                        HStack {
                            Text(currentPage < 2 ? "Next" : "Done")
                            if totemCaptured || currentPage < 2 { 
                                Image(systemName: currentPage < 2 ? "chevron.right" : "checkmark")
                                    .font(.body)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            (currentPage == 1 && !cameraPermissionGranted) || 
                            (currentPage == 2 && !totemCaptured) || isLoading ? 
                            Color.gray : Color.blue
                        )
                        .cornerRadius(10)
                    }
                    .disabled((currentPage == 1 && !cameraPermissionGranted) || 
                              (currentPage == 2 && !totemCaptured) || isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            Task {
                await checkCameraPermission()
            }
        }
    }
    
    private func advanceToScannerPage() {
        // First show loading state
        isLoading = true
        
        withAnimation {
            currentPage = 2
        }
        
        // Start scanning after a slight delay to allow view transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isScanning = true
            isLoading = false
        }
    }
    
    private func checkCameraPermission() async {
        await permissionsManager.checkCameraPermission()
        await MainActor.run {
            cameraPermissionGranted = permissionsManager.cameraPermissionStatus == .authorized
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(hasCompletedOnboarding: .constant(false))
    }
}
