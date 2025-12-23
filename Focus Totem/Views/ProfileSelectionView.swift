// NOTE: This view is now optional as the FamilyActivityPicker can be implemented directly 
// in ContentView.swift using the familyActivityPicker(isPresented:selection:) modifier on the
// "Select Profile" button. This approach simplifies the app architecture while maintaining
// the same functionality.

import SwiftUI
import FamilyControls
import SwiftData

struct ProfileSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var screenTimeManager: ScreenTimeManager
    @StateObject private var permissionsManager = PermissionsManager.shared
    
    // State to control the presentation of the activity picker
    @State private var showActivityPicker = false
    @State private var showingAuthorizationError = false
    @State private var showingCreateProfileAlert = false
    @State private var showingRenameProfileAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var newProfileName = ""
    @State private var profileToRename: ProfileModel?
    @State private var profilesToDelete = IndexSet()
    
    // Computed property to filter out the Quick Selection profile
    private var userProfiles: [ProfileModel] {
        screenTimeManager.profiles.filter { $0.name != "Quick Selection" }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if userProfiles.isEmpty {
                    ContentUnavailableView("No Profiles", 
                                           systemImage: "rectangle.stack.badge.plus",
                                           description: Text("Create your first profile to get started"))
                        .padding()
                } else {
                    List {
                        Section(header: Text("Your Profiles")) {
                            ForEach(userProfiles) { profile in
                                ProfileRow(profile: profile, 
                                           isActive: profile == screenTimeManager.activeProfile, 
                                           screenTimeManager: screenTimeManager,
                                           onRename: {
                                               profileToRename = profile
                                               newProfileName = profile.name
                                               showingRenameProfileAlert = true
                                           })
                                .swipeActions(edge: .leading) {
                                    Button {
                                        if permissionsManager.screenTimePermissionStatus == .approved {
                                            // Load this profile's selection before showing the picker
                                            screenTimeManager.loadSelectionFromProfile(profile)
                                            showActivityPicker = true
                                        } else {
                                            showingAuthorizationError = true
                                        }
                                    } label: {
                                        Label("Edit Apps", systemImage: "apps.iphone")
                                    }
                                    .tint(.orange)
                                }
                                .swipeActions(edge: .trailing) {
                                    if profile != screenTimeManager.activeProfile {
                                        Button(role: .destructive) {
                                            profilesToDelete = IndexSet([screenTimeManager.profiles.firstIndex(where: { $0.id == profile.id }) ?? 0])
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    
                                    Button {
                                        profileToRename = profile
                                        newProfileName = profile.name
                                        showingRenameProfileAlert = true
                                    } label: {
                                        Label("Rename", systemImage: "square.and.pencil")
                                    }
                                    .tint(.blue)
                                }
                                .contextMenu {
                                    Button {
                                        profileToRename = profile
                                        newProfileName = profile.name
                                        showingRenameProfileAlert = true
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    
                                    Button {
                                        Task {
                                            await screenTimeManager.createProfile(name: "\(profile.name) (Copy)", copyCurrentSelection: false)
                                            let selection = profile.toFamilyActivitySelection()
                                            if let newProfile = screenTimeManager.profiles.last {
                                                await screenTimeManager.updateProfile(newProfile, with: selection)
                                            }
                                        }
                                    } label: {
                                        Label("Duplicate", systemImage: "plus.square.on.square")
                                    }
                                    
                                    if profile != screenTimeManager.activeProfile {
                                        Divider()
                                        
                                        Button(role: .destructive) {
                                            profilesToDelete = IndexSet([screenTimeManager.profiles.firstIndex(where: { $0.id == profile.id }) ?? 0])
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        
                        Section {
                            Button(action: {
                                showingCreateProfileAlert = true
                            }) {
                                Label("Create New Profile", systemImage: "plus.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Block Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Create New Profile", isPresented: $showingCreateProfileAlert) {
                TextField("Profile Name", text: $newProfileName)
                    .autocorrectionDisabled()
                
                Button("Cancel", role: .cancel) {
                    newProfileName = ""
                }
                
                Button("Create") {
                    if !newProfileName.isEmpty {
                        createNewProfile(named: newProfileName)
                        newProfileName = ""
                    }
                }
            }
            .alert("Rename Profile", isPresented: $showingRenameProfileAlert) {
                TextField("Profile Name", text: $newProfileName)
                    .autocorrectionDisabled()
                
                Button("Cancel", role: .cancel) {
                    profileToRename = nil
                    newProfileName = ""
                }
                
                Button("Rename") {
                    if let profile = profileToRename, !newProfileName.isEmpty {
                        renameProfile(profile, to: newProfileName)
                        profileToRename = nil
                        newProfileName = ""
                    }
                }
            }
            .confirmationDialog(
                "Delete Profile",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteProfiles(at: profilesToDelete)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this profile? This action cannot be undone.")
            }
        }
        .task {
            // Check permission status when view appears
            await permissionsManager.checkScreenTimePermission()
        }
        .familyActivityPicker(isPresented: $showActivityPicker, 
                              selection: $screenTimeManager.selection)
        .onChange(of: showActivityPicker) { _, isPresented in
            if !isPresented {
                // Picker was dismissed, process the selection
                screenTimeManager.updateSelectedCategories(screenTimeManager.selection)
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
            Text("Deliberate needs Screen Time access to block distracting apps. This is a core feature that won't work without this permission.")
        }
    }
    
    private func createNewProfile(named name: String) {
        Task {
            await screenTimeManager.createProfile(name: name, copyCurrentSelection: false)
        }
    }
    
    private func renameProfile(_ profile: ProfileModel, to newName: String) {
        Task {
            await screenTimeManager.renameProfile(profile, to: newName)
        }
    }
    
    private func deleteProfiles(at indexSet: IndexSet) {
        Task {
            for index in indexSet {
                if index < screenTimeManager.profiles.count {
                    await screenTimeManager.deleteProfile(screenTimeManager.profiles[index])
                }
            }
        }
    }
}

// MARK: - Helper Views

struct ProfileRow: View {
    let profile: ProfileModel
    let isActive: Bool
    @ObservedObject var screenTimeManager: ScreenTimeManager
    var onRename: () -> Void
    @State private var showActivityPicker = false
    @StateObject private var permissionsManager = PermissionsManager.shared
    @State private var showingAuthorizationError = false
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                
                if profile.applicationTokenCount > 0 || profile.categoryTokenCount > 0 || profile.webDomainTokenCount > 0 {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()
            
            if isActive {
                Text("Active")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.all, 20)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isActive {
                Task {
                    await screenTimeManager.activateProfile(profile)
                }
            }
        }
        .background(isActive ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .familyActivityPicker(isPresented: $showActivityPicker, 
                               selection: $screenTimeManager.selection)
        .onChange(of: showActivityPicker) { _, isPresented in
            if !isPresented {
                // Picker was dismissed, update this profile with the selection
                Task {
                    await screenTimeManager.updateProfileWithCurrentSelection(profile)
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
            Text("Deliberate needs Screen Time access to block distracting apps. This is a core feature that won't work without this permission.")
        }
    }
}
