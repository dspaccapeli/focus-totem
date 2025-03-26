//
//  Focus_TotemApp.swift
//  Focus Totem
//
//  Created by Daniele Spaccapeli on 18/03/25.
//

import SwiftUI
import SwiftData
import AVFoundation
import FamilyControls

@main
struct Focus_TotemApp: App {
    @State private var sharedModelContainer: ModelContainer?
    @State private var hasCompletedOnboarding = false
    @StateObject private var permissionsManager = PermissionsManager.shared
    
    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer {
                Group {
                    if hasCompletedOnboarding {
                        ContentView()
                            .modelContainer(container)
                    } else {
                        OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                            .modelContainer(container)
                    }
                }
                .task {
                    // Check if onboarding has been fully completed
                    hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboardingCompleted")
                    
                    // Check permissions status at app launch
                    Task {
                        await permissionsManager.checkCameraPermission()
                        await permissionsManager.checkScreenTimePermission()
                    }
                }
            } else {
                ProgressView("Loading...")
                    .onAppear {
                        Task {
                            await setupModelContainer()
                        }
                    }
            }
        }
    }
    
    private func setupModelContainer() async {
        let schema = Schema([
            ProfileModel.self,
            SessionsStatsModel.self,
            TotemModel.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            // Create the container on a background thread
            let container = try await Task.detached(priority: .userInitiated) {
                try ModelContainer(for: schema, configurations: [modelConfiguration])
            }.value
            
            // Update the state on the main thread
            await MainActor.run {
                self.sharedModelContainer = container
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
