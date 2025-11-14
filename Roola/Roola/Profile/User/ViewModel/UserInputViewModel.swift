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

    // Replaced generic alert with specific success state
    @Published var showSuccessPopup = false
    @Published private(set) var hasAttemptedSave = false

    // MARK: - Load
    func loadData(from user: User) {
        bust       = user.bust
        waist      = user.waist
        torso      = user.torso
        armsLength = user.arms_length
    }

    // MARK: - Validation helpers
    private func isFieldInvalid(_ value: Int?, max: Int = 250) -> Bool {
        hasAttemptedSave && (value == nil || value! <= 0 || value! > max)
    }

    var isBustError: Bool       { isFieldInvalid(bust) }
    var isWaistError: Bool      { isFieldInvalid(waist) }
    var isTorsoError: Bool      { isFieldInvalid(torso) }
    var isArmsLengthError: Bool { isFieldInvalid(armsLength) }

    var hasError: Bool {
        isBustError || isWaistError || isTorsoError || isArmsLengthError
    }

    var hasEmptyError: Bool {
        hasAttemptedSave && (bust == nil || waist == nil || torso == nil || armsLength == nil)
    }

    // MARK: - Intent
    func validateInputs() -> Bool {
        hasAttemptedSave = true
        return !hasError
    }

    func triggerSuccess() {
        showSuccessPopup = true
    }
}
