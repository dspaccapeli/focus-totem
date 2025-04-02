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
    @State private var isCaptureMode = true
    @State private var similarityScore: Double = 0.0
    @State private var totemName: String = ""
    @State private var showingNameInput = false
    @State private var capturedImages: [UIImage] = []
    
    var similarityThreshold: Double = 0.3 // Play with this
    
    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            
            if totemCaptured, let totem = savedTotem {
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
                        isCaptureMode = true
                        totemName = ""
                        capturedImages = []
                        savedTotem = nil
                        
                        // Ensure we restart the camera
                        isScanning = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isScanning = true
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
                         isCaptureMode ?
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
                                // In capture mode, we just show the camera and save the feature print on capture
                                if isCaptureMode {
                                    ZStack {
                                        CaptureImageView(
                                            isCapturing: isScanning,
                                            onCaptureButtonTapped: captureImage
                                        )
                                        .frame(width: 200, height: 200)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.blue, lineWidth: 3)
                                        )
                                        .overlay(
                                            ZStack {
                                                Image(systemName: "camera.shutter.button")
                                                    .font(.system(size: 60))
                                                    .foregroundColor(.blue.opacity(0.2))
                                            }
                                            .allowsHitTesting(false)
                                        )
                                        
                                        if !capturedImages.isEmpty {
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
                                } else if !capturedFeaturePrints.isEmpty {
                                    // In verification mode, we use the similarity scanner to verify the capture worked
                                    ImageSimilarityScanner(
                                        isScanning: isScanning,
                                        similarityScore: $similarityScore,
                                        referenceFeaturePrints: capturedFeaturePrints,
                                        threshold: similarityThreshold,
                                        captureFrequency: 0.2,
                                        onInvalidMatch: {
                                            showInvalidImageMessage = true
                                            invalidImageMessageTimer?.invalidate()
                                            invalidImageMessageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                                showInvalidImageMessage = false
                                            }
                                        },
                                        onValidMatch: { score in
                                            // Show name input dialog
                                            showingNameInput = true
                                        }
                                    )
                                    .frame(width: 200, height: 200)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .inset(by: showInvalidImageMessage ? -4 : 0)
                                            // .stroke(showInvalidImageMessage ? .red : .blue,
                                            //    lineWidth: showInvalidImageMessage ? 6 : 3)
                                            .stroke(Color.blue.opacity(similarityScore <= 0 ? 0.1 : 0.1 + pow(similarityScore / similarityThreshold, 2) * 0.9),
                                                    lineWidth: similarityScore <= 0 ? 3 : 3 + (similarityScore / similarityThreshold) * 3)
                                    )
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
                    
                    if !isCaptureMode {
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
                            isCaptureMode = true
                            
                            // Ensure we're still scanning when transitioning to capture mode
                            isScanning = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isScanning = true
                            }
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
                                isCaptureMode = false
                                similarityScore = 0 // Reset similarity score for new verification attempt
                                
                                // Ensure we're still scanning when transitioning to verification mode
                                // This is necessary because the camera needs to restart in verification mode
                                isScanning = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isScanning = true
                                }
                            }) {
                                Text("Verify Totem")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue.opacity(isCaptureMode ? 1.0 : 0.5))
                                    .cornerRadius(10)
                            }
                            .disabled(!isCaptureMode)
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
                            isCaptureMode = true  // Ensure we're in capture mode
                            
                            // Restart the camera session to ensure it's ready for the next capture
                            isScanning = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isScanning = true
                            }
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
            // Ensure the camera is initialized when the view appears
            if !isScanning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isScanning = true
                }
            }
        }
        .alert("Name Your Totem", isPresented: $showingNameInput) {
            TextField("Totem Name", text: $totemName)
            Button("Cancel", role: .cancel) {
                totemName = ""
            }
            Button("Save") {
                saveTotem()
            }
        } message: {
            Text("Give your totem a name to help you remember what object to use.")
        }
    }
    
    // MARK: - Actions
    
    private func captureImage() {
        guard isScanning else { return }
        
        isLoading = true
        
        // Use the CaptureImageViewController directly to take a photo
        CaptureImageViewController.shared.capturePhoto { result in
            switch result {
            case .success(let image):
                // Save the captured image
                self.capturedImages.append(image)
                
                // Process the captured image
                ImageSimilarityHelper.processImage(image) { featurePrint in
                    DispatchQueue.main.async {
                        if let featurePrint = featurePrint {
                            // Add the new feature print to our collection
                            self.capturedFeaturePrints.append(featurePrint)
                        } else {
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
                    print("Error capturing photo: \(error.localizedDescription)")
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
        // Convert all captured images to JPEG data
        let imageDataArray = capturedImages.map { $0.jpegData(compressionQuality: 0.7) }
        
        // Create and save the totem model
        let totem = TotemModel(
            name: totemName,
            featurePrints: capturedFeaturePrints,
            imageDataArray: imageDataArray.compactMap { $0 } // Remove any nil values
        )
        
        // Insert the totem into the model context
        modelContext.insert(totem)
        try? modelContext.save()
        
        // Save reference to the saved totem
        savedTotem = totem
        
        // Mark the totem as captured and ready to use
        totemCaptured = true
    }
}

// Simple view for capturing a single image
struct CaptureImageView: UIViewControllerRepresentable {
    let isCapturing: Bool
    var onCaptureButtonTapped: () -> Void
    
    func makeUIViewController(context: Context) -> CaptureImageViewController {
        let vc = CaptureImageViewController.shared
        vc.onTapGesture = onCaptureButtonTapped
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CaptureImageViewController, context: Context) {
        if isCapturing {
            uiViewController.startCapture()
        } else {
            uiViewController.stopCapture()
        }
    }
}

class CaptureImageViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    static let shared = CaptureImageViewController()
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentCaptureCompletion: ((Result<UIImage, Error>) -> Void)?
    var onTapGesture: (() -> Void)?
    
    private override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupCaptureSession()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add tap gesture recognizer for manual capture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        guard let captureSession = self.captureSession else { return }
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
            previewLayer.frame = view.layer.bounds
        }
        
        // Setup photo output
        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
    }
    
    func startCapture() {
        if captureSession?.isRunning == false {
            // Ensure we're starting the capture session on a background thread
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
                
                // Log that the session has started
                DispatchQueue.main.async {
                    print("Camera session started")
                }
            }
        }
    }
    
    func stopCapture() {
        if captureSession?.isRunning == true {
            // Stop the capture session
            captureSession?.stopRunning()
            print("Camera session stopped")
        }
    }
    
    @objc private func handleTap() {
        // Call the tap gesture handler
        onTapGesture?()
    }
    
    func capturePhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let photoOutput = self.photoOutput, captureSession?.isRunning == true else {
            let error = NSError(domain: "CaptureImageViewController", code: 1, userInfo: [NSLocalizedDescriptionKey: "Capture session is not running"])
            completion(.failure(error))
            return
        }
        
        // Store the completion handler for use in the delegate method
        currentCaptureCompletion = completion
        
        // Ensure we're on the main thread
        DispatchQueue.main.async {
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            currentCaptureCompletion?(.failure(error))
            currentCaptureCompletion = nil
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            let error = NSError(domain: "CaptureImageViewController", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from captured data"])
            currentCaptureCompletion?(.failure(error))
            currentCaptureCompletion = nil
            return
        }
        
        currentCaptureCompletion?(.success(image))
        currentCaptureCompletion = nil
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
