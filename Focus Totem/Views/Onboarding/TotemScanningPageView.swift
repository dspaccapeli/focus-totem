//
//  TotemScanningPageView.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 14/03/25.
//

import SwiftUI
import Vision
import AVFoundation
import SwiftData

enum TotemScanningState {
    case capture
    case verification
    case success
}

struct TotemScanningPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TotemModel.createdAt) private var totems: [TotemModel]
    @State private var savedTotem: TotemModel?
    @Binding var isScanning: Bool
    @Binding var totemCaptured: Bool
    @Binding var isLoading: Bool

    // State variables for storing the totem feature prints
    @State private var capturedFeaturePrints: [VNFeaturePrintObservation] = []
    @State private var requiredCaptureCount = 5 // Play with this
    @State private var showInvalidImageMessage = false
    @State private var invalidImageMessageTimer: Timer?
    @State private var scanningState: TotemScanningState = .capture
    @State private var similarityScore: Double = 0.0
    @State private var totemName: String = ""
    @State private var showingNameInput = false
    @State private var capturedImages: [UIImage] = []
    @State private var hasTriggeredNameInput = false // Prevent alert from showing multiple times

    var similarityThreshold: Double = 0.3 // Play with this

    // Unified camera manager
    @StateObject private var cameraManager = UnifiedCameraManager()
    
    var body: some View {
        VStack(spacing: 15) {
            Spacer()

            if case .success = scanningState, let totem = savedTotem {
                // START Success view
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Great job!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Your totem '\(totem.name)' has been saved")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Total totems saved: \(totems.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Fan of captured images from the saved totem
                    ZStack {
                        let images = totem.getImages()
                        let totalImages = images.count
                        let maxAngle = min(45.0, 90.0 / Double(max(1, totalImages - 1))) // Limit total spread to 90 degrees
                        
                        ForEach(images.indices, id: \.self) { index in
                            Image(uiImage: images[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                .rotationEffect(.degrees(
                                    Double(index - (totalImages - 1) / 2) * maxAngle
                                ))
                                .offset(x: Double(index - (totalImages - 1) / 2) * 15)
                                .zIndex(Double(index))
                        }
                    }
                    .frame(height: 120)
                    .padding(.horizontal, 40)
                    
                    Text("Captured from \(totem.images.count) angles")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: {
                        // Delete all existing totems
                        for totem in totems {
                            modelContext.delete(totem)
                        }
                        try? modelContext.save()

                        // Reset the entire process
                        totemCaptured = false
                        capturedFeaturePrints = []
                        scanningState = .capture
                        totemName = ""
                        capturedImages = []
                        savedTotem = nil
                        hasTriggeredNameInput = false // Reset flag

                        // Restart camera in capture mode
                        isScanning = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            cameraManager.switchMode(to: .capture) { _ in
                                isScanning = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Start Over")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical, 20)
                
                Spacer()
                // END Success View
            } else {
                // START Header View
                VStack(spacing: 15) {
                    Text("Let's Capture Your Totem")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    (Text("Take ")
                     + Text("at least \(requiredCaptureCount)").bold().foregroundColor(.black)
                     + Text(" pictures of your totem from different angles"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)
                // END Header View
                
                // START Camera view
                VStack(spacing: 15) {
                    Text(capturedFeaturePrints.isEmpty ?
                         "Center your totem in the frame and tap the camera" :
                         scanningState == .capture ?
                         "Take 'Picture \(capturedFeaturePrints.count + 1)' from a different angle" :
                         ""
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    
                    // Camera view for capturing totem image
                    HStack(alignment: .center) {
                        Spacer()

                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .frame(width: 200, height: 200)
                            } else if isScanning {
                                // Use unified camera view for both modes
                                ZStack {
                                    UnifiedCameraView(
                                        cameraManager: cameraManager,
                                        mode: scanningState == .capture ? .capture : .verification,
                                        onTapToCapture: scanningState == .capture ? captureImage : nil,
                                        onVerificationResult: scanningState == .capture ? nil : { score in
                                            similarityScore = score
                                            if score >= similarityThreshold && !hasTriggeredNameInput {
                                                hasTriggeredNameInput = true
                                                showingNameInput = true
                                            } else if score < similarityThreshold && !hasTriggeredNameInput {
                                                showInvalidImageMessage = true
                                                invalidImageMessageTimer?.invalidate()
                                                invalidImageMessageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                                    showInvalidImageMessage = false
                                                }
                                            }
                                        },
                                        referenceFeaturePrints: capturedFeaturePrints,
                                        verificationThreshold: similarityThreshold,
                                        captureFrequency: 0.2
                                    )
                                    .frame(width: 200, height: 200)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                scanningState == .capture ? Color.blue :
                                                    Color.blue.opacity(similarityScore <= 0 ? 0.1 : 0.1 + pow(similarityScore / similarityThreshold, 2) * 0.9),
                                                lineWidth: scanningState == .capture ? 3 : (similarityScore <= 0 ? 3 : 3 + (similarityScore / similarityThreshold) * 3)
                                            )
                                    )

                                    // Overlay for capture mode
                                    if scanningState == .capture {
                                        ZStack {
                                            Image(systemName: "camera.shutter.button")
                                                .font(.system(size: 60))
                                                .foregroundColor(.blue.opacity(0.2))
                                        }
                                        .allowsHitTesting(false)
                                    }

                                    // Show captured images in capture mode
                                    if scanningState == .capture && !capturedImages.isEmpty {
                                        ZStack {
                                            ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 70, height: 70)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.blue, lineWidth: 2)
                                                    )
                                                    .shadow(radius: 3)
                                                    .rotationEffect(.degrees(index % 2 == 0 ?
                                                        Double((index + 1) * 7) :
                                                        Double((index + 1) * -7)))
                                                    .offset(x: 120)
                                            }
                                        }
                                    }
                                }
                            } else {
                                // Placeholder when not scanning
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black.opacity(0.05))
                                        .frame(width: 200, height: 200)

                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 80))
                                        .foregroundColor(Color.blue.opacity(0.3))
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: 3)
                                )
                            }
                        }

                        Spacer()
                    }
                    
                    if scanningState == .verification {
                        if showInvalidImageMessage {
                            /*
                            Text("Totem not yet recognized")
                                .font(.body)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                             */
                        }

                        Button(action: {
                            // Switch back to capture mode
                            scanningState = .capture
                            similarityScore = 0
                            hasTriggeredNameInput = false // Reset flag
                        }) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                Text("Add More Photos")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.top, 10)
                    } else {
                        // Show progress of captures
                        HStack(spacing: 8) {
                            // Show first 3 dots
                            ForEach(0..<requiredCaptureCount, id: \.self) { index in
                                Circle()
                                    .fill(index < capturedFeaturePrints.count ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 12, height: 12)
                            }
                            
                            // Show count of additional photos
                            if capturedFeaturePrints.count > 3 {
                                Text("+\(capturedFeaturePrints.count - 3)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.leading, 4)
                            }
                        }
                        .padding(.top, 5)
                    }
                }
                // End Camera View
                
                // START Body view
                if capturedFeaturePrints.count >= requiredCaptureCount {
                    VStack(spacing: 10) {
                        Text("Take more pictures or verify your totem")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 15) {
                            Button(action: {
                                // Switch to verification mode
                                scanningState = .verification
                                similarityScore = 0
                                hasTriggeredNameInput = false // Reset flag when starting verification
                            }) {
                                Text("Verify Totem")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue.opacity(scanningState == .capture ? 1.0 : 0.5))
                                    .cornerRadius(10)
                            }
                            .disabled(scanningState != .capture)
                            /*
                            Button(action: captureImage) {
                                Text("Take More Pictures")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                            }
                            */
                        }
                        
                        Button(action: {
                            // Reset the captured feature prints to allow retaking the photos
                            capturedFeaturePrints = []
                            capturedImages = []
                            scanningState = .capture
                            similarityScore = 0
                            hasTriggeredNameInput = false // Reset flag
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Start Over")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.top, 5)
                    }
                    .padding(.top, 10)
                    .frame(minHeight: 150)
                } else {
                    /*
                    Button(action: captureImage) {
                        Text(capturedFeaturePrints.isEmpty ? "Capture Totem" : "Capture Angle \(capturedFeaturePrints.count + 1)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                    .disabled(!isScanning) // Disable the button if not scanning
                    */
                    Spacer()
                        .frame(height: 150)
                }
                // END Body view
            }
        }
        .padding(.horizontal, 30)
        .onAppear {
            // Camera automatically starts via UnifiedCameraView
            isScanning = true
        }
        .alert("Name Your Totem", isPresented: $showingNameInput) {
            TextField("Totem Name", text: $totemName)
            Button("Cancel", role: .cancel) {
                // Reset to verification mode to try again
                totemName = ""
                scanningState = .verification
                similarityScore = 0
                hasTriggeredNameInput = false // Allow alert to show again if verified again
            }
            Button("Save") {
                saveTotem()
            }
            .disabled(totemName.trimmingCharacters(in: .whitespaces).isEmpty)
        } message: {
            Text("Give your totem a name to help you remember what object to use.")
        }
    }
    
    // MARK: - Actions
    
    private func captureImage() {
        guard isScanning else {
            #if DEBUG
            print("⚠️ Not scanning, ignoring capture")
            #endif
            return
        }

        #if DEBUG
        print("📸 captureImage() triggered")
        #endif
        isLoading = true

        // Use unified camera manager to capture photo
        cameraManager.capturePhoto { result in
            switch result {
            case .success(let image):
                #if DEBUG
                print("✅ Photo captured successfully, size: \(image.size)")
                #endif
                // Save the captured image
                self.capturedImages.append(image)
                #if DEBUG
                print("📦 Total captured images: \(self.capturedImages.count)")
                #endif

                // Process the captured image
                ImageSimilarityHelper.processImage(image) { featurePrint in
                    DispatchQueue.main.async {
                        if let featurePrint = featurePrint {
                            // Add the new feature print to our collection
                            self.capturedFeaturePrints.append(featurePrint)
                            #if DEBUG
                            print("✅ Feature print added. Total: \(self.capturedFeaturePrints.count)")
                            #endif
                        } else {
                            #if DEBUG
                            print("❌ Failed to generate feature print")
                            #endif
                            // Show error if feature print generation failed
                            self.showInvalidImageMessage = true
                            self.invalidImageMessageTimer?.invalidate()
                            self.invalidImageMessageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                self.showInvalidImageMessage = false
                            }
                            // Remove the last captured image since feature print generation failed
                            self.capturedImages.removeLast()
                        }
                        self.isLoading = false
                    }
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    #if DEBUG
                    print("❌ Error capturing photo: \(error.localizedDescription)")
                    #endif
                    self.showInvalidImageMessage = true
                    self.invalidImageMessageTimer?.invalidate()
                    self.invalidImageMessageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                        self.showInvalidImageMessage = false
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveTotem() {
        #if DEBUG
        print("💾 Saving totem with name: '\(totemName)'")
        print("💾 Feature prints: \(capturedFeaturePrints.count), Images: \(capturedImages.count)")
        #endif

        // Convert all captured images to JPEG data
        let imageDataArray = capturedImages.map { $0.jpegData(compressionQuality: 0.7) }

        // Create and save the totem model
        let totem = TotemModel(
            name: totemName,
            featurePrints: capturedFeaturePrints,
            imageDataArray: imageDataArray.compactMap { $0 } // Remove any nil values
        )

        // Delete all old totems BEFORE inserting new one
        #if DEBUG
        print("🗑️ Deleting \(totems.count) old totem(s)")
        #endif
        for oldTotem in totems {
            #if DEBUG
            print("🗑️ Deleting: \(oldTotem.name)")
            #endif
            modelContext.delete(oldTotem)
        }

        // Insert the new totem into the model context
        modelContext.insert(totem)

        // Set new totem as active
        totem.isActive = true

        do {
            try modelContext.save()
            #if DEBUG
            print("✅ Totem saved successfully to database")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to save totem: \(error)")
            #endif
        }

        // Save reference to the saved totem and transition to success state
        savedTotem = totem
        scanningState = .success

        // Stop camera to prevent further verification triggers
        isScanning = false
        cameraManager.stopSession()

        // Auto-complete registration after successful save
        totemCaptured = true
        #if DEBUG
        print("✅ Totem saved and registration marked complete")
        #endif
    }
}

struct TotemScanningPageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TotemScanningPageView(isScanning: .constant(true), totemCaptured: .constant(false), isLoading: .constant(false))
                .modelContainer(for: TotemModel.self)
        }
    }
    
    static var previewsWithCaptures: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: TotemModel.self, configurations: config)
        
        // Create a sample totem with some captures
        let sampleTotem = TotemModel(name: "Preview Totem", featurePrints: [], imageDataArray: [
            UIImage(systemName: "photo")!.jpegData(compressionQuality: 0.7)!,
            UIImage(systemName: "photo.fill")!.jpegData(compressionQuality: 0.7)!,
            UIImage(systemName: "photo.circle")!.jpegData(compressionQuality: 0.7)!
        ])
        container.mainContext.insert(sampleTotem)
        
        return NavigationView {
            TotemScanningPageView(isScanning: .constant(true), totemCaptured: .constant(false), isLoading: .constant(false))
                .modelContainer(container)
        }
    }
}
