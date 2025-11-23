//
//  OnboardingFlowView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 11/11/25.
//

import SwiftUI
import SwiftData
import AVFoundation

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var users: [User]
    @Binding var isOnboardingComplete: Bool
    
    @State private var path = NavigationPath()
    @State private var isReturningFromSettings = false
    
    // Modal States
    @State private var showBodySizeModal = false
    @State private var tempHeight: Int?
    @State private var tempWeight: Int?
    
    init(isOnboardingComplete: Binding<Bool>) {
        self._isOnboardingComplete = isOnboardingComplete
        self._users = Query()
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            OnboardingPage(
                onAI: { path.append(OnboardingStep.ai) },
                onInput: { path.append(OnboardingStep.manual) }
            )
            .navigationBarHidden(true)
            .navigationDestination(for: OnboardingStep.self) { step in
                switch step {
                case .ai:
                    ZStack {
                        CameraTutorialView {
                            showBodySizeModal = true
                        }
                        
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
                    // Tidak perlu navigationBarHidden(true) jika ingin navbar muncul di tutorial
                    
                case .manual:
                    UserInputView()
                }
            }
            .navigationDestination(for: FlowStep.self) { step in
                switch step {
                case .capture:
                    MeasurementFlowView(
                        onFlowDidFinish: {
                            // Tidak perlu melakukan apa-apa disini secara manual,
                            // Karena begitu MeasurementFlowView menyimpan data (bust/waist),
                            // ContentView akan otomatis mendeteksi user.isOnboardingFinished = true
                            // dan mengganti halaman.
                        },
                        onSwitchToManual: {
                            path.removeLast(path.count)
                            path.append(OnboardingStep.manual)
                        })
                    .navigationBarHidden(true)
                    
                case .permissionDenied:
                    CameraPermissionDeniedView(
                        onCancel: {
                            if !path.isEmpty { path.removeLast() }
                        },
                        onOpenSettings: openSettings
                    )
                    .navigationBarHidden(true)
                }
            }
        }
    }
    // MARK: - Helper Save untuk Onboarding
    private func saveBodyDataAndProceed() {
        let user = users.first ?? User(waist: 0)
        user.height = tempHeight ?? 0
        user.weight = tempWeight ?? 0
        
        // Saat ini disimpan, 'user.isOnboardingFinished' MASIH FALSE (karena bust/waist 0).
        // Jadi ContentView TIDAK AKAN pindah halaman. Aman.
        
        if users.isEmpty {
            modelContext.insert(user)
        }
        
        try? modelContext.save()
        
        checkCameraPermission { granted in
            if granted {
                path.append(FlowStep.capture)
            } else {
                path.append(FlowStep.permissionDenied)
            }
        }
    }
    
    private func finishOnboarding() {
        // Ini dipanggil oleh MeasurementFlowView saat semua animasi selesai
        withAnimation {
            isOnboardingComplete = true
        }
    }
    
    private func saveUser(_ user: User) {
        modelContext.insert(user)
        try? modelContext.save()
        withAnimation {
            isOnboardingComplete = true
        }
    }

    // MARK: - Camera Logic (Moved from CameraFlowContainerView)

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default: completion(false)
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Navigation payloads
private enum FlowStep: Hashable {
    case capture
    case permissionDenied
}

private enum OnboardingStep: Hashable {
    case ai
    case manual
}
