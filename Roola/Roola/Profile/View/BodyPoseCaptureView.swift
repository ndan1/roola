//
//  BodyPoseCaptureView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 29/10/25.
//

import SwiftUI
import UIKit

struct BodyPoseCaptureView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (UIImage, BodyMeasurements) -> Void
    
    func makeUIViewController(context: Context) -> PoseCaptureViewController {
        let controller = PoseCaptureViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PoseCaptureViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PoseCaptureDelegate {
        let parent: BodyPoseCaptureView
        
        init(_ parent: BodyPoseCaptureView) {
            self.parent = parent
        }
        
        func didCaptureValidPose(image: UIImage, measurements: BodyMeasurements) {
            parent.onCapture(image, measurements)
        }
    }
}
