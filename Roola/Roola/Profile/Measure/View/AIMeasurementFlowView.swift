//
//  MeasurementFlowView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 09/11/25.
//

import SwiftUI

struct AIMeasurementFlowView: View {
    
    enum FlowState: Equatable {
        case capturing
        case loading(videoURL: URL)
        case success(data: MeasurementData)
        case error(message: String)
        
        static func == (lhs: FlowState, rhs: FlowState) -> Bool {
            switch (lhs, rhs) {
            case (.capturing, .capturing):
                return true
            case (.loading, .loading):
                return true
            case (.success, .success):
                return true
            case (.error, .error):
                return true
            default:
                return false
            }
        }
    }

    
    @State private var flowState: FlowState = .capturing
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
                    // "Done" button action
                    flowState = .capturing
                }
            case .error(let message):
                errorView(message: message)
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
                            .padding(.top, 10)                .bold()
                .padding(.top, 10)
        }
        .padding()
        .task {
            await startMeasurementTask(url: videoURL)
        }
    }
    
    /// The view to show if the API call fails
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 97))
                .foregroundColor(AppColors.grayScale300)

            Text("Measurement Failed")
                .font(.title)
                .bold()

            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            Button("Try Again") {
                flowState = .capturing
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 40)
        }
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
                // 5. Success! Update the flow state to show the results
                await MainActor.run {
                    flowState = .success(data: response.output.measurements)
                }
            } else {
                // 5a. API returned a non-success status
                await MainActor.run {
                    flowState = .error(message: "API processing failed. Status: \(response.output.status)")
                }
            }
            
        } catch let error as MeasureServiceError {
            // 5b. The service itself threw an error (e.g., timeout)
            await MainActor.run {
                flowState = .error(message: "Service Error: \(error.localizedDescription)")
            }
        } catch {
            // 5c. Any other error (e.g., JSON parsing)
            await MainActor.run {
                flowState = .error(message: "An unknown error occurred: \(error.localizedDescription)")
            }
        }
        
        // Clean up the captured video file from the temp directory
        try? FileManager.default.removeItem(at: url)
    }
}

#Preview {
    AIMeasurementFlowView()
}
