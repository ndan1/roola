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
            
            Text("Analyzing photo...")
                .font(.body18Medium)
                .bold()
                .padding(.top, 10)
        }
        .padding()
        .task {
            // 3. Get height from SwiftData (default to 170 if missing)
            let userHeight = Double(users.first?.height ?? 170)
            
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
            onBack: { viewModel.retryMeasurement() },
            onInfo: { print("info")}
        )
        .overlay {
            if showSuccessPopup {
                SuccessPopupView {
                    withAnimation { showSuccessPopup = false }
                }
                .task {
                    await viewModel.measurementDidFinish(data: data, modelContext: modelContext)
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
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
        // --- UPDATE PREVIEW ---
        onFlowDidFinish: { print("Flow Finished") },
        onSwitchToManual: { print("Switch to Manual") }
    )
    .modelContainer(for: User.self, inMemory: true)
}
