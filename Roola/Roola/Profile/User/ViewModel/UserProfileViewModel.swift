//
//  UserProfileViewModel.swift
//  Roola
//
//  Created by Lin Dan Christiano on 08/11/25.
//

import Foundation
import SwiftUI

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var showingEditSheet = false
    @Published var showingCameraFlow = false
    @Published var capturedVideoURL: URL?
    
    func startCameraFlow() {
        showingCameraFlow = true
    }
    
    func handleCaptureComplete(videoURL: URL, measurements: BodyMeasurements) {
        self.capturedVideoURL = videoURL
        print("📹 Video captured: \(videoURL)")
        print("📏 Measurements: armSpan=\(measurements.armSpan), shoulderWidth=\(measurements.shoulderWidth), torsoLength=\(measurements.torsoLength)")
        // TODO: Save measurements to SwiftData User model
    }
}
