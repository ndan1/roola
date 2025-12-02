//
//  CameraFlowContainerView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 09/11/25.
//

import SwiftUI
import AVFoundation
import SwiftData

struct CameraFlowContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var users: [User]
    
    @State private var path = NavigationPath()
    
    // State for Modal
    @State private var showBodySizeModal = false
    @State private var tempHeight: Int?
    @State private var tempWeight: Int?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // Main Content
                CameraTutorialView(
                    onContinue: { checkCameraPermissionFirst() },
                    showBodySizeModal: $showBodySizeModal
                )
                
                // Modal Overlay
                if showBodySizeModal {
                    SaveBodySizeModal(
                        isPresented: $showBodySizeModal,
                        height: $tempHeight,
                        weight: $tempWeight,
                        onSave: {
                            saveBodyDataAndProceed()
                        }
                    )
                    .zIndex(1)
                }
            }
            .toolbar(showBodySizeModal ? .hidden : .visible, for: .navigationBar)
            .navigationDestination(for: FlowStep.self) { step in
                switch step {
                case .capture:
                    MeasurementFlowView(
                        onFlowDidFinish: { dismiss() },
                        onSwitchToManual: { dismiss() },
                        onRetake: {
                            if !path.isEmpty {
                                path.removeLast()
                            }
                        }
                    )
                    .navigationBarHidden(true)
                case .permissionDenied:
                    CameraPermissionDeniedView(
                        onCancel: { dismiss() },
                        onOpenSettings: openSettings
                    )
                    .navigationBarHidden(true)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
        .background(FirstGradientBackground().ignoresSafeArea())
        .onChange(of: showBodySizeModal) { oldValue, newValue in
            if !newValue {
                resetTempData()
            }
        }
    }

    // MARK: - Helper Functions
    
    private func resetTempData() {
        tempHeight = nil
        tempWeight = nil
    }
    
    private func checkCameraPermissionFirst() {
        // 1. PRE-FILL LOGIC:
        // Check UserDefaults first (most recent temp entry), then SwiftData (saved user)
        let storedHeight = UserDefaults.standard.integer(forKey: "temp_user_height")
        let storedWeight = UserDefaults.standard.integer(forKey: "temp_user_weight")
        
        if storedHeight > 0 {
            self.tempHeight = storedHeight
        } else if let existingUser = users.first, existingUser.height > 0 {
            self.tempHeight = existingUser.height
        }
        
        if storedWeight > 0 {
            self.tempWeight = storedWeight
        } else if let existingUser = users.first, existingUser.weight > 0 {
            self.tempWeight = existingUser.weight
        }
        
        // Show modal
        showBodySizeModal = true
    }

    // Logic to save temporarily to UserDefaults
    private func saveBodyDataAndProceed() {
        // 2. SAVE LOGIC:
        if let h = tempHeight {
            UserDefaults.standard.setValue(h, forKey: "temp_user_height")
        }
        if let w = tempWeight {
            UserDefaults.standard.setValue(w, forKey: "temp_user_weight")
        }
        
        print("✅ Height & Weight stored in UserDefaults: \(tempHeight ?? 0), \(tempWeight ?? 0)")
        
        // Check Camera Permission
        checkCameraPermission { granted in
            if granted {
                path.append(FlowStep.capture)
            } else {
                path.append(FlowStep.permissionDenied)
            }
        }
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

private enum FlowStep: Hashable {
    case capture
    case permissionDenied
}

#Preview {
    CameraFlowContainerView()
        .modelContainer(for: User.self, inMemory: true)
}
