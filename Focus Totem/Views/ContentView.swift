//
//  ContentView.swift
//  Focus Totem
//
//  Created by Daniele Spaccapeli on 11/03/25.
//

import SwiftUI
import AVFoundation
import VisionKit
import SwiftData
import FamilyControls
import Vision

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stats: [SessionsStatsModel]
    @Query(filter: #Predicate<TotemModel> { totem in
        totem.isActive == true
    }) private var activeTotem: [TotemModel]

    // Constants
    private static let defaultProfileName = "Default Profile"
    // Similarity threshold for triggering blocking/unblocking
    private let similarityThreshold: Double = 0.3
    // Create a temporary ModelContainer for initialization
    private static let tempContainer = try! ModelContainer(for: ProfileModel.self, SessionsStatsModel.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    // Debounce time in seconds to prevent rapid toggling of blocking state
    private static let blockingDebounceTime: TimeInterval = 1.5
    
    @StateObject private var permissionsManager = PermissionsManager.shared
    @StateObject private var screenTimeManager = ScreenTimeManager(
        modelContext: tempContainer.mainContext,
        defaultProfileName: defaultProfileName
    )
    
    @State private var isTimerInitialized = false
    @State private var blockingStartTime: Date?
    @State private var lastSimilarityScore: Double = 0.0
    @State private var similarityScoreText: String = "No totem detected yet"
    @State private var timer: Timer?
    
    @State private var currentElapsedTime: TimeInterval = 0
    @State private var lastScanTime: Date?

    @State private var showingAuthorizationError = false
    @State private var showingSetupError = false

    @State private var showingSettingsView = false
    @State private var showingProfileSelection = false
    @State private var showingFamilyPicker = false
    @State private var showingProfilesView = false
    
    // States for totem registration
    @State private var showingTotemRegistration = false
    @State private var isTotemScanningActive = false
    @State private var totemCaptured = false
    @State private var isTotemScanningLoading = false

    // Add a state variable to force camera refresh
    @State private var forceRefreshCamera = false

    // Add a counter to force ImageSimilarityScanner to rebuild
    @State private var scannerRefreshCounter = 0

    // Computed property to determine scanning state
    private var isScanning: Bool {
        // Only scan if:
        // 1. Camera permission is authorized
        // 2. Screen Time permission is approved
        // 3. No modal sheets are being presented
        // 4. There is an active totem
        return permissionsManager.cameraPermissionStatus == .authorized &&
               permissionsManager.screenTimePermissionStatus == .approved &&
               !showingFamilyPicker &&
               !showingProfilesView &&
               !showingAuthorizationError &&
               screenTimeManager.activeProfile?.hasTokens ?? false &&
               !activeTotem.isEmpty &&
               !forceRefreshCamera // Add this condition to control camera state
    }
    
    // Computed properties for Default Profile
    private var defaultProfile: ProfileModel? {
        screenTimeManager.profiles.first { $0.name == Self.defaultProfileName }
    }
    
    // Computed property to access the single stats object
    private var statsObject: SessionsStatsModel? {
        stats.first
    }
    
    // Computed property to get the current active totem
    private var currentTotem: TotemModel? {
        activeTotem.first
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                // App header
                AppHeader(showImage: currentTotem != nil)
                .padding(.bottom, 60)
                
                if !screenTimeManager.isSetupComplete {
                    // Show loading indicator while setup is in progress
                    ProgressView("Setting up profiles...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let setupError = screenTimeManager.setupError {
                    // Show error view if setup failed
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Setup Error")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("There was a problem setting up your profiles: \(setupError.localizedDescription)")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            Task {
                                try? await screenTimeManager.setup()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .padding()
                } else if currentTotem == nil {
                    // Show message when no active totem is available
                    VStack(spacing: 16) {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("No Active Totem")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Please set up a totem in the settings to use for focus mode")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    // Image Similarity Scanner View with Totem Thumbnail
                    ZStack {
                        // Image Similarity Scanner (centered)
                        ImageSimilarityScanner(
                            isScanning: isScanning,
                            similarityScore: $lastSimilarityScore,
                            referenceFeaturePrints: currentTotem?.getFeaturePrints() ?? [],
                            threshold: similarityThreshold,
                            captureFrequency: 0.5,
                            onInvalidMatch: {
                                // Handle invalid match
                                similarityScoreText = "Similarity too low"
                            },
                            onValidMatch: { score in
                                // Handle valid match
                                handleValidSimilarityMatch(score)
                            }
                        )
                        .id("scanner_\(scannerRefreshCounter)") // Force rebuild when counter changes
                        .frame(width: 200, height: 200)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .inset(by: -4)
                                .stroke(screenTimeManager.isBlocking ? .red : .blue,
                                    lineWidth: screenTimeManager.isBlocking ? 6 : 3)
                        )
                        .overlay(
                            ZStack {
                                if screenTimeManager.hasSelection {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 120))
                                        .foregroundColor(screenTimeManager.isBlocking ?
                                            .red.opacity(0.2) : .blue.opacity(0.2))
                                } else if permissionsManager.screenTimePermissionStatus == .approved {
                                    RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    Image(systemName: "apps.iphone")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                        .symbolEffect(.wiggle, options: .speed(0.1) .nonRepeating, isActive: true)
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    Image(systemName: "hourglass")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                        .symbolEffect(.wiggle, options: .speed(0.1) .nonRepeating, isActive: true)
                                }
                            }
                        )
                        
                        // Totem Thumbnail (overlapping on the right)
                        if let totem = currentTotem, let thumbnail = totem.getThumbnail() {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                                .rotationEffect(.degrees(10))
                                .offset(x: 110, y: 0)
                                .onTapGesture {
                                    showingTotemRegistration = true
                                }
                                .disabled(screenTimeManager.isBlocking)
                                .opacity(screenTimeManager.isBlocking ? 0.8 : 1.0)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Scanning status
                    HStack(spacing: 4) {
                        Text(similarityScoreText)
                            .font(.caption)
                            .foregroundColor(
                                similarityScoreText.hasPrefix("Similarity too low") ? .red :
                                similarityScoreText.hasPrefix("Started") || similarityScoreText.hasPrefix("Stopped") ?
                                    .green : .secondary
                            )
                        
                        if lastSimilarityScore > 0 {
                            Text("Score: \(String(format: "%.2f", lastSimilarityScore))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        // Debug info - show active totem info
                        if let totem = currentTotem {
                            Text("[\(totem.name): \(totem.getFeaturePrints().count) FPs]")
                                .font(.caption2)
                                .foregroundColor(.blue.opacity(0.7))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .frame(height: 10)
                    
                    // App Selection Buttons
                    VStack(spacing: 10) {
                        if permissionsManager.screenTimePermissionStatus == .approved {
                            // Show app selection buttons when permission is granted
                            Button(action: {
                                // Set selection to the Default Profile if available
                                if let profile = defaultProfile {
                                    screenTimeManager.selection = profile.toFamilyActivitySelection()
                                } else {
                                    // Reset selection if no Default Profile exists
                                    screenTimeManager.selection = FamilyActivitySelection()
                                }
                                showingFamilyPicker = true
                            }) {
                                Label(
                                    "Quick Select Apps", 
                                    systemImage: defaultProfile?.hasTokens ?? false
                                        ? (screenTimeManager.activeProfile == defaultProfile ? "checkmark.circle" : "circle")
                                        : "plus.circle"
                                )
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(screenTimeManager.isBlocking ? Color.secondary : .blue)
                                .cornerRadius(10)
                                .opacity(screenTimeManager.isBlocking ? 0.6 : 1.0)
                                .symbolEffect(.bounce, options: .speed(1.5), value: defaultProfile?.hasTokens ?? false)
                                .symbolEffect(.bounce, options: .speed(1.5), value: screenTimeManager.activeProfile == defaultProfile)
                                .contentTransition(.symbolEffect(.replace.downUp))
                            }
                            .disabled(screenTimeManager.isBlocking)
                            
                            Button(action: {
                                showingProfilesView = true
                            }) {
                                Label("Manage Profiles", systemImage: "rectangle.stack")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(screenTimeManager.isBlocking ? Color.secondary : .blue)
                                    .cornerRadius(10)
                                    .opacity(screenTimeManager.isBlocking ? 0.6 : 1.0)
                            }
                            .disabled(screenTimeManager.isBlocking)
                        } else {
                            // Show only permission request button when permission is not granted
                            Button(action: {
                                Task {
                                    let granted = await permissionsManager.requestScreenTimePermission()
                                    if !granted {
                                        showingAuthorizationError = true
                                    }
                                }
                            }) {
                                Label("Allow Blocking Apps", systemImage: "hand.raised")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 30)
                    // Family Activity Picker for Default Profile
                    .familyActivityPicker(isPresented: $showingFamilyPicker, 
                                        selection: $screenTimeManager.selection)
                    .onChange(of: showingFamilyPicker) { _, isPresented in
                        if !showingFamilyPicker {
                            // Picker was dismissed, process the selection
                            Task {
                                await screenTimeManager.createOrUpdateQuickSelectionProfile(with: screenTimeManager.selection)
                            }
                        }
                    }
                    .sheet(isPresented: $showingProfilesView) {
                        ProfileSelectionView(screenTimeManager: screenTimeManager)
                    }
                    .sheet(isPresented: $showingTotemRegistration, onDismiss: {
                        // Always reset scanning states when sheet is dismissed
                        isTotemScanningActive = false
                        isTotemScanningLoading = false
                        
                        // Force refresh camera after a short delay regardless of how the sheet was dismissed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            forceRefreshCamera = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                forceRefreshCamera = false
                                // Increment scanner refresh counter to force a rebuild
                                scannerRefreshCounter += 1
                            }
                        }
                    }) {
                        NavigationView {
                            TotemScanningPageView(
                                isScanning: $isTotemScanningActive,
                                totemCaptured: $totemCaptured,
                                isLoading: $isTotemScanningLoading
                            )
                            .onAppear {
                                // Start scanning when view appears
                                isTotemScanningActive = true
                            }
                            .onChange(of: totemCaptured) { _, isCaptured in
                                // Only delete existing totems after successful registration
                                if isCaptured {
                                    // Create a Task to handle database operations asynchronously
                                    Task {
                                        // Get the most recently created totem (the new one)
                                        let fetchDescriptor = FetchDescriptor<TotemModel>(
                                            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                                        )
                                        
                                        do {
                                            // Get all totems sorted by creation date (newest first)
                                            let allTotems = try modelContext.fetch(fetchDescriptor)
                                            
                                            // Keep the most recent totem, delete all others
                                            if let newTotem = allTotems.first {
                                                print("Debug: New totem has \(newTotem.getFeaturePrints().count) feature prints")
                                                
                                                // Set all totems to inactive first
                                                for totem in allTotems {
                                                    totem.isActive = false
                                                }
                                                
                                                // Set the new totem as active
                                                newTotem.isActive = true
                                                
                                                // Delete all older totems
                                                for totem in allTotems where totem != newTotem {
                                                    print("Debug: Deleting old totem: \(totem.name)")
                                                    modelContext.delete(totem)
                                                }
                                                
                                                try modelContext.save()
                                                
                                                // Update UI on the main thread
                                                await MainActor.run {
                                                    // Force scanner refresh by incrementing counter
                                                    scannerRefreshCounter += 1
                                                }
                                            }
                                        } catch {
                                            print("Error managing totems: \(error.localizedDescription)")
                                        }
                                        
                                        // Brief delay to show success message
                                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1.0 second(s)
                                        
                                        // Dismiss the sheet on the main thread
                                        await MainActor.run {
                                            showingTotemRegistration = false
                                        }
                                    }
                                }
                            }
                            .navigationTitle("Register New Totem")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") {
                                        // Stop the scanning first
                                        isTotemScanningActive = false
                                        
                                        // Then dismiss the sheet
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            showingTotemRegistration = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .alert("Permission Required for App Blocking", isPresented: $showingAuthorizationError) {
                        Button("Allow", role: .none) {
                            Task {
                                await permissionsManager.requestScreenTimePermission()
                            }
                        }
                        Button("Not now", role: .cancel) { }
                    } message: {
                        Text("Focus Totem needs Screen Time access to block distracting apps. This is a core feature that won't work without this permission.")
                    }
                    // Selection status
                    VStack {
                        if permissionsManager.screenTimePermissionStatus == .approved {
                            if !screenTimeManager.isBlocking {
                                if screenTimeManager.hasSelection {
                                    HStack(spacing: 6) {
                                        Spacer()
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.blue)
                                        if let activeProfile = screenTimeManager.activeProfile {
                                            Text("Profile: \(activeProfile.name)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("Apps selected")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                } else {
                                    HStack(spacing: 6) {
                                        Spacer()
                                        Image(systemName: "hand.point.up")
                                            .foregroundColor(.blue)
                                        Text("Select which apps to block")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                }
                            } else {
                                HStack(spacing: 6) {
                                    Spacer()
                                    Image(systemName: "qrcode.viewfinder")
                                        .foregroundColor(.red)
                                    Text("Scan the sticker to unlock the apps")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        } else {
                            HStack(spacing: 6) {
                                Spacer()
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundColor(.blue)
                                Text("Give Focus Totem permissions to block apps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .frame(height: 20) // Fixed height to prevent layout shifts
                    .padding(.top, 2)
                }
                
                Spacer()
                
                // Time Counter
                VStack {
                    Text(screenTimeManager.isBlocking ? "Current Session Time" : "Time Blocked This Week")
                        .font(.caption)
                    if isTimerInitialized {
                        Text(timeString(from: screenTimeManager.isBlocking ? currentElapsedTime : statsObject?.calculateTimeThisWeek() ?? .zero))
                            .font(.title2)
                            .bold()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(screenTimeManager.isBlocking ? .red.opacity(0.2) : .blue.opacity(0.2))
                            .cornerRadius(8)
                            .frame(minWidth: 120) // Ensure minimum width
                    } else {
                        // Use a ZStack to ensure consistent sizing with the time display
                        ZStack {
                            // Invisible text with the same font/size as the time display to maintain consistent dimensions
                            // Using a placeholder that includes days format to ensure enough width
                            Text("1d 00:00:00")
                                .font(.title2)
                                .bold()
                                .opacity(0)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            
                            ProgressView()
                                .controlSize(.regular)
                        }
                        .background(.blue.opacity(0.1))
                        .cornerRadius(8)
                        .frame(minWidth: 120) // Ensure minimum width
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarItems(trailing: 
                Button(action: {
                    showingSettingsView = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                }
            )
            .sheet(isPresented: $showingSettingsView) {
                SettingsView(
                    screenTimeManager: screenTimeManager,
                    onEmergencyUnblock: stopBlocking
                )
            }
        }
        .onChange(of: showingFamilyPicker) { _, _ in
            if !showingFamilyPicker {
                // Picker was dismissed, process the selection
                if let defaultProfile = defaultProfile {
                    Task {
                        await screenTimeManager.activateProfile(defaultProfile)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // App is coming back to foreground, refresh the camera
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                forceRefreshCamera = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    forceRefreshCamera = false
                    // Force scanner rebuild
                    scannerRefreshCounter += 1
                }
            }
        }
        .onAppear {
            // Start the timer for updating elapsed time
            startTimer()
            
            // Update the model context with the real one from the environment
            screenTimeManager.updateModelContext(modelContext)
            
            // Check if apps are currently blocked
            screenTimeManager.checkCurrentBlockingState()
            
            // If blocking is active but no active session exists, create one
            if screenTimeManager.isBlocking {
                if let stats = statsObject {
                    // If there's already an active session, don't create a new one
                    if !stats.hasActiveSession {
                        _ = stats.startNewSession()
                        try? modelContext.save()
                    }
                } else {
                    // Create a new stats object with a new session
                    let newStats = SessionsStatsModel()
                    _ = newStats.startNewSession()
                    modelContext.insert(newStats)
                    try? modelContext.save()
                }
                
                print("Restored blocking state from previous session")
            } else {
                // If not blocking but there's an active session, end it
                if let stats = statsObject, stats.hasActiveSession {
                    stats.endCurrentSession()
                    try? modelContext.save()
                }
            }
            
            // Initialize the timer if stats object exists
            if statsObject == nil {
                // Create a new stats object if one doesn't exist
                let newStats = SessionsStatsModel()
                modelContext.insert(newStats)
                try? modelContext.save()
            }

            isTimerInitialized = true
            
            // Check permissions
            Task {
                // Check camera permission status
                await permissionsManager.checkCameraPermission()
                
                // Check screen time permission status
                await permissionsManager.checkScreenTimePermission()
            }
        }
        .alert("Setup Error", isPresented: $showingSetupError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = screenTimeManager.setupError {
                Text("There was a problem setting up your profiles: \(error.localizedDescription)")
            } else {
                Text("An unknown error occurred during setup.")
            }
        }
    }
    
    private func handleValidSimilarityMatch(_ score: Double) {
        // Ensure we don't process scans too frequently (debounce)
        guard lastScanTime == nil || 
              Date().timeIntervalSince(lastScanTime!) >= Self.blockingDebounceTime else {
            return
        }
        
        lastScanTime = Date()
        
        // Toggle blocking state based on current state
        if screenTimeManager.isBlocking {
            // If currently blocking, stop blocking
            stopBlocking()
            similarityScoreText = "Stopped blocking | Score: \(String(format: "%.2f", score))"
            
            // Update session stats if we were blocking
            if let startTime = blockingStartTime {
                let sessionDuration = Date().timeIntervalSince(startTime)
                updateSessionStats(duration: sessionDuration)
                blockingStartTime = nil
            }
        } else {
            // If not blocking, start blocking
            startBlocking()
            similarityScoreText = "Started blocking | Score: \(String(format: "%.2f", score))"
            
            // Record start time for session stats
            blockingStartTime = Date()
        }
    }
    
    private func startBlocking() {
        // Only start blocking if not already blocking
        if !screenTimeManager.isBlocking {
            screenTimeManager.activateBlockingForCurrentProfile()
            
            // Record start time for session stats
            blockingStartTime = Date()
            
            // Create a new session
            if let stats = statsObject {
                if !stats.hasActiveSession {
                    _ = stats.startNewSession()
                    try? modelContext.save()
                }
            } else {
                // Create a new stats object with a new session
                let newStats = SessionsStatsModel()
                _ = newStats.startNewSession()
                modelContext.insert(newStats)
                try? modelContext.save()
            }
            
            // Start the timer
            startTimer()
        }
    }
    
    private func stopBlocking() {
        // Only stop blocking if currently blocking
        if screenTimeManager.isBlocking {
            screenTimeManager.deactivateBlocking()
            
            // End the current session if there is one
            if let stats = statsObject, stats.hasActiveSession {
                stats.endCurrentSession()
                try? modelContext.save()
            }
            
            // Update session stats if we were blocking
            if let startTime = blockingStartTime {
                let sessionDuration = Date().timeIntervalSince(startTime)
                updateSessionStats(duration: sessionDuration)
                blockingStartTime = nil
            }
            
            // Stop timer
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func startTimer() {
        // Stop existing timer if any
        timer?.invalidate()
        
        // Start new timer with dispatch to main thread to handle @MainActor-isolated properties
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Use Task to handle the @MainActor-isolated properties safely
            Task { @MainActor in
                if self.screenTimeManager.isBlocking {
                    // If we're blocking, get time directly from blockingStartTime
                    if let startTime = self.blockingStartTime {
                        self.currentElapsedTime = Date().timeIntervalSince(startTime)
                    } else if let stats = self.statsObject, stats.hasActiveSession {
                        // Fallback to stats if blockingStartTime is not set
                        self.currentElapsedTime = stats.currentSession?.duration ?? 0
                    }
                } else {
                    // If not blocking, get the total time for the week
                    if let stats = self.statsObject {
                        // This will trigger UI update even if not blocking
                        self.currentElapsedTime = stats.calculateTimeThisWeek()
                    }
                }
            }
        }
        
        // Trigger immediate update
        if screenTimeManager.isBlocking {
            if let startTime = blockingStartTime {
                currentElapsedTime = Date().timeIntervalSince(startTime)
            }
        } else if let stats = statsObject {
            currentElapsedTime = stats.calculateTimeThisWeek()
        }
        
        isTimerInitialized = true
    }
    
    private func updateSessionStats(duration: TimeInterval) {
        if let stats = statsObject {
            // Update the total blocked time
            stats.totalBlockedTime += duration
            
            // End the current session if there is one
            if stats.hasActiveSession {
                stats.endCurrentSession()
            }
            
            try? modelContext.save()
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let days = Int(timeInterval) / 86400
        let hours = Int(timeInterval) / 3600 % 24
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if days > 0 {
            return String(format: "%dd %02d:%02d:%02d", days, hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ProfileModel.self, SessionsStatsModel.self, TotemModel.self], inMemory: true)
}
