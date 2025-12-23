//
//  ImageSimilarityScanner.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 18/03/25.
//

import SwiftUI
import Vision
import AVFoundation

struct ImageSimilarityScanner: View {
    let isScanning: Bool
    @Binding var similarityScore: Double
    let referenceFeaturePrint: VNFeaturePrintObservation?
    let referenceFeaturePrints: [VNFeaturePrintObservation]
    
    // Default threshold for deciding what is a valid match
    var threshold: Double
    var onInvalidMatch: (() -> Void)?
    var onValidMatch: ((Double) -> Void)?
    var captureFrequency: Double // Capture frequency in seconds
        
    // Initialize with default configuration
    init(
        isScanning: Bool,
        similarityScore: Binding<Double>,
        referenceFeaturePrint: VNFeaturePrintObservation?,
        threshold: Double = 0.7,
        captureFrequency: Double = 0.5,
        onInvalidMatch: (() -> Void)? = nil,
        onValidMatch: ((Double) -> Void)? = nil
    ) {
        self.isScanning = isScanning
        self._similarityScore = similarityScore
        self.referenceFeaturePrint = referenceFeaturePrint
        self.referenceFeaturePrints = referenceFeaturePrint != nil ? [referenceFeaturePrint!] : []
        self.threshold = threshold
        self.captureFrequency = captureFrequency
        self.onInvalidMatch = onInvalidMatch
        self.onValidMatch = onValidMatch
    }
    
    // Initialize with multiple reference feature prints
    init(
        isScanning: Bool,
        similarityScore: Binding<Double>,
        referenceFeaturePrints: [VNFeaturePrintObservation],
        threshold: Double = 0.7,
        captureFrequency: Double = 0.5,
        onInvalidMatch: (() -> Void)? = nil,
        onValidMatch: ((Double) -> Void)? = nil
    ) {
        self.isScanning = isScanning
        self._similarityScore = similarityScore
        self.referenceFeaturePrint = referenceFeaturePrints.first
        self.referenceFeaturePrints = referenceFeaturePrints
        self.threshold = threshold
        self.captureFrequency = captureFrequency
        self.onInvalidMatch = onInvalidMatch
        self.onValidMatch = onValidMatch
    }
    
    var body: some View {
        VStack {
            CameraView(
                isScanning: isScanning,
                referenceFeaturePrints: referenceFeaturePrints,
                threshold: threshold,
                onImageCaptured: { similarity in
                    similarityScore = similarity
                    
                    if similarity >= threshold {
                        onValidMatch?(similarity)
                    } else {
                        onInvalidMatch?()
                    }
                },
                captureFrequency: captureFrequency
            )
            // Text("Similarity Score: \(String(format: "%.4f", similarityScore))")
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    let isScanning: Bool
    let referenceFeaturePrints: [VNFeaturePrintObservation]
    let threshold: Double
    var onImageCaptured: (Double) -> Void
    
    // Optional configuration parameters
    var captureFrequency: Double = 0.5 // Capture frames every 0.5 seconds
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController(
            referenceFeaturePrints: referenceFeaturePrints,
            captureFrequency: captureFrequency,
            threshold: threshold,
            onImageCaptured: onImageCaptured
        )
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var referenceFeaturePrints: [VNFeaturePrintObservation]
    private var lastCaptureTime: TimeInterval = 0
    private var captureFrequency: Double
    private var threshold: Double
    private var onImageCaptured: (Double) -> Void
    
    init(referenceFeaturePrints: [VNFeaturePrintObservation], captureFrequency: Double, threshold: Double, onImageCaptured: @escaping (Double) -> Void) {
        self.referenceFeaturePrints = referenceFeaturePrints
        self.captureFrequency = captureFrequency
        self.threshold = threshold
        self.onImageCaptured = onImageCaptured
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
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
        
        // Setup video data output
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if let videoDataOutput = videoDataOutput, captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
    }
    
    func startScanning() {
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    func stopScanning() {
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastCaptureTime >= captureFrequency else { return }
        lastCaptureTime = currentTime
        
        guard !referenceFeaturePrints.isEmpty else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Process the image buffer to compute the similarity
        computeImageSimilarity(pixelBuffer: pixelBuffer, referenceFeaturePrints: referenceFeaturePrints) { [weak self] similarity in
            DispatchQueue.main.async {
                self?.onImageCaptured(similarity)
            }
        }
    }
    
    private func computeImageSimilarity(pixelBuffer: CVPixelBuffer, referenceFeaturePrints: [VNFeaturePrintObservation], completion: @escaping (Double) -> Void) {
        // Create a new request to compute the feature print of the current frame
        let request = VNGenerateImageFeaturePrintRequest()
        
        // Create a new handler with the pixel buffer
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            // Perform the request
            try handler.perform([request])
            
            // Verify we have a result
            guard let featurePrintObservation = request.results?.first as? VNFeaturePrintObservation else {
                completion(0.0)
                return
            }
            
            // Calculate the maximum similarity across all reference feature prints
            let similarityScore = ImageSimilarityHelper.computeMaxSimilarity(
                currentFeaturePrint: featurePrintObservation,
                againstStoredPrints: referenceFeaturePrints
            )
            
            // Print the similarity score to the console for debugging
            #if DEBUG
            print("🔍 Totem similarity score: \(String(format: "%.4f", similarityScore)) (threshold: \(threshold))")
            #endif
            
            completion(similarityScore)
        } catch {
            print("Error computing image similarity: \(error)")
            completion(0.0)
        }
    }
}

// Helper class to generate a feature print from a UIImage
class ImageSimilarityHelper {
    static func generateFeaturePrint(from image: UIImage, completion: @escaping (VNFeaturePrintObservation?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()
        
        do {
            try requestHandler.perform([request])
            if let featurePrint = request.results?.first as? VNFeaturePrintObservation {
                completion(featurePrint)
            } else {
                completion(nil)
            }
        } catch {
            print("Error generating feature print: \(error)")
            completion(nil)
        }
    }
    
    // Process an image to generate a feature print
    static func processImage(_ image: UIImage, completion: @escaping (VNFeaturePrintObservation?) -> Void) {
        // Generate feature print from captured image
        generateFeaturePrint(from: image) { featurePrint in
            completion(featurePrint)
        }
    }
    
    // Compute maximum similarity against all stored feature prints
    static func computeMaxSimilarity(currentFeaturePrint: VNFeaturePrintObservation, againstStoredPrints: [VNFeaturePrintObservation]) -> Double {
        var maxSimilarity = 0.0
        
        for storedPrint in againstStoredPrints {
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
