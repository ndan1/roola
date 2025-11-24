//
//  BodyPoseCaptureView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 29/10/25.
//

import SwiftUI

struct BodyPoseCaptureView: UIViewControllerRepresentable {
    
    @Environment(\.dismiss) private var dismiss
    
    // UPDATED: Now returns UIImage instead of URL
    var onCaptureComplete: (UIImage, BodyMeasurements) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PoseCaptureViewController {
        let vc = PoseCaptureViewController()
        vc.delegate = context.coordinator
        
        vc.onBackButtonTapped = {
            dismiss()
        }
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: PoseCaptureViewController, context: Context) {
        // ...
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, PoseCaptureDelegate {
        var parent: BodyPoseCaptureView
        
        init(_ parent: BodyPoseCaptureView) {
            self.parent = parent
        }
        
        // UPDATED Delegate method
        func didCapture(image: UIImage, measurements: BodyMeasurements) {
            parent.onCaptureComplete(image, measurements)
        }
    }
}
