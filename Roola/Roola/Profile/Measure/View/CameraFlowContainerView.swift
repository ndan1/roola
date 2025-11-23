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
    @Environment(\.modelContext) private var modelContext // 2. Access Context
    
    // 3. Query Existing User
    @Query private var users: [User]
    
    @State private var path = NavigationPath()
    
    // 4. State untuk Modal
    @State private var showBodySizeModal = false
    @State private var tempHeight: Int?
    @State private var tempWeight: Int?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // 5. Content Utama
                CameraTutorialView {
                    // Saat klik Continue, JANGAN langsung cek permission.
                    // Munculkan modal dulu.
                    showBodySizeModal = true
                }
                
                // 6. Modal Overlay
                if showBodySizeModal {
                    SaveBodySizeModal(
                        isPresented: $showBodySizeModal,
                        height: $tempHeight,
                        weight: $tempWeight,
                        onSave: {
                            saveBodyData()
                        }
                    )
                    .zIndex(1) // Pastikan di atas
                }
            }
            // .navigationBarHidden(true) // Opsional: Hapus/Comment jika ingin native navbar
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
        // 7. Load data existing saat view muncul
        .onAppear {
            if let user = users.first {
                tempHeight = user.height > 0 ? user.height : nil
                tempWeight = user.weight > 0 ? user.weight : nil
            }
        }
    }

    // 8. Logic Penyimpanan Data
    private func saveBodyData() {
        let user = users.first ?? User(waist: 0) // Ambil user lama atau buat baru sementara
        
        user.height = tempHeight ?? 0
        user.weight = tempWeight ?? 0
        
        if users.isEmpty {
            modelContext.insert(user)
        }
        
        try? modelContext.save()
        print("✅ Height & Weight Saved: \(user.height), \(user.weight)")
        
        // 9. Setelah save sukses, BARU lanjut ke flow kamera
        proceedToCamera()
    }
    
    private func proceedToCamera() {
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

// MARK: - Navigation payload
private enum FlowStep: Hashable {
    case capture
    case permissionDenied
}

#Preview {
    CameraFlowContainerView()
        .modelContainer(for: User.self, inMemory: true)
}
