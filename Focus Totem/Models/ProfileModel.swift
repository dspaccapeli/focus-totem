import SwiftData
import ManagedSettings
import Foundation
import FamilyControls
import SwiftUI

@Model
final class ProfileModel {
    // Profile identification properties
    var name: String
    var isActive: Bool
    
    // Use private(set) to allow read-only access while maintaining encapsulation
    private(set) var encodedApplicationTokens: Data
    private(set) var encodedCategoryTokens: Data
    private(set) var encodedWebDomainTokens: Data
    var lastUpdated: Date
    
    // Add a computed property for token counts to help with debugging
    var applicationTokenCount: Int {
        do {
            let appTokens = try PropertyListDecoder().decode([ApplicationToken].self, from: encodedApplicationTokens)
            return appTokens.count
        } catch {
            print("Failed to decode application tokens: \(error)")
            return 0
        }
    }
    
    var categoryTokenCount: Int {
        do {
            let catTokens = try PropertyListDecoder().decode([ActivityCategoryToken].self, from: encodedCategoryTokens)
            return catTokens.count
        } catch {
            print("Failed to decode category tokens: \(error)")
            return 0
        }
    }
    
    var webDomainTokenCount: Int {
        do {
            let webTokens = try PropertyListDecoder().decode([WebDomainToken].self, from: encodedWebDomainTokens)
            return webTokens.count
        } catch {
            print("Failed to decode web domain tokens: \(error)")
            return 0
        }
    }

    /// Returns true if the model has any tokens (applications, categories, or web domains)
    var hasTokens: Bool {
        return applicationTokenCount > 0 || categoryTokenCount > 0 || webDomainTokenCount > 0
    }
    
    init(name: String = "Default Profile", 
         isActive: Bool = false,
         applicationTokens: Set<ApplicationToken> = [], 
         categoryTokens: Set<ActivityCategoryToken> = [],
         webDomainTokens: Set<WebDomainToken> = []) {
        self.name = name
        self.isActive = isActive
        
        do {
            self.encodedApplicationTokens = try PropertyListEncoder().encode(Array(applicationTokens))
            self.encodedCategoryTokens = try PropertyListEncoder().encode(Array(categoryTokens))
            self.encodedWebDomainTokens = try PropertyListEncoder().encode(Array(webDomainTokens))
        } catch {
            print("Failed to encode tokens during initialization: \(error)")
            self.encodedApplicationTokens = Data()
            self.encodedCategoryTokens = Data()
            self.encodedWebDomainTokens = Data()
        }
        self.lastUpdated = Date()
    }
    
    func update(from selection: FamilyActivitySelection) {
        do {
            // Only update if tokens are actually present
            // if !selection.applicationTokens.isEmpty {
            // if !selection.categoryTokens.isEmpty {
            // if !selection.webDomainTokens.isEmpty {
            self.encodedApplicationTokens = try PropertyListEncoder().encode(Array(selection.applicationTokens))
            print("Encoded \(selection.applicationTokens.count) application tokens")
        
            self.encodedCategoryTokens = try PropertyListEncoder().encode(Array(selection.categoryTokens))
            print("Encoded \(selection.categoryTokens.count) category tokens")
            
            self.encodedWebDomainTokens = try PropertyListEncoder().encode(Array(selection.webDomainTokens))
            print("Encoded \(selection.webDomainTokens.count) web domain tokens")
            
            self.lastUpdated = Date()
        } catch {
            print("Failed to encode tokens during update: \(error.localizedDescription)")
        }
    }
    
    func toFamilyActivitySelection() -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()
        
        do {
            // Properly decode application tokens
            let appTokens = try PropertyListDecoder().decode([ApplicationToken].self, from: encodedApplicationTokens)
            selection.applicationTokens = Set(appTokens)
            print("Decoded \(appTokens.count) application tokens")
            
            // Properly decode category tokens
            let catTokens = try PropertyListDecoder().decode([ActivityCategoryToken].self, from: encodedCategoryTokens)
            selection.categoryTokens = Set(catTokens)
            print("Decoded \(catTokens.count) category tokens")
            
            // Properly decode web domain tokens
            let webTokens = try PropertyListDecoder().decode([WebDomainToken].self, from: encodedWebDomainTokens)
            selection.webDomainTokens = Set(webTokens)
            print("Decoded \(webTokens.count) web domain tokens")
        } catch {
            print("Error decoding tokens: \(error.localizedDescription)")
        }
        
        return selection
    }
    
    // Convenience method to toggle active status
    func toggleActive() {
        isActive = !isActive
        lastUpdated = Date()
    }
    
    // Update profile name
    func rename(to newName: String) {
        name = newName
        lastUpdated = Date()
    }

    // Create a binding to FamilyActivitySelection for direct use in SwiftUI
    var familyActivitySelection: Binding<FamilyActivitySelection> {
        Binding<FamilyActivitySelection>(
            get: {
                // Convert from model to FamilyActivitySelection
                self.toFamilyActivitySelection()
            },
            set: { newSelection in
                // Update model from FamilyActivitySelection
                self.update(from: newSelection)
            }
        )
    }
}
