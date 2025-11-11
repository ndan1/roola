//
//  CameraFlowContainerView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 09/11/25.
//

import SwiftUI
import AVFoundation

enum CameraFlowStep {
    case tutorial
    case capture
    case permissionDenied
}

struct CameraFlowContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: CameraFlowStep = .tutorial
    
    let onComplete: (URL, BodyMeasurements) -> Void
    
    var body: some View {
        ZStack {
            switch currentStep {
                
            case .tutorial:
                CameraTutorialView(onContinue: {
                    checkCameraPermissionAndProceed()
                })
                .transition(.move(edge: .trailing))
                
            case .capture:
                BodyPoseCaptureView { videoURL, measurements in
                    onComplete(videoURL, measurements)
                    dismiss()
                }
                .transition(.move(edge: .trailing))
                
            case .permissionDenied:
                CameraPermissionDeniedView(
                    onCancel: {
                        dismiss()
                    },
                    onOpenSettings: {
                        openSettings()
                    }
                )
                .transition(.move(edge: .trailing))
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func checkCameraPermissionAndProceed() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            withAnimation {
                currentStep = .capture
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    withAnimation {
                        currentStep = granted ? .capture : .permissionDenied
                    }
                }
            }
        case .denied, .restricted:
            withAnimation {
                currentStep = .permissionDenied
            }
        @unknown default:
            withAnimation {
                currentStep = .permissionDenied
            }
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
