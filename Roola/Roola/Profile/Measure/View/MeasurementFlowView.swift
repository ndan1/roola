//
//  MeasurementFlowView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 09/11/25.
//

import SwiftUI

import SwiftUI

struct MeasurementFlowView: View {
    // 1. Create and observe the ViewModel
    @StateObject private var viewModel = MeasurementFlowViewModel()
    @Environment(\.modelContext) private var modelContext
    
    @State private var showSuccessPopup = false

    var body: some View {
        ZStack {
            // 2. Switch on the ViewModel's published state
            switch viewModel.flowState {
            case .capturing:
                BodyPoseCaptureView { videoURL, measurements in
                    // 3. Call the ViewModel method instead of setting state
                    viewModel.didCaptureVideo(videoURL: videoURL)
                }
                .ignoresSafeArea()
                
            case .loading(let videoURL):
                loadingView(videoURL: videoURL)
                
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
    
    /// The loading view shown after capture. It automatically starts the API call.
    private func loadingView(videoURL: URL) -> some View {
        VStack(spacing: 20) {
            GradientCircularLoader()
            
            Text("Getting your measurements...")
                .font(.body18Medium)
                .bold()
                .padding(.top, 10)
        }
        .padding()
        .task {
            // 3. Call the ViewModel's async task
            await viewModel.startMeasurementTask(url: videoURL)
        }
    }
    
    /// The view to show if the API call fails
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
                        // 3. Call the ViewModel method
                        viewModel.retryMeasurement()
                    }
                )
                .frame(width: UIScreen.main.bounds.width * 0.8)

                RoolaButton(
                    buttonTitle: "Input Manually",
                    buttonColor: AppColors.primaryWhite,
                    action: {
                        // TODO: You would add a new method to the ViewModel
                        // e.g., viewModel.switchToManualInput()
                    }
                )
                .frame(width: UIScreen.main.bounds.width * 0.8)
            }
            .padding(.bottom, 25)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    /// The success animation view
    private func successAnimationView() -> some View {
        VStack(spacing: 20) {
            SuccesState(label: "Your measurement result is ready")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            // 3. Call the ViewModel method
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
                    // called after the 2‑second delay
                    withAnimation { showSuccessPopup = false }
                }
                .task {
                    // 1. Save immediately
                    await viewModel.measurementDidFinish(data: data, modelContext: modelContext)
                    
                    // 2. Wait 2 seconds → then auto‑dismiss
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        withAnimation { showSuccessPopup = false }
                    }
                }
            }
        }
    }
}

#Preview {
    MeasurementFlowView()
        // 9. Add the model container for the preview to work
        .modelContainer(for: User.self, inMemory: true)
}
