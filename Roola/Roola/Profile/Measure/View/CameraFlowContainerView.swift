//
//  CameraFlowContainerView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 09/11/25.
//

import SwiftUI
import AVFoundation

struct CameraFlowContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            CameraTutorialView {
                // User tapped Continue → check permission then push capture
                checkCameraPermission { granted in
                    if granted {
                        path.append(FlowStep.capture)
                    } else {
                        path.append(FlowStep.permissionDenied)
                    }
                }
            }
            .navigationDestination(for: FlowStep.self) { step in
                switch step {
                case .capture:
                    MeasurementFlowView(onSwitchToManual: {})
                        .navigationBarHidden(true)
                case .permissionDenied:
                    CameraPermissionDeniedView(
                        onCancel: { dismiss() },
                        onOpenSettings: openSettings
                    )
                }
            }
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
        .background(FirstGradientBackground().ignoresSafeArea())
    }

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Navigation payload
private enum FlowStep: Hashable {
    case capture
    case permissionDenied
}

#Preview {
    CameraFlowContainerView()
}
