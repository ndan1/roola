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
    @Query private var history: [MeasurementHistory]
    @Binding var isOnboardingComplete: Bool
    
    // Navigation inside the flow
    @State private var path = NavigationPath()
    @State private var isReturningFromSettings = false
    
    init(isOnboardingComplete: Binding<Bool>) {
        self._isOnboardingComplete = isOnboardingComplete
        self._users = Query()
    }
    
    var body: some View {
        VStack {
            if !users.isEmpty {
                // User already exists → skip onboarding
                MainTabView()
                    .transition(.opacity)
            } else {
                NavigationStack(path: $path) {
                    OnboardingPage(
                        onAI: { path.append(OnboardingStep.ai) },
                        onInput: { path.append(OnboardingStep.manual) }
                    )
                    .navigationBarHidden(true)
                    .navigationDestination(for: OnboardingStep.self) { step in
                        switch step {
                        case .ai:
                            CameraTutorialView {
                                checkCameraPermission { granted in
                                    if granted {
                                        path.append(FlowStep.capture)
                                    } else {
                                        path.append(FlowStep.permissionDenied)
                                    }
                                }
                            }
//                            .navigationBarHidden(true)
                        case .manual:
                            UserInputView()
//                            .navigationBarHidden(true)
                        }
                    }
                    .navigationDestination(for: FlowStep.self) { step in
                        switch step {
                        case .capture:
                            MeasurementFlowView(
                                onFlowDidFinish: {},
                                onSwitchToManual: {
                                    path.removeLast(path.count)
                                    path.append(OnboardingStep.manual)
                            })
                            .navigationBarHidden(true)
                        case .permissionDenied:
                            CameraPermissionDeniedView(
                                onCancel: {
                                    if !path.isEmpty {
                                        path.removeLast()
                                    }
                                },
                                onOpenSettings: openSettings
                            )
                            .navigationBarHidden(true)
                        }
                    }
                }
            }
        }
        .animation(.easeInOut, value: users.isEmpty)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Detect when app returns from background (Settings)
            if oldPhase == .background && newPhase == .active {
                print("🔄 [OnboardingFlow] App returned from background")
                isReturningFromSettings = true
                
                // Check if we're on permission denied screen and reset navigation
                if !path.isEmpty {
                    // Clear navigation stack safely to prevent crash
                    DispatchQueue.main.async {
                        path = NavigationPath()
                        print("✅ [OnboardingFlow] Navigation path reset")
                    }
                }
            }
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

// MARK: - Navigation payloads
private enum FlowStep: Hashable {
    case capture
    case permissionDenied
}

private enum OnboardingStep: Hashable {
    case ai
    case manual
}
