//
//  MeasurementFlowView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 09/11/25.
//

import SwiftUI

struct MeasurementFlowView: View {
    @State private var pendingMeasurementData: MeasurementData?
    
    enum FlowState: Equatable {
        case capturing
        case loading(videoURL: URL)
        case successAnimation
        case success(data: MeasurementData)
        case error(message: String)
        
        static func == (lhs: FlowState, rhs: FlowState) -> Bool {
            switch (lhs, rhs) {
            case (.capturing, .capturing),
                 (.loading, .loading),
                 (.successAnimation, .successAnimation),
                 (.success, .success),
                 (.error, .error):
                return true
            default:
                return false
            }
        }
    }
    
    @State private var flowState: FlowState = .success(data: MeasurementData(
        armsLength: 49.21,
        chestCircumference: 92,
        height: 169,
        torsoLength: 54,
        waistCircumference: 82)
    )
//    @State private var flowState: FlowState = .loading(videoURL: URL(fileURLWithPath: "/Users/hcarlo/Desktop/test.mp4"))
    
    private let service = MeasureService()

    var body: some View {
        ZStack {
            // The view's content switches based on the current flow state
            switch flowState {
            case .capturing:
                BodyPoseCaptureView { videoURL, measurements in
                    self.flowState = .loading(videoURL: videoURL)
                }
                .ignoresSafeArea()
            case .loading(let videoURL):
                loadingView(videoURL: videoURL)
            case .success(let data):
                MeasurementResultView(data: data) {
                    flowState = .capturing
                }
            case .error(let message):
                errorView(message: message)
            case .successAnimation:
                successAnimationView()
            }
        }
    }
    
    /// The initial view with a button to start the process
    private var idleView: some View {
        VStack {
            Text("Start Measurement")
                .font(.title)
            Button("Start") {
                flowState = .capturing
            }
            .buttonStyle(.borderedProminent)
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
            await startMeasurementTask(url: videoURL)
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
                        flowState = .capturing
                    }
                )
                .frame(width: UIScreen.main.bounds.width * 0.8)

                RoolaButton(
                    buttonTitle: "Input Manually",
                    buttonColor: AppColors.primaryWhite,
                    action: { }
                )
                .frame(width: UIScreen.main.bounds.width * 0.8)
            }
            .padding(.bottom, 25)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    /// The async function that calls the MeasureService
    private func startMeasurementTask(url: URL) async {
        do {
            // 1. Call your service (this is the same as in MeasureTestView)
            let resultDictionary = try await service.getMeasurement(from: url)
            
            // 2. Convert the dictionary [String: Any] to JSON Data
            let jsonData = try JSONSerialization.data(withJSONObject: resultDictionary)
            
            // 3. Use JSONDecoder to parse the Data into our Codable structs
            let response = try JSONDecoder().decode(MeasurementResponse.self, from: jsonData)
            
            // 4. Check the API's internal status
            if response.output.status == "success" {
                await MainActor.run {
                    pendingMeasurementData = response.output.measurements
                    flowState = .successAnimation
                }
            }
            // Check for a specific maintenance status
            else if response.output.status == "maintenance" {
                // 5a. API returned a maintenance status
                await MainActor.run {
                    flowState = .error(message: "Server is under maintenance. Please try again later.")
                }
            }
            else {
                // 5b. API returned a different non-success status
                await MainActor.run {
                    flowState = .error(message: "API processing failed. Status: \(response.output.status)")
                }
            }
            
        } catch let error as MeasureServiceError {
            // 5c. The service itself threw an error (e.g., timeout)
            await MainActor.run {
                flowState = .error(message: "Service Error: \(error.localizedDescription)")
            }
        } catch {
            // 5d. Any other error (e.g., JSON parsing)
            await MainActor.run {
                flowState = .error(message: "An unknown error occurred: \(error.localizedDescription)")
            }
        }
        
        // Clean up the captured video file from the temp directory
        try? FileManager.default.removeItem(at: url)
    }
    
    private func successAnimationView() -> some View {
        VStack(spacing: 20) {
            SuccesState(label: "Your measurement result is ready")
            
            // Optional: subtle fade-in/out
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if let data = pendingMeasurementData {
                await MainActor.run {
                    flowState = .success(data: data)
                    pendingMeasurementData = nil
                }
            }
        }
    }
}

#Preview {
    MeasurementFlowView()
}
