//
//  UserInputView.swift
//  Roola
//

import SwiftUI
import SwiftData

struct UserInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \User.bust) private var existingUsers: [User]
    @StateObject private var viewModel = UserInputViewModel()
    
    @State private var isEditing = false
    @State private var showMeasureGuide = false
    @State private var isShowingAIMeasurement = false
    
    var body: some View {
        ZStack {
            // MARK: - Main Content
            VStack(alignment: .leading, spacing: 0) {
                if existingUsers.isEmpty {
                    createUserView
                } else {
                    updateUserView
                }
            }
            .background(FirstGradientBackground().ignoresSafeArea())
            
            // MARK: - Success Popup Overlay
            if viewModel.showSuccessPopup {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .zIndex(1)
                
                SuccessPopupView {
                    // Allow manual dismiss on tap
                    handleSuccessDismissal()
                }
                .zIndex(2)
                .onAppear {
                    // Auto-dismiss after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        // Check if it is still showing to avoid redundant calls
                        if viewModel.showSuccessPopup {
                            handleSuccessDismissal()
                        }
                    }
                }
            }
        }
        .onAppear(perform: loadExistingUserData)
        .sheet(isPresented: $showMeasureGuide) {
            MeasureGuideModal()
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isShowingAIMeasurement) {
            CameraFlowContainerView()
        }
    }
    
    // Helper to handle navigation after success
    private func handleSuccessDismissal() {
        withAnimation {
            viewModel.showSuccessPopup = false
            
            if existingUsers.isEmpty {
                // If creating for the first time, dismiss the screen
                dismiss()
            } else {
                // If updating, just exit edit mode
                isEditing = false
            }
        }
    }
}

// MARK: - Create / Update UI
private extension UserInputView {
    var createUserView: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoolaHeader(
                title: "Your Measurements",
                onBack: { dismiss() },
                onInfo: {showMeasureGuide.toggle()})

            VStack(spacing: 30) {
                MeasurementsCard(
                    chest: $viewModel.bust,
                    waist: $viewModel.waist,
                    armLength: $viewModel.armsLength,
                    torsoLength: $viewModel.torso,
                    isChestError: viewModel.isBustError,
                    isWaistError: viewModel.isWaistError,
                    isArmLengthError: viewModel.isArmsLengthError,
                    isTorsoLengthError: viewModel.isTorsoError,
                    hasAnyError: viewModel.hasError
                )

                validationErrors
                
                Spacer()
                RoolaButton(
                    buttonTitle: "Save",
                    buttonColor: AppColors.primaryPurple,
                    action: saveUser
                )
                .frame(width: UIScreen.main.bounds.width * 0.85)
                .padding(.bottom, 25)
            }
            .padding(.horizontal, 30)
            .padding(.top, 10)
        }
    }
    
    var updateUserView: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoolaHeader(
                title: "Your Measurements",
                onInfo: {showMeasureGuide.toggle()},
                isLargeTitle: true
            )

            VStack(spacing: 30) {
                if isEditing {
                    MeasurementsCard(
                        chest: $viewModel.bust,
                        waist: $viewModel.waist,
                        armLength: $viewModel.armsLength,
                        torsoLength: $viewModel.torso,
                        isChestError: viewModel.isBustError,
                        isWaistError: viewModel.isWaistError,
                        isArmLengthError: viewModel.isArmsLengthError,
                        isTorsoLengthError: viewModel.isTorsoError,
                        hasAnyError: viewModel.hasError
                    )

                    validationErrors
                    
                    Spacer()

                    RoolaButton(buttonTitle: "Update",
                                buttonColor: AppColors.primaryPurple,
                                action: saveUser)
                        .frame(width: UIScreen.main.bounds.width * 0.8)
                        .padding(.bottom, 40)
                } else {
                    MeasurementListView(
                        items: [
                            MeasurementItem(label: "Chest", value: viewModel.bust),
                            MeasurementItem(label: "Waist", value: viewModel.waist),
                            MeasurementItem(label: "Arm length", value: viewModel.armsLength),
                            MeasurementItem(label: "Torso length", value: viewModel.torso)
                        ]
                    )
                    Spacer()
                    
                    VStack(spacing:10){
                        RoolaButton(
                            buttonTitle: "Measure with AI",
                            buttonColor: AppColors.primaryPurple,
                            action: {
                                isShowingAIMeasurement = true
                            }
                        )
                        RoolaButton(
                            buttonTitle: "Edit",
                            buttonColor: AppColors.primaryWhite,
                            action: {
                                if isEditing {
                                    loadExistingUserData()
                                }
                                isEditing.toggle()
                            }
                        )
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.85)
                    .padding(.bottom, 25)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 10)
        }
    }
}

// MARK: - Validation UI
private extension UserInputView {
    var validationErrors: some View {
        VStack(alignment: .leading, spacing: 4) {
            if viewModel.hasEmptyError {
                Text("Please fill in all fields")
                    .font(.body15Regular)
                    .foregroundColor(AppColors.errorRed)
            }

            if viewModel.hasAttemptedSave && viewModel.hasError {
                Text("All measurements must be between 1 and 250 cm")
                    .font(.body15Regular)
                    .foregroundColor(AppColors.errorRed)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

// MARK: - Load existing data
private extension UserInputView {
    func loadExistingUserData() {
        if let user = existingUsers.first {
            viewModel.loadData(from: user)
        }
    }
}

// MARK: - SAVE LOGIC
private extension UserInputView {
    func saveUser() {
        guard viewModel.validateInputs() else { return }

        let user = existingUsers.first ?? User(waist: 0)
        user.bust        = viewModel.bust        ?? 0
        user.waist       = viewModel.waist       ?? 0
        user.torso       = viewModel.torso       ?? 0
        user.arms_length = viewModel.armsLength  ?? 0

        if existingUsers.isEmpty {
            modelContext.insert(user)
        }
        
        try? modelContext.save()
        
        // Trigger the view state; the View will handle the timer via .onAppear
        withAnimation {
            viewModel.triggerSuccess()
        }
    }
}

// MARK: - Previews
#Preview("Create Mode") {
    UserInputView()
        .modelContainer(for: User.self, inMemory: true)
}

#Preview("Update Mode") {
    let container = try! ModelContainer(for: User.self,
                                        configurations: .init(isStoredInMemoryOnly: true))
    let ctx = container.mainContext
    let mock = User(bust: 95, waist: 80, torso: 60, arms_length: 55)
    ctx.insert(mock)
    return UserInputView()
        .modelContainer(container)
}
