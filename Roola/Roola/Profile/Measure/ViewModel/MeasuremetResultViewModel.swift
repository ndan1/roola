//
//  MeasuremetResultViewModel.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 11/11/25.
//

import Foundation
import SwiftUI

class MeasurementResultViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var chest: Int?
    @Published var waist: Int?
    @Published var armLength: Int?
    @Published var torsoLength: Int?
    
    // NEW: Add Height and Weight
    @Published var height: Int?
    @Published var weight: Int?
    
    @Published private(set) var hasAttemptedSave: Bool = false
    
    // MARK: - Stored Properties
    let data: MeasurementData?
    private let onDone: () -> Void
    private let onBack: () -> Void
    let onInfo: () -> Void
    
    // MARK: - Initializer
    init(data: MeasurementData?, userWeight: Int? = nil, onDone: @escaping () -> Void, onBack: @escaping () -> Void, onInfo: @escaping () -> Void) {
        self.data = data
        self.onDone = onDone
        self.onBack = onBack
        self.onInfo = onInfo
        
        if let data = data {
            self.chest = Int(data.chestCircumference)
            self.waist = Int(data.waistCircumference)
            self.armLength = Int(data.armsLength)
            self.torsoLength = Int(data.torsoLength)
            
            // NEW: Initialize Height from data
            self.height = Int(data.height)
            
            // NEW: Initialize Weight from Temp Storage (UserDefaults)
            // We read the same key used in CameraFlowContainerView
            let storedWeight = UserDefaults.standard.integer(forKey: "temp_user_weight")
            if let passedWeight = userWeight, passedWeight > 0 {
                self.weight = passedWeight
            } else {
                self.weight = storedWeight > 0 ? storedWeight : nil
            }
        }
    }
    
    // MARK: - Validation Logic
    
    private func isInvalid(_ value: Int?) -> Bool {
        hasAttemptedSave && (value == nil || (value ?? 0) > 250 || (value ?? 0) <= 0)
    }
    
    var isChestError: Bool { isInvalid(chest) }
    var isWaistError: Bool { isInvalid(waist) }
    var isArmLengthError: Bool { isInvalid(armLength) }
    var isTorsoLengthError: Bool { isInvalid(torsoLength) }
    
    // NEW: Height/Weight Validation
    var isHeightError: Bool { isInvalid(height) }
    var isWeightError: Bool { isInvalid(weight) } // Weight can technically be > 250, but let's keep consistency or adjust logic if needed
    
    var hasError: Bool {
        isChestError || isWaistError || isArmLengthError || isTorsoLengthError || isHeightError || isWeightError
    }
    
    var hasEmptyError: Bool {
        hasAttemptedSave && (
            chest == nil || waist == nil || armLength == nil || torsoLength == nil || height == nil || weight == nil
        )
    }
    
    var isOver250Error: Bool {
        hasAttemptedSave && (
            (chest ?? 0) > 250 || (waist ?? 0) > 250 ||
            (armLength ?? 0) > 250 || (torsoLength ?? 0) > 250 ||
            (height ?? 0) > 250 || (weight ?? 0) > 250
        )
    }
    
    // MARK: - User Intents
    
    func saveTapped() {
        hasAttemptedSave = true
        
        if !hasError {
            // CRITICAL: Update the UserDefaults with the FINAL edited values.
            // This ensures MeasurementFlowViewModel picks up any changes made here.
            if let h = height {
                UserDefaults.standard.setValue(h, forKey: "temp_user_height")
            }
            if let w = weight {
                UserDefaults.standard.setValue(w, forKey: "temp_user_weight")
            }
            
            // Note: Ideally, you should also pass updated Chest/Waist back,
            // but based on current architecture, we are syncing Height/Weight for the save.
            
            onDone()
        }
    }
    
    func retakeTapped() {
        onBack()
    }
}
