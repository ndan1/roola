//
//  UserInputViewModel.swift
//  Roola
//
//  Created by Lin Dan Christiano on 08/11/25.
//

import Foundation

final class UserInputViewModel: ObservableObject {
    // MARK: - Published UI state
    @Published var bust: Int?
    @Published var waist: Int?
    @Published var torso: Int?
    @Published var armsLength: Int?
    @Published var height: Int?
    @Published var weight: Int?

    // Replaced generic alert with specific success state
    @Published var showSuccessPopup = false
    @Published private(set) var hasAttemptedSave = false

    // MARK: - Load
    func loadData(from user: User) {
        bust       = user.bust
        waist      = user.waist
        torso      = user.torso
        armsLength = user.arms_length
        height     = user.height
        weight     = user.weight
    }

    // MARK: - Validation helpers
    private func isFieldNull(_ value: Int?) -> Bool {
        hasAttemptedSave && (value == nil)
    }
    
    private func isFieldNumber(_ value: Int?, max: Int = 250) -> Bool {
       guard hasAttemptedSave, let value = value else { return false }
        
        return value <= 0 || value > max
    }

    var isChestError: Bool       { isFieldNull(bust) || isFieldNumber(bust) }
    var isWaistError: Bool      { isFieldNull(waist) || isFieldNumber(waist) }
    var isTorsoLengthError: Bool      { isFieldNull(torso) || isFieldNumber(torso) }
    var isArmLengthError: Bool { isFieldNull(armsLength) || isFieldNumber(armsLength) }
    
    var isHeightError: Bool      { isFieldNull(height) }
    var isWeightError: Bool     { isFieldNull(weight) }

    var hasBodyErrorNull: Bool {
        isFieldNull(height) || isFieldNull(weight)
    }
    
    var hasMeasureErrorNull: Bool {
        isFieldNull(bust) || isFieldNull(waist) || isFieldNull(torso) || isFieldNull(armsLength)
    }
    
    var hasMeasureErrorNumber: Bool {
        isFieldNumber(bust) || isFieldNumber(waist) || isFieldNumber(torso) || isFieldNumber(armsLength)
    }
    
    var hasError: Bool {
        hasMeasureErrorNull || hasBodyErrorNull || hasMeasureErrorNumber
    }
    
    // MARK: - Error properties for Cards (matching BodySizeCard and MeasurementsCard expectations)
//    var isHeightError: Bool { isFieldNull(height) }
//    var isWeightError: Bool { isFieldNull(weight) }
//    var isChestError: Bool { isFieldNull(bust) || isFieldNumber(bust) }
//    var isWaistError: Bool { isFieldNull(waist) || isFieldNumber(waist) }
//    var isArmLengthError: Bool { isFieldNull(armsLength) || isFieldNumber(armsLength) }
//    var isTorsoLengthError: Bool { isFieldNull(torso) || isFieldNumber(torso) }

    // MARK: - Intent
    func validateInputs() -> Bool {
        hasAttemptedSave = true
        return !hasError
    }

    func triggerSuccess() {
        showSuccessPopup = true
    }
}
