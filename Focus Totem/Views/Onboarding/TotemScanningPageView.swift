//
//  TotemScanningPageView.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 14/03/25.
//

import SwiftUI
import Vision
import AVFoundation

struct TotemScanningPageView: View {
    @Binding var isScanning: Bool
    @Binding var totemCaptured: Bool
    @Binding var isLoading: Bool
    
    // State variables for storing the totem feature print
    @State private var capturedFeaturePrint: VNFeaturePrintObservation?
    @State private var showInvalidImageMessage = false
    @State private var invalidImageMessageTimer: Timer?
    @State private var isCaptureMode = true
    @State private var similarityScore: Double = 0.0
    
    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            
            if totemCaptured {
                // Success view
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Great job!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Your totem has been saved. Tap 'Done' to start.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        // Reset the entire process
                        totemCaptured = false
                        capturedFeaturePrint = nil
                        isCaptureMode = true
                        
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
            } else {
                Text("Let's Capture Your Totem")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Take a picture of an object that will be your focus totem")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Camera view for capturing totem image
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 200, height: 200)
                    } else if isScanning {
                        // In capture mode, we just show the camera and save the feature print on capture
                        if isCaptureMode {
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
                        } else if let featurePrint = capturedFeaturePrint {
                            // In verification mode, we use the similarity scanner to verify the capture worked
                            ImageSimilarityScanner(
                                isScanning: isScanning,
                                similarityScore: $similarityScore,
                                referenceFeaturePrint: featurePrint,
                                threshold: 0.5,
                                onInvalidMatch: {
                                    showInvalidImageMessage = true
                                    invalidImageMessageTimer?.invalidate()
                                    invalidImageMessageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                        showInvalidImageMessage = false
                                    }
                                },
                                onValidMatch: { score in
                                    // Successfully verified totem
                                    totemCaptured = true
                                    
                                    // Save feature print to UserDefaults as serialized data
                                    ImageSimilarityHelper.saveFeaturePrintToUserDefaults(featurePrint)
                                }
                            )
                            .frame(width: 200, height: 200)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .inset(by: showInvalidImageMessage ? -4 : 0)
                                    .stroke(showInvalidImageMessage ? .red : .blue, 
                                        lineWidth: showInvalidImageMessage ? 6 : 3)
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
                .padding(.top, 20)
                
                if !isCaptureMode {
                    if showInvalidImageMessage {
                        Text("Please try to frame your totem object better")
                            .font(.body)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 5) {
                            Text("Show your totem in the frame to verify")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Similarity: \(String(format: "%.2f", similarityScore))")
                                .font(.caption)
                                .foregroundColor(similarityScore > 0.3 ? (similarityScore > 0.5 ? .green : .orange) : .gray)
                        }
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
                            Image(systemName: "arrow.counterclockwise")
                            Text("Recapture")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                } else {
                    if capturedFeaturePrint == nil {
                        Text("Center your totem object in the frame and tap")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: captureImage) {
                            Text("Capture Totem")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)
                        .disabled(!isScanning) // Disable the button if not scanning
                    } else {
                        VStack(spacing: 10) {
                            Text("Now verify that we can recognize your totem")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                // Switch to verification mode
                                isCaptureMode = false
                                
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
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                // Reset the captured feature print to allow retaking the photo
                                capturedFeaturePrint = nil
                                
                                // Restart the camera session to ensure it's ready for the next capture
                                isScanning = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isScanning = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Retake Photo")
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding(.top, 5)
                        }
                        .padding(.top, 10)
                    }
                }
                
                Spacer()
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
    }
    
    // MARK: - Actions
    
    private func captureImage() {
        guard isScanning else { return }
        
        isLoading = true
        
        // Use the CaptureImageViewController directly to take a photo
        CaptureImageViewController.shared.capturePhoto { result in
            switch result {
            case .success(let image):
                // Process the captured image
                ImageSimilarityHelper.processImage(image) { featurePrint in
                    DispatchQueue.main.async {
                        if let featurePrint = featurePrint {
                            self.capturedFeaturePrint = featurePrint
                        } else {
                            // Show error if feature print generation failed
                            self.showInvalidImageMessage = true
                            self.invalidImageMessageTimer?.invalidate()
                            self.invalidImageMessageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                self.showInvalidImageMessage = false
                            }
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
