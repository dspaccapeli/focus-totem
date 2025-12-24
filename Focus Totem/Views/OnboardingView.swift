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
    
    // Page indices
    private enum Page {
        static let welcome = 0
        static let explanation = 1
        static let cameraPermission = 2
        static let totemScanning = 3
        static let notificationPermission = 4
    }

    private let pageCount = 5
    
    @State private var currentPage = Page.welcome
    @State private var cameraPermissionGranted = false
    @State private var totemCaptured = false
    @State private var notificationPermissionGranted = false
    @State private var isScanning = false
    @State private var isLoading = false
    @State private var showTotemScanner = false
        
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
                        .opacity(currentPage == Page.welcome ? 1 : 0)
                        .offset(x: currentPage == Page.welcome ? 0 : (currentPage < Page.welcome ? screenWidth : -screenWidth))
                    
                    ExplanationPageView()
                        .opacity(currentPage == Page.explanation ? 1 : 0)
                        .offset(x: currentPage == Page.explanation ? 0 : (currentPage < Page.explanation ? screenWidth : -screenWidth))
                    
                    CameraPermissionPageView(cameraPermissionGranted: $cameraPermissionGranted)
                        .opacity(currentPage == Page.cameraPermission ? 1 : 0)
                        .offset(x: currentPage == Page.cameraPermission ? 0 : (currentPage < Page.cameraPermission ? screenWidth : -screenWidth))
                        .onChange(of: cameraPermissionGranted) { oldValue, newValue in
                            // Only advance if we're on the camera permission page AND permission was just granted
                            if currentPage == Page.cameraPermission && !oldValue && newValue {
                                // Permission was just granted, advance to next page
                                advanceToScannerPage()
                            }
                        }
                    
                    // Only initialize TotemScanningPageView when needed
                    if showTotemScanner {
                        TotemScanningPageView(
                            isScanning: $isScanning,
                            totemCaptured: $totemCaptured,
                            isLoading: $isLoading
                        )
                        .modelContext(modelContext)
                        .opacity(currentPage == Page.totemScanning ? 1 : 0)
                        .offset(x: currentPage == Page.totemScanning ? 0 : (currentPage < Page.totemScanning ? screenWidth : -screenWidth))
                    } else if currentPage == Page.totemScanning {
                        // Placeholder for when the scanner should be visible but isn't loaded yet
                        VStack {
                            ProgressView("Loading scanner...")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    NotificationPermissionPageView(
                        notificationPermissionGranted: $notificationPermissionGranted,
                        onSkip: {
                            // Save onboarding completion status to UserDefaults
                            UserDefaults.standard.set(true, forKey: "onboardingCompleted")

                            // Store the completion date
                            UserDefaults.standard.set(Date(), forKey: "onboardingCompletionDate")

                            // Complete onboarding
                            hasCompletedOnboarding = true
                        }
                    )
                    .opacity(currentPage == Page.notificationPermission ? 1 : 0)
                    .offset(x: currentPage == Page.notificationPermission ? 0 : (currentPage < Page.notificationPermission ? screenWidth : -screenWidth))
                }
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Navigation controls
                HStack(alignment: .center) {
                    // Back button (hidden on first page)
                    Button(action: {
                        if currentPage > Page.welcome {
                            if currentPage == Page.totemScanning {
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
                        .opacity(currentPage == Page.welcome ? 0 : 1)
                    }
                    .disabled(currentPage == Page.welcome)
                    
                    Spacer()

                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pageCount, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }

                    Spacer()
                    
                    // Next/Done button
                    Button(action: {
                        if currentPage == Page.welcome || currentPage == Page.explanation {
                            withAnimation {
                                currentPage += 1
                            }
                        } else if currentPage == Page.cameraPermission && cameraPermissionGranted {
                            // First show loading state
                            isLoading = true

                            withAnimation {
                                currentPage = Page.totemScanning
                            }

                            // Initialize the scanner view and start scanning after a slight delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showTotemScanner = true

                                // Give a little more time for the view to initialize before starting scanning
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isScanning = true
                                    isLoading = false
                                }
                            }
                        } else if currentPage == Page.totemScanning && totemCaptured {
                            withAnimation {
                                currentPage = Page.notificationPermission
                            }
                        } else if currentPage == Page.notificationPermission {
                            // Save onboarding completion status to UserDefaults
                            UserDefaults.standard.set(true, forKey: "onboardingCompleted")

                            // Store the completion date
                            UserDefaults.standard.set(Date(), forKey: "onboardingCompletionDate")

                            // Complete onboarding
                            hasCompletedOnboarding = true
                        }
                    }) {
                        HStack {
                            Text(currentPage < Page.notificationPermission ? "Next" : "Done")
                            if (totemCaptured && currentPage == Page.totemScanning) || currentPage < Page.totemScanning || currentPage == Page.notificationPermission {
                                Image(systemName: currentPage < Page.notificationPermission ? "chevron.right" : "checkmark")
                                    .font(.body)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            (currentPage == Page.cameraPermission && !cameraPermissionGranted) ||
                            (currentPage == Page.totemScanning && !totemCaptured) || isLoading ?
                            Color.gray : Color.blue
                        )
                        .cornerRadius(10)
                    }
                    .disabled((currentPage == Page.cameraPermission && !cameraPermissionGranted) ||
                              (currentPage == Page.totemScanning && !totemCaptured) || isLoading)
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
        .onDisappear {
            // Ensure camera is stopped when view disappears
            isScanning = false
        }
    }
    
    private func advanceToScannerPage() {
        // First show loading state
        isLoading = true
        
        withAnimation {
            currentPage = Page.totemScanning
        }
        
        // Initialize the scanner view and start scanning after a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showTotemScanner = true
            
            // Give a little more time for the view to initialize before starting scanning
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isScanning = true
                isLoading = false
            }
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
