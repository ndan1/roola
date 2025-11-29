//
//  MeasurementFlowView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 09/11/25.
//

import SwiftUI
import SwiftData

struct MeasurementFlowView: View {
    @StateObject private var viewModel = MeasurementFlowViewModel()
    
    // 1. Access Model Context and Query User
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    @State private var showSuccessPopup = false

    var onFlowDidFinish: () -> Void
    var onSwitchToManual: () -> Void
    // New closure to handle navigation pop
    var onRetake: () -> Void

    var body: some View {
        ZStack {
            switch viewModel.flowState {
            case .capturing:
                BodyPoseCaptureView { image, measurements in
                    viewModel.didCaptureImage(image)
                }
                .ignoresSafeArea()
                
            case .loading(let image):
                // 2. Pass image AND height to loading view
                loadingView(image: image)
                
            case .success(let data):
                successResultView(data: data)
                
            case .error(let message):
                errorView(message: message)
                
            case .successAnimation:
                successAnimationView()
            }
        }.safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
    }
    
    private func loadingView(image: UIImage) -> some View {
            VStack(spacing: 20) {
                GradientCircularLoader()
                
                Text("Getting your measurements..")
                    .font(.body18Medium)
                    .bold()
                    .padding(.top, 10)
            }
            .padding()
            .task {
                // UPDATED LOGIC:
                // 1. Try to get height from UserDefaults (Temp)
                // 2. If 0/nil, Fallback to SwiftData User
                // 3. If missing, default to 170
                
                let tempHeight = UserDefaults.standard.integer(forKey: "temp_user_height")
                let existingHeight = users.first?.height ?? 0
                
                let userHeight = Double(tempHeight > 0 ? tempHeight : (existingHeight > 0 ? existingHeight : 170))
                
                print("📏 Using Height for API: \(userHeight)")

                // 4. Call VM with both image and height
                await viewModel.startMeasurementTask(image: image, userHeight: userHeight)
            }
        }
    
    private func errorView(message: String) -> some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                FailedState(label: message)
                Spacer(minLength: 120)
            }

            VStack(spacing: 10) {
                RoolaButton(
                    buttonTitle: "Retake",
                    buttonColor: AppColors.primaryPurple,
                    action: {
                        // Note: You can also use onRetake() here if you want
                        // error retries to pop back to container as well.
                        viewModel.retryMeasurement()
                    }
                )
                .frame(width: UIScreen.main.bounds.width * 0.8)

                RoolaButton(
                    buttonTitle: "Input Manually",
                    buttonColor: AppColors.primaryWhite,
                    action: {
                        onSwitchToManual()
                    }
                )
                .frame(width: UIScreen.main.bounds.width * 0.8)
            }
            .padding(.bottom, 25)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func successAnimationView() -> some View {
        VStack(spacing: 20) {
            SuccesState(label: "Your measurement result is ready")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            await viewModel.successAnimationDidFinish()
        }
    }
    
    private func successResultView(data: MeasurementData) -> some View {
        MeasurementResultView(
            data: data,
            onDone: { withAnimation { showSuccessPopup = true } },
            // UPDATED: Call the external onRetake closure to pop the view
            onBack: { onRetake() },
            onInfo: { print("info")}
        )
        .overlay {
            if showSuccessPopup {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    SuccessPopupView(onDismiss: {})
                }
                .transition(.opacity)
                .zIndex(1)
                .task {
                    // MARK: - LOGIC FIX
                    
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 Detik
                    
                    await viewModel.measurementDidFinish(data: data, modelContext: modelContext)
                    
                    await MainActor.run {
                        withAnimation { showSuccessPopup = false }
                        onFlowDidFinish()
                    }
                }
            }
        }
    }
}

#Preview {
    MeasurementFlowView(
        onFlowDidFinish: { print("Flow Finished") },
        onSwitchToManual: { print("Switch to Manual") },
        onRetake: { print("Pop Navigation") }
    )
    .modelContainer(for: User.self, inMemory: true)
}
