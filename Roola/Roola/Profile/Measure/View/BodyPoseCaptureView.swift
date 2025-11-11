//
//  BodyPoseCaptureView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 29/10/25.
//

// This is the SwiftUI view that wraps your UIViewController
// (You might have named it 'BodyPoseCaptureView' or something similar)

import SwiftUI

struct BodyPoseCaptureView: UIViewControllerRepresentable {
    
    @Environment(\.dismiss) private var dismiss // <-- 1. Get SwiftUI's dismiss action
    
    // This is the closure that gets called on success
    var onCaptureComplete: (URL, BodyMeasurements) -> Void
    
    // This connects your delegate
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // This creates the UIKit View Controller
    func makeUIViewController(context: Context) -> PoseCaptureViewController {
        let vc = PoseCaptureViewController()
        vc.delegate = context.coordinator // For success
        
        // --- THIS IS THE FIX ---
        // 2. Tell the VC what to do when its back button is tapped
        vc.onBackButtonTapped = {
            dismiss() // Call the SwiftUI dismiss action
        }
        // -----------------------
        
        return vc
    }
    
    // This is required, but you likely don't need to add anything
    func updateUIViewController(_ uiViewController: PoseCaptureViewController, context: Context) {
        // ...
    }
    
    // MARK: - Coordinator
    // This coordinator handles the 'didCaptureVideo' delegate method
    class Coordinator: NSObject, PoseCaptureDelegate {
        var parent: BodyPoseCaptureView
        
        init(_ parent: BodyPoseCaptureView) {
            self.parent = parent
        }
        
        func didCaptureVideo(videoURL: URL, measurements: BodyMeasurements) {
            parent.onCaptureComplete(videoURL, measurements)
        }
    }
}
