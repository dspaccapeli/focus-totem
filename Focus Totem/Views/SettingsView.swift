//
//  SettingsView.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 15/03/25.
//

import SwiftUI
import SafariServices
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var screenTimeManager: ScreenTimeManager
    
    // Callback function for emergency unblock
    var onEmergencyUnblock: () -> Void
    
    // State variables
    @State private var showingUnblockConfirmation = false
    @State private var showingNoMoreUnblocksAlert = false
    @State private var remainingUnblocks: Int
    
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
            List {
                Section(header: Text("Support")) {
                    Link(destination: URL(string: "https://deliberate.app/faq")!) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("Frequently Asked Questions")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
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
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
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
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                .disabled(remainingUnblocks <= 0 || !screenTimeManager.isBlocking)
                }
                
                /*
                Section(header: Text("About")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                */
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
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
