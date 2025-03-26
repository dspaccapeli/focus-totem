//
//  TotemModel.swift
//  Focus Totem
//
//  Created by Cascade AI on 26/03/25.
//

import SwiftUI
import SwiftData
import Vision
import UIKit

@Model
final class TotemModel {
    var name: String
    var createdAt: Date
    var featurePrints: [Data] // Serialized VNFeaturePrintObservation objects
    var images: [Data] // Array of image data for each captured angle
    var isActive: Bool // Whether this totem is currently being used for verification
    
    init(name: String, featurePrints: [VNFeaturePrintObservation], imageDataArray: [Data]) {
        self.name = name
        self.createdAt = Date()
        
        // Convert feature prints to Data
        self.featurePrints = featurePrints.compactMap { featurePrint in
            try? NSKeyedArchiver.archivedData(withRootObject: featurePrint, requiringSecureCoding: true)
        }
        
        self.images = imageDataArray
        self.isActive = true
    }
    
    // Helper method to get feature prints as VNFeaturePrintObservation objects
    func getFeaturePrints() -> [VNFeaturePrintObservation] {
        return featurePrints.compactMap { data in
            try? NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: data)
        }
    }
    
    // Helper method to get images as UIImage objects
    func getImages() -> [UIImage] {
        return images.compactMap { UIImage(data: $0) }
    }
    
    // Helper method to get the first image as a thumbnail
    func getThumbnail() -> UIImage? {
        guard let firstImageData = images.first else { return nil }
        return UIImage(data: firstImageData)
    }
    
    // Helper method to compute maximum similarity against this totem's feature prints
    func computeMaxSimilarity(with currentFeaturePrint: VNFeaturePrintObservation) -> Double {
        var maxSimilarity = 0.0
        
        for storedPrint in getFeaturePrints() {
            do {
                var distance: Float = 0.0
                try currentFeaturePrint.computeDistance(&distance, to: storedPrint)
                
                // Convert distance to similarity score (1.0 - distance)
                let similarity = Double(1.0 - distance)
                
                // Update max similarity if this one is higher
                if similarity > maxSimilarity {
                    maxSimilarity = similarity
                }
            } catch {
                print("Error computing similarity: \(error)")
            }
        }
        
        return maxSimilarity
    }
}
