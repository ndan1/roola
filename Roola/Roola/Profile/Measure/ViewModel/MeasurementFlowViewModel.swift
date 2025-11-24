//
//  MeasurementFlowViewModel.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 10/11/25.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class MeasurementFlowViewModel: ObservableObject {
    
    // MARK: - State
    @Published var flowState: FlowState = .capturing
    
    enum FlowState: Equatable {
        case capturing
        case loading(image: UIImage)
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
    
    // MARK: - Properties
    private var pendingMeasurementData: MeasurementData?
    private let service: MeasureService
    
    init(service: MeasureService = MeasureService()) {
        self.service = service
    }
    
    // MARK: - Public Methods
    
    func didCaptureImage(_ image: UIImage) {
        self.flowState = .loading(image: image)
    }
    
    func retryMeasurement() {
        self.flowState = .capturing
    }

    func successAnimationDidFinish() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 sec delay for animation
        
        if let data = pendingMeasurementData {
            self.flowState = .success(data: data)
            self.pendingMeasurementData = nil
        } else {
            self.flowState = .error(message: "An unexpected error occurred (missing data).")
        }
    }

    /// Process the image and call API
    /// - Parameters:
    ///   - image: The captured UIImage
    ///   - userHeight: The height (in cm) from the User model
    func startMeasurementTask(image: UIImage, userHeight: Double) async {
        
        // 1. Convert UIImage to Data
        // Compression 0.8 is usually a good balance for API uploads
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            self.flowState = .error(message: "Failed to process image data.")
            return
        }
        
        do {
            // 2. Call the API (using your new MeasureService signature)
            let responseDict = try await service.getMeasurement(imageData: imageData, height: userHeight)
            
            // 3. Parse the Dictionary Response
            // We need to drill down into the JSON structure.
            // Assuming structure: { "output": { "chest": 90, ... }, "status": "COMPLETED" }
            
            guard let output = responseDict["output"] as? [String: Any] else {
                // If status is not success, check for error message
                if let status = responseDict["status"] as? String, status == "FAILED" {
                    self.flowState = .error(message: "Analysis failed. Please try a clearer photo.")
                } else {
                    self.flowState = .error(message: "Invalid response from server.")
                }
                return
            }
            
            // 4. Map JSON to MeasurementData
            // Use helper to safely extract Double/Int from JSON
            let data = MeasurementData(
                        armsLength: parseDouble(output["arms_length"]),
                        chestCircumference: parseDouble(output["chest_circumference"]),
                        height: userHeight,
                        torsoLength: parseDouble(output["torso_length"]),
                        waistCircumference: parseDouble(output["waist_circumference"])
                    )
            
            self.pendingMeasurementData = data
            self.flowState = .successAnimation
            
        } catch let error as MeasureServiceError {
            switch error {
            case .timeout:
                self.flowState = .error(message: "The process timed out. Please try again.")
            case .serverError(let msg):
                self.flowState = .error(message: "Server Error: \(msg)")
            default:
                self.flowState = .error(message: "Connection error. Please check internet.")
            }
        } catch {
            self.flowState = .error(message: "An unknown error occurred: \(error.localizedDescription)")
        }
    }
    
    // Helper to handle JSON numbers which might be Int or Double
    private func parseDouble(_ value: Any?) -> Double {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let str = value as? String, let d = Double(str) { return d }
        return 0.0
    }

    func measurementDidFinish(data: MeasurementData, modelContext: ModelContext) async {
        saveOrUpdateUser(with: data, in: modelContext)
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        self.flowState = .capturing
    }
    
    private func saveOrUpdateUser(with data: MeasurementData, in context: ModelContext) {
        let descriptor = FetchDescriptor<User>()
        do {
            if let userToUpdate = try context.fetch(descriptor).first {
                userToUpdate.bust = Int(data.chestCircumference.rounded())
                userToUpdate.waist = Int(data.waistCircumference.rounded())
                userToUpdate.torso = Int(data.torsoLength.rounded())
                userToUpdate.arms_length = Int(data.armsLength.rounded())
            } else {
                // Fallback creation (shouldn't happen if flow is correct)
                let newUser = User(
                    bust: Int(data.chestCircumference.rounded()),
                    waist: Int(data.waistCircumference.rounded()),
                    torso: Int(data.torsoLength.rounded()),
                    arms_length: Int(data.armsLength.rounded())
                )
                newUser.height = Int(data.height)
                context.insert(newUser)
            }
            try context.save()
        } catch {
            print("Failed to save user: \(error)")
        }
    }
}
