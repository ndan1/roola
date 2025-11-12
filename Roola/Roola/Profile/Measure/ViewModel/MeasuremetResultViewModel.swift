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
    // The View will bind to these properties.
    @Published var chest: Int?
    @Published var waist: Int?
    @Published var armLength: Int?
    @Published var torsoLength: Int?
    
    // This is private(set) because only the VM should change it,
    // but the View can read it.
    @Published private(set) var hasAttemptedSave: Bool = false
    
    // MARK: - Stored Properties
    // Keep the original data and navigation closures
    let data: MeasurementData?
    private let onDone: () -> Void
    private let onBack: () -> Void
    let onInfo: () -> Void // Public so the View's Header can use it
    
    // MARK: - Initializer
    init(data: MeasurementData?, onDone: @escaping () -> Void, onBack: @escaping () -> Void, onInfo: @escaping () -> Void) {
        self.data = data
        self.onDone = onDone
        self.onBack = onBack
        self.onInfo = onInfo
        
        // This logic is moved from the View's .onAppear
        // It only runs if data is non-nil, initializing the fields.
        if let data = data {
            self.chest = Int(data.chestCircumference)
            self.waist = Int(data.waistCircumference)
            self.armLength = Int(data.armsLength)
            self.torsoLength = Int(data.torsoLength)
        }
    }
    
    // MARK: - Computed Properties (Validation Logic)
    // All the error-checking logic is moved here from the View.
    
    var isChestError: Bool {
        hasAttemptedSave && ((chest ?? 0) > 250 || chest == nil)
    }
    
    var isWaistError: Bool {
        hasAttemptedSave && ((waist ?? 0) > 250 || waist == nil)
    }
    
    var isArmLengthError: Bool {
        hasAttemptedSave && ((armLength ?? 0) > 250 || armLength == nil)
    }
    
    var isTorsoLengthError: Bool {
        hasAttemptedSave && ((torsoLength ?? 0) > 250 || torsoLength == nil)
    }
    
    var hasError: Bool {
        isChestError || isWaistError || isArmLengthError || isTorsoLengthError
    }
    
    var isOver250Error: Bool {
        hasAttemptedSave && (
            (chest ?? 0) > 250 ||
            (waist ?? 0) > 250 ||
            (armLength ?? 0) > 250 ||
            (torsoLength ?? 0) > 250
        )
    }
    
    var hasEmptyError: Bool {
        hasAttemptedSave && (
            chest == nil ||
            waist == nil ||
            armLength == nil ||
            torsoLength == nil
        )
    }
    
    // MARK: - Public Functions (User Intents)
    // These functions are called by the View's buttons.
    
    func saveTapped() {
        hasAttemptedSave = true // Mark that we've tried to save
        
        // If there are no errors, call the onDone closure
        if !hasError {
            // Optional: You could update the `data` model here
            // with the new values from chest, waist, etc.
            // before calling onDone.
            onDone()
        }
    }
    
    func retakeTapped() {
        onBack()
    }
}
