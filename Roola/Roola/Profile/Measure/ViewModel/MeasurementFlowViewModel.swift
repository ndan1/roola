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
    
    // The View will listen to this property for all UI changes
//    @Published var flowState: FlowState = .capturing
    @Published var flowState: FlowState = .success(data: MeasurementData(
                    armsLength: 49.21,
                    chestCircumference: 92,
                    height: 169,
                    torsoLength: 54,
                    waistCircumference: 82))
    
    // This enum now lives inside the ViewModel for encapsulation
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
    
    // MARK: - Properties

    private var pendingMeasurementData: MeasurementData?
    private let service: MeasureService
    
    // MARK: - Init
    
    init(service: MeasureService = MeasureService()) {
        self.service = service
        
        // Uncomment this to test success/error states directly
//        self.flowState = .success(data: MeasurementData(
//            armsLength: 49.21,
//            chestCircumference: 92,
//            height: 169,
//            torsoLength: 54,
//            waistCircumference: 82)
//        )
    }
    
    // MARK: - Public Methods (Intents from View)
    
    /// Called by the View when video capture is complete
    func didCaptureVideo(videoURL: URL) {
        self.flowState = .loading(videoURL: videoURL)
    }
    
    /// Called by the View's "Try Again" button
    func retryMeasurement() {
        self.flowState = .capturing
    }

    /// Called by the success animation view when it's done
    func successAnimationDidFinish() async {
        // This is the logic from the .task in the old successAnimationView
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        if let data = pendingMeasurementData {
            self.flowState = .success(data: data)
            self.pendingMeasurementData = nil
        } else {
            // Failsafe in case data is missing
            self.flowState = .error(message: "An unexpected error occurred (missing data).")
        }
    }

    /// The async function that calls the MeasureService
    func startMeasurementTask(url: URL) async {
        do {
            // 1. Call your service
            let resultDictionary = try await service.getMeasurement(from: url)
            
            // 2. Convert to JSON
            let jsonData = try JSONSerialization.data(withJSONObject: resultDictionary)
            
            // 3. Parse
            let response = try JSONDecoder().decode(MeasurementResponse.self, from: jsonData)
            
            // 4. Check status
            if response.output.status == "success" {
                // 5. Success! Store data and trigger animation
                self.pendingMeasurementData = response.output.measurements
                self.flowState = .successAnimation
                
            } else if response.output.status == "maintenance" {
                // 5a. Maintenance
                self.flowState = .error(message: "Server is under maintenance. Please try again later.")
                
            } else {
                // 5b. Other API failure
                self.flowState = .error(message: "API processing failed. Status: \(response.output.status)")
            }
            
        } catch let error as MeasureServiceError {
            // 5c. Service error
            self.flowState = .error(message: "Service Error: \(error.localizedDescription)")
            
        } catch {
            // 5d. Any other error
            self.flowState = .error(message: "An unknown error occurred: \(error.localizedDescription)")
        }
        
        // Clean up the captured video file from the temp directory
        try? FileManager.default.removeItem(at: url)
    }

    private func saveOrUpdateUser(with data: MeasurementData, in context: ModelContext) {
        let descriptor = FetchDescriptor<User>()
        
        do {
            if let userToUpdate = try context.fetch(descriptor).first {
                // --- CASE 2: UPDATE EXISTING USER ---
                print("Updating existing user...")
                
                userToUpdate.height = Int(data.height.rounded())
                userToUpdate.bust = Int(data.chestCircumference.rounded())
                userToUpdate.waist = Int(data.waistCircumference.rounded())
                userToUpdate.torso = Int(data.torsoLength.rounded())
                userToUpdate.arms_length = Int(data.armsLength.rounded())
            } else {
                // --- CASE 1: NO PREVIOUS DATA (CREATE NEW) ---
                print("Creating new user...")
                
                let newUser = User(
                    height: Int(data.height.rounded()),
                    bust: Int(data.chestCircumference.rounded()),
                    waist: Int(data.waistCircumference.rounded()),
                    torso: Int(data.torsoLength.rounded()),
                    arms_length: Int(data.armsLength.rounded())
                )
                // Insert the new object into the context
                context.insert(newUser)
            }
            
            // Explicitly save for reliability on real devices
            try context.save()
            print("Save successful")
            
        } catch {
            print("Failed to fetch or save user: \(error)")
        }
    }

    func measurementDidFinish(data: MeasurementData, modelContext: ModelContext) async {
        saveOrUpdateUser(with: data, in: modelContext)
        
        // Sleep here to give the popup time to show before resetting state
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        self.flowState = .capturing
    }
}
