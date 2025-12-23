//
//  UnifiedCameraView.swift
//  Focus Totem
//
//  Created by Claude on 23/12/25.
//

import SwiftUI
import Vision

/// SwiftUI wrapper for UnifiedCameraManager
struct UnifiedCameraView: UIViewControllerRepresentable {
    @ObservedObject var cameraManager: UnifiedCameraManager
    let mode: UnifiedCameraManager.CameraMode

    // Capture mode callback
    var onTapToCapture: (() -> Void)?

    // Verification mode callbacks
    var onVerificationResult: ((Double) -> Void)?
    var referenceFeaturePrints: [VNFeaturePrintObservation] = []
    var verificationThreshold: Double = 0.7
    var captureFrequency: Double = 0.5

    func makeUIViewController(context: Context) -> UnifiedCameraViewController {
        let viewController = UnifiedCameraViewController(cameraManager: cameraManager)
        viewController.onTapToCapture = onTapToCapture
        return viewController
    }

    func updateUIViewController(_ uiViewController: UnifiedCameraViewController, context: Context) {
        // Update tap gesture callback
        uiViewController.onTapToCapture = onTapToCapture

        // Prevent duplicate mode switches
        if context.coordinator.isSwitchingMode {
            return
        }

        // Handle mode switching ONLY when mode actually changes
        if cameraManager.currentMode != mode && !context.coordinator.isSwitchingMode {
            print("🔄 Mode change detected: \(cameraManager.currentMode) → \(mode)")
            context.coordinator.isVerificationActive = false
            context.coordinator.isSwitchingMode = true

            cameraManager.switchMode(to: mode) { [weak coordinator = context.coordinator] result in
                defer {
                    coordinator?.isSwitchingMode = false
                }

                switch result {
                case .success:
                    if mode == .verification {
                        cameraManager.startVerification(
                            referenceFeaturePrints: referenceFeaturePrints,
                            threshold: verificationThreshold,
                            captureFrequency: captureFrequency,
                            onResult: { similarity in
                                onVerificationResult?(similarity)
                            }
                        )
                        coordinator?.isVerificationActive = true
                    } else {
                        cameraManager.stopVerification()
                        coordinator?.isVerificationActive = false
                    }
                case .failure(let error):
                    print("❌ Failed to switch camera mode: \(error)")
                }
            }
        } else if mode == .verification && !context.coordinator.isVerificationActive {
            // First time entering verification mode - set it up
            print("🔄 Starting verification for the first time")
            cameraManager.startVerification(
                referenceFeaturePrints: referenceFeaturePrints,
                threshold: verificationThreshold,
                captureFrequency: captureFrequency,
                onResult: { similarity in
                    onVerificationResult?(similarity)
                }
            )
            context.coordinator.isVerificationActive = true
        }
        // Otherwise do nothing - verification is already running
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var isVerificationActive = false
        var isSwitchingMode = false
    }
}

/// UIViewController wrapper for UnifiedCameraManager
class UnifiedCameraViewController: UIViewController {
    let cameraManager: UnifiedCameraManager
    var onTapToCapture: (() -> Void)?
    var onVerificationResult: ((Double) -> Void)?

    init(cameraManager: UnifiedCameraManager) {
        self.cameraManager = cameraManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up preview view
        cameraManager.previewView = view

        // Setup camera session if not already set up
        if cameraManager.captureSession == nil {
            cameraManager.setupSession { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    print("📹 Camera session setup completed")
                    // Configure initial mode (capture by default) then start
                    self.cameraManager.switchMode(to: .capture) { modeResult in
                        switch modeResult {
                        case .success:
                            self.cameraManager.startSession()
                        case .failure(let error):
                            print("❌ Failed to set initial mode: \(error)")
                        }
                    }
                case .failure(let error):
                    print("❌ Camera setup failed: \(error)")
                }
            }
        } else if !cameraManager.isSessionRunning {
            // Session already set up, just start it
            cameraManager.startSession()
        }

        // Add tap gesture for capture mode
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraManager.updatePreviewLayerFrame(view.bounds)
    }

    // Don't auto-manage session lifecycle in viewDidAppear/viewWillDisappear
    // SwiftUI view updates can trigger these methods during state changes,
    // causing unwanted session restarts and freezes

    @objc private func handleTap() {
        onTapToCapture?()
    }
}
