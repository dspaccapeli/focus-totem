//
//  UnifiedCameraManager.swift
//  Focus Totem
//
//  Created by Claude on 23/12/25.
//

import SwiftUI
import AVFoundation
import Vision

/// Unified camera manager that handles both photo capture and continuous verification
class UnifiedCameraManager: NSObject, ObservableObject {

    // MARK: - Types

    enum CameraMode {
        case capture    // Photo capture mode
        case verification  // Continuous scanning for verification
    }

    enum CameraError: Error {
        case sessionNotRunning
        case captureSessionBusy
        case outputConfigurationFailed
        case noCamera
    }

    // MARK: - Properties

    @Published private(set) var currentMode: CameraMode = .capture
    @Published private(set) var isSessionRunning = false

    var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var deviceInput: AVCaptureDeviceInput?

    // Background queue for camera operations
    private let sessionQueue = DispatchQueue(label: "com.focustotem.camera.session")
    private let videoDataQueue = DispatchQueue(label: "com.focustotem.camera.video")

    // Verification mode properties
    private var referenceFeaturePrints: [VNFeaturePrintObservation] = []
    private var verificationThreshold: Double = 0.7
    private var captureFrequency: Double = 0.5
    private var lastCaptureTime: TimeInterval = 0
    private var onVerificationResult: ((Double) -> Void)?

    // Capture mode properties
    private var photoCaptureCompletion: ((Result<UIImage, Error>) -> Void)?

    // View reference for preview layer
    weak var previewView: UIView? {
        didSet {
            if let view = previewView, let layer = previewLayer {
                view.layer.addSublayer(layer)
                layer.frame = view.bounds
            }
        }
    }

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Session Setup

    func setupSession(completion: @escaping (Result<Void, Error>) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            let session = AVCaptureSession()
            self.captureSession = session

            // Get camera device
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                DispatchQueue.main.async {
                    completion(.failure(CameraError.noCamera))
                }
                return
            }

            // Create input
            guard let input = try? AVCaptureDeviceInput(device: camera) else {
                DispatchQueue.main.async {
                    completion(.failure(CameraError.noCamera))
                }
                return
            }

            // Configure session
            session.beginConfiguration()

            if session.canAddInput(input) {
                session.addInput(input)
                self.deviceInput = input
            }

            session.commitConfiguration()

            // Setup preview layer on main thread
            DispatchQueue.main.async {
                let preview = AVCaptureVideoPreviewLayer(session: session)
                preview.videoGravity = .resizeAspectFill
                self.previewLayer = preview

                if let view = self.previewView {
                    view.layer.addSublayer(preview)
                    preview.frame = view.bounds
                }

                completion(.success(()))
            }
        }
    }

    // MARK: - Session Control

    func startSession(completion: (() -> Void)? = nil) {
        sessionQueue.async { [weak self] in
            guard let self = self, let session = self.captureSession else {
                DispatchQueue.main.async { completion?() }
                return
            }

            if !session.isRunning {
                session.startRunning()
                print("📹 Camera session started in \(self.currentMode) mode")

                DispatchQueue.main.async {
                    self.isSessionRunning = true
                    completion?()
                }
            } else {
                DispatchQueue.main.async { completion?() }
            }
        }
    }

    func stopSession(completion: (() -> Void)? = nil) {
        sessionQueue.async { [weak self] in
            guard let self = self, let session = self.captureSession else {
                DispatchQueue.main.async { completion?() }
                return
            }

            if session.isRunning {
                session.stopRunning()
                print("📹 Camera session stopped")

                DispatchQueue.main.async {
                    self.isSessionRunning = false
                    completion?()
                }
            } else {
                DispatchQueue.main.async { completion?() }
            }
        }
    }

    // MARK: - Mode Switching

    func switchMode(to mode: CameraMode, completion: @escaping (Result<Void, Error>) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self, let session = self.captureSession else {
                DispatchQueue.main.async {
                    completion(.failure(CameraError.sessionNotRunning))
                }
                return
            }

            print("📹 Switching camera mode: \(self.currentMode) → \(mode)")

            // Stop session first
            let wasRunning = session.isRunning
            if wasRunning {
                session.stopRunning()
                // Give time for session to fully stop
                Thread.sleep(forTimeInterval: 0.3)
            }

            // Reconfigure outputs
            session.beginConfiguration()

            // Remove existing outputs
            if let photoOutput = self.photoOutput {
                session.removeOutput(photoOutput)
                self.photoOutput = nil
            }

            if let videoOutput = self.videoDataOutput {
                session.removeOutput(videoOutput)
                self.videoDataOutput = nil
            }

            // Configure for new mode
            switch mode {
            case .capture:
                let output = AVCapturePhotoOutput()
                if session.canAddOutput(output) {
                    session.addOutput(output)
                    self.photoOutput = output
                    print("📹 Photo output configured")
                } else {
                    session.commitConfiguration()
                    DispatchQueue.main.async {
                        completion(.failure(CameraError.outputConfigurationFailed))
                    }
                    return
                }

            case .verification:
                let output = AVCaptureVideoDataOutput()
                output.setSampleBufferDelegate(self, queue: self.videoDataQueue)

                if session.canAddOutput(output) {
                    session.addOutput(output)
                    self.videoDataOutput = output
                    print("📹 Video output configured for verification")
                } else {
                    session.commitConfiguration()
                    DispatchQueue.main.async {
                        completion(.failure(CameraError.outputConfigurationFailed))
                    }
                    return
                }
            }

            session.commitConfiguration()

            // Update mode
            DispatchQueue.main.async {
                self.currentMode = mode
            }

            // Restart session if it was running
            if wasRunning {
                session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                    print("📹 Camera session restarted in \(mode) mode")
                    completion(.success(()))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Capture Mode

    func capturePhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
        print("📸 capturePhoto() called")
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            print("📸 Current mode: \(self.currentMode), photoOutput exists: \(self.photoOutput != nil), session running: \(self.captureSession?.isRunning ?? false)")

            guard self.currentMode == .capture else {
                print("❌ Not in capture mode")
                DispatchQueue.main.async {
                    completion(.failure(CameraError.captureSessionBusy))
                }
                return
            }

            guard let photoOutput = self.photoOutput,
                  let session = self.captureSession,
                  session.isRunning else {
                print("❌ Photo output or session not ready")
                DispatchQueue.main.async {
                    completion(.failure(CameraError.sessionNotRunning))
                }
                return
            }

            self.photoCaptureCompletion = completion

            print("📸 Capturing photo with AVCapturePhotoOutput")
            DispatchQueue.main.async {
                let settings = AVCapturePhotoSettings()
                photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    // MARK: - Verification Mode

    func startVerification(
        referenceFeaturePrints: [VNFeaturePrintObservation],
        threshold: Double = 0.7,
        captureFrequency: Double = 0.5,
        onResult: @escaping (Double) -> Void
    ) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.referenceFeaturePrints = referenceFeaturePrints
            self.verificationThreshold = threshold
            self.captureFrequency = captureFrequency
            self.onVerificationResult = onResult
            self.lastCaptureTime = 0

            print("📹 Verification started with \(referenceFeaturePrints.count) reference prints")
        }
    }

    func stopVerification() {
        sessionQueue.async { [weak self] in
            self?.onVerificationResult = nil
            self?.referenceFeaturePrints = []
            print("📹 Verification stopped")
        }
    }

    // MARK: - Preview Layer Management

    func updatePreviewLayerFrame(_ frame: CGRect) {
        DispatchQueue.main.async { [weak self] in
            self?.previewLayer?.frame = frame
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension UnifiedCameraManager: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoCaptureCompletion?(.failure(error))
            photoCaptureCompletion = nil
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            let error = NSError(
                domain: "UnifiedCameraManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create image from captured data"]
            )
            photoCaptureCompletion?(.failure(error))
            photoCaptureCompletion = nil
            return
        }

        print("📸 Photo captured successfully")
        photoCaptureCompletion?(.success(image))
        photoCaptureCompletion = nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension UnifiedCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastCaptureTime >= captureFrequency else { return }
        lastCaptureTime = currentTime

        guard !referenceFeaturePrints.isEmpty else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Process the image buffer to compute similarity
        computeImageSimilarity(pixelBuffer: pixelBuffer) { [weak self] similarity in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.onVerificationResult?(similarity)
            }
        }
    }

    private func computeImageSimilarity(pixelBuffer: CVPixelBuffer, completion: @escaping (Double) -> Void) {
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try handler.perform([request])

            guard let featurePrintObservation = request.results?.first as? VNFeaturePrintObservation else {
                completion(0.0)
                return
            }

            let similarityScore = ImageSimilarityHelper.computeMaxSimilarity(
                currentFeaturePrint: featurePrintObservation,
                againstStoredPrints: referenceFeaturePrints
            )

            print("🔍 Similarity: \(String(format: "%.4f", similarityScore)) (threshold: \(verificationThreshold))")
            completion(similarityScore)
        } catch {
            print("❌ Error computing similarity: \(error)")
            completion(0.0)
        }
    }
}
