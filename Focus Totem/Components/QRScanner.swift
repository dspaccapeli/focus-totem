//
//  QRSCanner.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 13/03/25.
//

import SwiftUI
import VisionKit

struct QRScanner: View {
    let isScanning: Bool
    @Binding var lastScannedValue: String
    
    // Default validation function checks if the URL host matches validHost
    var validateQRCode: (String) -> Bool
    var onInvalidQR: (() -> Void)?
    var onValidQR: ((String) -> Void)?
    
    // Initialize with default validation that checks URL host
    init(
        isScanning: Bool,
        lastScannedValue: Binding<String>,
        validHost: String,
        onInvalidQR: (() -> Void)? = nil,
        onValidQR: ((String) -> Void)? = nil
    ) {
        self.isScanning = isScanning
        self._lastScannedValue = lastScannedValue
        self.validateQRCode = { scannedValue in
            guard let url = URL(string: scannedValue),
                  url.host == validHost else {
                return false
            }
            return true
        }
        self.onInvalidQR = onInvalidQR
        self.onValidQR = onValidQR
    }
    
    // Initialize with custom validation function
    init(
        isScanning: Bool,
        lastScannedValue: Binding<String>,
        validateQRCode: @escaping (String) -> Bool,
        onInvalidQR: (() -> Void)? = nil,
        onValidQR: ((String) -> Void)? = nil
    ) {
        self.isScanning = isScanning
        self._lastScannedValue = lastScannedValue
        self.validateQRCode = validateQRCode
        self.onInvalidQR = onInvalidQR
        self.onValidQR = onValidQR
    }
    
    var body: some View {
        DataScannerView(
            isScanning: isScanning,
            recognizedDataType: .barcode(symbologies: [.qr]),
            onScan: { scannedValue in
                lastScannedValue = scannedValue
                
                if validateQRCode(scannedValue) {
                    onValidQR?(scannedValue)
                } else {
                    onInvalidQR?()
                }
            }
        )
    }
}

struct DataScannerView: UIViewControllerRepresentable {
    let isScanning: Bool
    let recognizedDataType: DataScannerViewController.RecognizedDataType
    
    // Callback for when a QR code is scanned
    var onScan: (String) -> Void
    
    // Optional configuration parameters
    var isGuidanceEnabled: Bool = false
    var isHighlightingEnabled: Bool = true
    var recognizesMultipleItems: Bool = false
    var qualityLevel: DataScannerViewController.QualityLevel = .fast
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [recognizedDataType],
            qualityLevel: qualityLevel,
            recognizesMultipleItems: recognizesMultipleItems,
            isGuidanceEnabled: isGuidanceEnabled,
            isHighlightingEnabled: isHighlightingEnabled
        )
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning {
            try? uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        
        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            processRecognizedItem(item)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let firstItem = addedItems.first else { return }
            processRecognizedItem(firstItem)
        }
        
        private func processRecognizedItem(_ item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let payload = barcode.payloadStringValue {
                    onScan(payload)
                }
            default:
                break
            }
        }
    }
}
