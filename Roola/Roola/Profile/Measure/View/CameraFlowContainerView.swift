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
    
    // State untuk Modal
    @State private var showBodySizeModal = false
    @State private var tempHeight: Int?
    @State private var tempWeight: Int?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // Content Utama
                CameraTutorialView(
                    onContinue: { checkCameraPermissionFirst() },
                    showBodySizeModal: $showBodySizeModal
                )
                
                // Modal Overlay - Muncul SETELAH permission granted
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
                        onSwitchToManual: { dismiss() }
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
        // Reset temp data ketika modal ditutup
        .onChange(of: showBodySizeModal) { oldValue, newValue in
            if !newValue {
                resetTempData()
            }
        }
    }

    // MARK: - Helper Functions
    
    // Reset temporary data
    private func resetTempData() {
        tempHeight = nil
        tempWeight = nil
    }
    
    // NEW: Check camera permission first, then show modal
    private func checkCameraPermissionFirst() {
        checkCameraPermission { granted in
            if granted {
                // Permission granted → Show body size modal with EMPTY fields
                showBodySizeModal = true
            } else {
                // Permission denied → Go to denied screen
                path.append(FlowStep.permissionDenied)
            }
        }
    }

    // Logic Penyimpanan Data dan Lanjut ke Capture
    private func saveBodyDataAndProceed() {
        let user = users.first ?? User(waist: 0)
        
        user.height = tempHeight ?? 0
        user.weight = tempWeight ?? 0
        
        if users.isEmpty {
            modelContext.insert(user)
        }
        
        try? modelContext.save()
        print("✅ Height & Weight Saved: \(user.height), \(user.weight)")
        
        // Permission sudah checked, langsung ke capture
        path.append(FlowStep.capture)
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
        .modelContainer(for: User.self, inMemory: true)
}
