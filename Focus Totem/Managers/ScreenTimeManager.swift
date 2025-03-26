//
//  ScreenTimeManager.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 13/03/25.
//
// >> "Which apps do we block and how?" (functionality)

import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI
import SwiftData

// Handles Screen Time API interactions for blocking applications
@MainActor
final class ScreenTimeManager: ObservableObject {
    // import SwiftUI which is required for ObservableObject
    private let store = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()
    
    // Store the quick selection profile name
    private let defaultProfileName: String
    
    @Published var selection = FamilyActivitySelection()
    @Published var profiles: [ProfileModel] = []
    @Published var activeProfile: ProfileModel?
    @Published var isBlocking = false
    
    // Setup state
    @Published var isSetupComplete = false
    @Published var setupError: Error?
    
    private var modelContext: ModelContext
    
    // MARK: - Initialization
    init(modelContext: ModelContext, defaultProfileName: String = "Default Profile") {
        self.modelContext = modelContext
        self.defaultProfileName = defaultProfileName
        
        // Initial setup with temporary context
        performSetup()
    }
    
    // Update the model context after initialization
    func updateModelContext(_ newModelContext: ModelContext) {
        // Check if this is a different context
        let needsSetup = modelContext !== newModelContext
        
        // Update the context
        self.modelContext = newModelContext
        
        // Only perform setup if we're switching to a different context
        if needsSetup {
            performSetup()
        }
    }
    
    // Helper method to perform setup
    private func performSetup() {
        isSetupComplete = false
        setupError = nil
        
        Task {
            do {
                try await setup()
                self.isSetupComplete = true
                
                // Check current blocking state after setup
                checkCurrentBlockingState()
            } catch {
                print("Error during setup: \(error.localizedDescription)")
                self.setupError = error
                self.isSetupComplete = true
            }
        }
    }
    
    // Setup method that can be awaited and can throw errors
    public func setup() async throws {
        try await loadProfiles()
        try await ensureDefaultProfileExists()
    }
    
    // MARK: - Profile Management
    
    /// Load all saved profiles from SwiftData
    private func loadProfiles() async throws {
        do {
            let descriptor = FetchDescriptor<ProfileModel>(sortBy: [SortDescriptor(\.name), SortDescriptor(\.lastUpdated, order: .reverse)])
            
            let results = try modelContext.fetch(descriptor)
            print("Found \(results.count) saved profiles")
            
            await MainActor.run {
                self.profiles = results
                
                // Find the active profile if any exists
                self.activeProfile = results.first { $0.isActive }
                
                // If we have an active profile, set its selection
                if let activeProfile = self.activeProfile {
                    self.selection = activeProfile.toFamilyActivitySelection()
                    print("Loaded active profile: \(activeProfile.name) with \(activeProfile.applicationTokenCount) app tokens")
                } else if !results.isEmpty {
                    // Otherwise use the first profile if available
                    self.activeProfile = results[0]
                    self.selection = results[0].toFamilyActivitySelection()
                    print("No active profile found, using first profile: \(results[0].name)")
                }
            }
        } catch {
            print("Failed to load profiles: \(error.localizedDescription)")
            throw ScreenTimeManagerError.failedToLoadProfiles(error)
        }
    }
    
    /// Ensures that the default profile exists, creating it if necessary
    private func ensureDefaultProfileExists() async throws {
        return try await MainActor.run {
            // Check if default profile exists
            let defaultProfileExists = profiles.contains { $0.name == self.defaultProfileName }
            
            if !defaultProfileExists {
                print("Default profile '\(self.defaultProfileName)' not found. Creating it...")
                let newDefaultProfile = ProfileModel(name: self.defaultProfileName, isActive: self.activeProfile == nil)
                self.modelContext.insert(newDefaultProfile)
                self.profiles.append(newDefaultProfile)
                
                // If no active profile, make this one active
                if self.activeProfile == nil {
                    self.activeProfile = newDefaultProfile
                    print("No active profile found. Setting new default profile as active.")
                }
                
                // Save the changes and handle errors
                do {
                    try self.modelContext.save()
                } catch {
                    print("Failed to save default profile: \(error.localizedDescription)")
                    throw ScreenTimeManagerError.failedToCreateDefaultProfile(error)
                }
            }
        }
    }
    
    // MARK: - Profile Management
    
    /// Create a new profile with empty selection
    func createProfile(name: String, copyCurrentSelection: Bool = false) async {
        // Create new profile with empty selection by default
        let newProfile = ProfileModel(name: name, isActive: false)
        
        // Only copy current selection if explicitly requested
        if copyCurrentSelection {
            newProfile.update(from: selection)
        }
        
        await MainActor.run {
            modelContext.insert(newProfile)
            profiles.append(newProfile)
        }
        
        try? modelContext.save()
        print("Created new profile: \(name)")
    }
    
    /// Delete a profile
    func deleteProfile(_ profile: ProfileModel) async {
        // Handle profile deletion
        if profile.isActive {
            // For active profiles
            await MainActor.run {
                // If this is the only profile, just delete it and clear active profile
                if profiles.count <= 1 {
                    modelContext.delete(profile)
                    profiles.removeAll()
                    activeProfile = nil
                    selection = FamilyActivitySelection()
                } else {
                    // Activate another profile
                    let otherProfile = profiles.first { $0 != profile } ?? profiles[0]
                    otherProfile.isActive = true
                    activeProfile = otherProfile
                    selection = otherProfile.toFamilyActivitySelection()
                    
                    // Now delete the original profile
                    modelContext.delete(profile)
                    profiles.removeAll { $0 == profile }
                }
            }
        } else {
            // For non-active profiles, just delete
            await MainActor.run {
                modelContext.delete(profile)
                profiles.removeAll { $0 == profile }
            }
        }
        
        try? modelContext.save()
        print("Deleted profile: \(profile.name)")
    }
    
    /// Activate a profile and deactivate all others
    func activateProfile(_ profile: ProfileModel) async {
        await MainActor.run {
            // Deactivate all profiles
            for p in profiles {
                p.isActive = false
            }
            
            // Activate the selected profile
            profile.isActive = true
            activeProfile = profile
            selection = profile.toFamilyActivitySelection()
        }
        
        try? modelContext.save()
        print("Activated profile: \(profile.name)")
    }
    
    /// Deactivate a profile without activating another one
    func deactivateProfile(_ profile: ProfileModel? = nil) async {
        await MainActor.run {
            // If no profile is specified, use the active profile
            let profileToDeactivate = profile ?? activeProfile
            
            // Only proceed if there's a profile to deactivate
            if let profileToDeactivate = profileToDeactivate, profileToDeactivate.isActive {
                profileToDeactivate.isActive = false
                activeProfile = nil
                selection = FamilyActivitySelection()
                print("Deactivated profile: \(profileToDeactivate.name)")
            }
        }
        
        try? modelContext.save()
    }
    
    /// Rename a profile
    func renameProfile(_ profile: ProfileModel, to newName: String) async {
        await MainActor.run {
            profile.rename(to: newName)
        }
        
        try? modelContext.save()
        print("Renamed profile to: \(newName)")
    }
    
    // MARK: - Profile Selection Editing
    
    /// Load a profile's selection into the current selection
    func loadSelectionFromProfile(_ profile: ProfileModel) {
        self.selection = profile.toFamilyActivitySelection()
        print("Loaded selection from profile: \(profile.name)")
    }
    
    /// Update a specific profile with the current selection
    func updateProfileWithCurrentSelection(_ profile: ProfileModel) async {
        await updateProfile(profile, with: selection)
    }
    
    // MARK: - Default Profile
    
    /// Create or update the Quick Selection profile with the current selection
    func createOrUpdateQuickSelectionProfile(with newSelection: FamilyActivitySelection) async {
        // Look for an existing Quick Selection profile
        let defaultProfile = profiles.first { $0.name == defaultProfileName }
        
        if let existingProfile = defaultProfile {
            // Update the existing profile
            await MainActor.run {
                existingProfile.update(from: newSelection)
                selection = newSelection
                activeProfile = existingProfile
                existingProfile.isActive = true
            }
            
            // Deactivate all other profiles
            for profile in profiles where profile != existingProfile {
                profile.isActive = false
            }
            
            try? modelContext.save()
            print("Updated \(defaultProfileName) profile")
        } else {
            // Create a new Quick Selection profile
            let newProfile = ProfileModel(name: defaultProfileName, isActive: true)
            newProfile.update(from: newSelection)
            
            await MainActor.run {
                // Deactivate all other profiles
                for profile in profiles where profile !== newProfile {
                    profile.isActive = false
                }
                
                modelContext.insert(newProfile)
                profiles.append(newProfile)
                activeProfile = newProfile
                selection = newSelection
            }
            
            try? modelContext.save()
            print("Created new \(defaultProfileName) profile")
        }
    }
    
    // MARK: - Selection Management
    func updateSelectedCategories(_ newSelection: FamilyActivitySelection) {
        print("Updating selection with \(newSelection.applicationTokens.count) app tokens and \(newSelection.categoryTokens.count) category tokens")
        selection = newSelection
        
        // If we have an active profile, update it with new selection
        if let activeProfile = activeProfile {
            activeProfile.update(from: newSelection)
            try? modelContext.save()
        } else if !profiles.isEmpty {
            // Activate an existing profile if available
            Task {
                if let profile = profiles.first {
                    await activateProfile(profile)
                    profile.update(from: newSelection)
                    try? modelContext.save()
                }
            }
        }
        // Do nothing if no profiles exist - user will need to create one explicitly
    }
    
    // Update an existing profile with new selection
    func updateProfile(_ profile: ProfileModel, with newSelection: FamilyActivitySelection) async {
        await MainActor.run {
            profile.update(from: newSelection)
            
            // If this is the active profile, update current selection
            if activeProfile == profile {
                selection = newSelection
            }
        }
        
        try? modelContext.save()
        print("Updated profile: \(profile.name)")
    }
    
    // MARK: - Blocking Management
    func activateBlockingForCurrentProfile() {
        var shield = store.shield
        
        // Configure shield with selected apps and categories
        shield.applications = selection.applicationTokens
        shield.applicationCategories = .specific(selection.categoryTokens)
        
        // Configure shield with selected web domains and categories
        shield.webDomains = selection.webDomainTokens
        
        // Update blocking state
        isBlocking = true
    }
    
    func deactivateBlocking() {
        var shield = store.shield
        
        // Clear all restrictions
        shield.applications = nil
        shield.applicationCategories = nil
        shield.webDomains = nil
        
        // Update blocking state
        isBlocking = false
    }
    
    /// Check if apps are currently blocked by examining the ManagedSettingsStore
    /// and update the isBlocking property accordingly
    func checkCurrentBlockingState() {
        // Access the current shield settings
        let shield = store.shield
        
        // Check if any applications or categories are currently being blocked
        let hasBlockedApps = shield.applications != nil && !(shield.applications?.isEmpty ?? true)
        let hasBlockedCategories = shield.applicationCategories != nil
        let hasBlockedWebDomains = shield.webDomains != nil && !(shield.webDomains?.isEmpty ?? true)
        
        // Update the isBlocking state based on current shield settings
        let newBlockingState = hasBlockedApps || hasBlockedCategories || hasBlockedWebDomains
        
        // Only update if there's a change to avoid unnecessary UI updates
        if isBlocking != newBlockingState {
            isBlocking = newBlockingState
            print("Updated blocking state: \(isBlocking ? "BLOCKING" : "NOT BLOCKING")")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if there is any selection (apps or categories) to block
    var hasSelection: Bool {
        return !selection.applicationTokens.isEmpty || 
               !selection.categoryTokens.isEmpty || 
               !selection.webDomainTokens.isEmpty
    }
}

// Define custom errors for ScreenTimeManager
enum ScreenTimeManagerError: Error {
    case failedToLoadProfiles(Error)
    case failedToCreateDefaultProfile(Error)
    case modelContextNotAvailable
    
    var localizedDescription: String {
        switch self {
        case .failedToLoadProfiles(let error):
            return "Failed to load profiles: \(error.localizedDescription)"
        case .failedToCreateDefaultProfile(let error):
            return "Failed to create default profile: \(error.localizedDescription)"
        case .modelContextNotAvailable:
            return "Model context is not available"
        }
    }
}
