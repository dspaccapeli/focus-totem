//
//  SettingsView.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 15/03/25.
//

import SwiftUI
import SafariServices
import SwiftData
import Vision

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var screenTimeManager: ScreenTimeManager
    @Query private var totems: [TotemModel] // Added query for TotemModel
    
    // Callback function for emergency unblock
    var onEmergencyUnblock: () -> Void
    
    // State variables
    @State private var showingUnblockConfirmation = false
    @State private var showingNoMoreUnblocksAlert = false
    @State private var remainingUnblocks: Int
    @State private var showingTotemRegistration = false
    @State private var showingResetTotemConfirmation = false
    @State private var showingResetSuccess = false
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    @State private var showingCannotResetTotemAlert = false
    
    // State variables for TotemScanningPageView
    @State private var isScanning = false
    @State private var totemCaptured = false
    @State private var isLoading = false
    
    // UserDefaults key for remaining emergency unblocks
    private let remainingUnblocksKey = "remainingEmergencyUnblocks"
    private let maxEmergencyUnblocks = 5
    
    // Initialize with default unblocks count if not already set
    init(screenTimeManager: ScreenTimeManager, onEmergencyUnblock: @escaping () -> Void) {
        self.screenTimeManager = screenTimeManager
        self.onEmergencyUnblock = onEmergencyUnblock
        
        // Set default value if key doesn't exist
        if UserDefaults.standard.object(forKey: remainingUnblocksKey) == nil {
            UserDefaults.standard.set(maxEmergencyUnblocks, forKey: remainingUnblocksKey)
        }
        
        // Initialize the state property
        self._remainingUnblocks = State(initialValue: UserDefaults.standard.integer(forKey: remainingUnblocksKey))
    }
    
    var body: some View {
        NavigationView {
            SettingsContentView()
                .navigationTitle("Settings")
                .navigationBarItems(trailing: Button("Done") {
                    dismiss()
                })
        }
        .alert("Emergency Unblock", isPresented: $showingUnblockConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Unblock", role: .destructive) {
                performEmergencyUnblock()
            }
        } message: {
            Text("This will immediately stop blocking all apps. You have \(remainingUnblocks) emergency unblocks remaining. Use this only when absolutely necessary.")
        }
        .alert("No Unblocks Remaining", isPresented: $showingNoMoreUnblocksAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You have used all your emergency unblocks. Wait for the current blocking session to end naturally.")
        }
        .alert("Totem Reset Success", isPresented: $showingResetSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Totem reset successfully.")
        }
        .sheet(isPresented: $showingTotemRegistration, onDismiss: {
            // Only run handleTotemReset if a totem was successfully captured
            if totemCaptured {
                handleTotemReset()
                // Reset the state for next time
                totemCaptured = false
            }
            // Always reset these states regardless of whether a totem was captured
            isScanning = false
            isLoading = false
        }) {
            NavigationView {
                TotemScanningPageView(
                    isScanning: $isScanning,
                    totemCaptured: $totemCaptured,
                    isLoading: $isLoading
                )
                .onAppear {
                    // Start scanning when view appears
                    isScanning = true
                }
                .onChange(of: totemCaptured) { _, isCaptured in
                    // Auto-dismiss the sheet when totem is captured
                    if isCaptured {
                        // Brief delay to show success message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showingTotemRegistration = false
                        }
                    }
                }
                .navigationTitle("Reset Totem")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            // Stop the scanning first
                            isScanning = false
                            
                            // Then dismiss the sheet
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showingTotemRegistration = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Break out the List content into a separate View
    @ViewBuilder
    private func SettingsContentView() -> some View {
        List {
            SupportSection()
            TotemManagementSection()
            EmergencySection()
            
            /*
            Section(header: Text("About")) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundColor(.gray)
                }
            }
            */
        }
    }
    
    // Support Section
    @ViewBuilder
    private func SupportSection() -> some View {
        Section(header: Text("Support")) {
            Link(destination: URL(string: "https://deliberate.app/faq")!) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.blue)
                    Text("Frequently Asked Questions")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            Link(destination: URL(string: "https://deliberate.app/how-to-use")!) {
                HStack {
                    Image(systemName: "book.circle")
                        .foregroundColor(.blue)
                    Text("How to Use")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
        }
    }
    
    // Emergency Section
    @ViewBuilder
    private func EmergencySection() -> some View {
        Section(header: Text("Emergency Options")) {
            Button(action: {
                if remainingUnblocks > 0 {
                    showingUnblockConfirmation = true
                } else {
                    showingNoMoreUnblocksAlert = true
                }
            }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("Emergency Unblock")
                    Spacer()
                    Text("\(remainingUnblocks) remaining")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .disabled(remainingUnblocks <= 0 || !screenTimeManager.isBlocking)
        }
    }
    
    // Totem Management Section
    @ViewBuilder
    private func TotemManagementSection() -> some View {
        Section(header: Text("Totem Management")) {
            Button(action: {
                if screenTimeManager.isBlocking {
                    // Show alert that totem can't be reset during blocking
                    showingCannotResetTotemAlert = true
                } else {
                    showingResetTotemConfirmation = true
                }
            }) {
                HStack {
                    Image(systemName: "gobackward")
                        .foregroundColor(screenTimeManager.isBlocking ? .gray : .blue)
                    Text("Reset Totem")
                        .foregroundColor(screenTimeManager.isBlocking ? .gray : .blue)
                    Spacer()
                }
            }
            .alert("Reset Totem", isPresented: $showingResetTotemConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    showingTotemRegistration = true
                }
            } message: {
                Text("This will reset your totem. You'll need to register a new totem afterward.")
            }
            .alert("Cannot Reset Totem", isPresented: $showingCannotResetTotemAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You cannot change the totem while blocking apps. Stop blocking first.")
            }
        }
    }
    
    private func performEmergencyUnblock() {
        // Decrement the remaining unblocks count and update UserDefaults
        remainingUnblocks -= 1
        UserDefaults.standard.set(remainingUnblocks, forKey: remainingUnblocksKey)
        
        // Call ContentView's stopBlocking method via callback instead of directly
        // calling screenTimeManager.deactivateBlocking()
        onEmergencyUnblock()
        
        // Dismiss settings view after unblocking
        dismiss()
    }
    
    private func handleTotemReset() {
        // Create a Task to handle database operations asynchronously
        Task {
            // Get the most recently created totem (the new one)
            let fetchDescriptor = FetchDescriptor<TotemModel>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            do {
                // Get all totems sorted by creation date (newest first)
                let allTotems = try modelContext.fetch(fetchDescriptor)
                
                // Only proceed if we have at least one totem
                if !allTotems.isEmpty {
                    print("Debug: Found \(allTotems.count) totems")
                    
                    // Get the most recently created totem
                    let newTotem = allTotems[0]
                    print("Debug: New totem has \(newTotem.getFeaturePrints().count) feature prints")
                    
                    // Set all totems to inactive first
                    for totem in allTotems {
                        totem.isActive = false
                    }
                    
                    // Set the new totem as active
                    newTotem.isActive = true
                    
                    // Delete all older totems
                    for totem in allTotems where totem.id != newTotem.id {
                        print("Debug: Deleting old totem: \(totem.name)")
                        modelContext.delete(totem)
                    }
                    
                    try modelContext.save()
                    
                    // Trigger haptic feedback and show success message on main thread
                    await MainActor.run {
                        hapticFeedback.prepare()
                        hapticFeedback.impactOccurred(intensity: 0.3)
                        showingResetSuccess = true
                        
                        // Dismiss the sheet if it's still presented
                        showingTotemRegistration = false
                    }
                } else {
                    print("Debug: No totems found")
                }
            } catch {
                print("Error managing totems: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    // Create a temporary model container for preview
    let tempContainer = try! ModelContainer(for: ProfileModel.self, SessionsStatsModel.self, 
                                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    return SettingsView(
        screenTimeManager: ScreenTimeManager(modelContext: tempContainer.mainContext),
        onEmergencyUnblock: {}
    )
}
