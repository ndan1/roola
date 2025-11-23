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
    
    private func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
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
            .onAppear(perform: loadExistingUserData)
            
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
        .background(FirstGradientBackground()
            .ignoresSafeArea()
            .onTapGesture {
                endEditing()
            }
        )
        .sheet(isPresented: $showMeasureGuide) {
            MeasureGuideModal()
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isShowingAIMeasurement) {
            CameraFlowContainerView()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    endEditing()
                }
                .fontWeight(.semibold)
                .foregroundColor(AppColors.primaryPurple)
            }
        }
        
        // MARK: - AKTIFKAN NAVIGATION BAR DISINI
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            
            // BAGIAN KIRI (LEADING)
            ToolbarItem(placement: .topBarLeading) {
                if existingUsers.isEmpty {
                    HStack(spacing: 12) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 24)
                                .foregroundColor(AppColors.primaryWhite)
                                .background(
                                    Circle()
                                        .fill(AppColors.primaryPurple)
                                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                )
                        }
                        
                        Text("Your Measurements")
                            .font(.heading28Medium)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                } else {
                    Text("Your Measurements")
                        .font(.heading28Medium)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.leading, 4)
                }
            }
                
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showMeasureGuide.toggle() }) {
                    Image(systemName: "info.circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(AppColors.primaryPurple)
                }
            }
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
                VStack(spacing: 30) {
                    ScrollView(showsIndicators: false) {
                        VStack (alignment: .leading, spacing: 4) {
                            Text("Body size")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(Color(AppColors.grayScale400))
                            BodySizeCard(
                                height: $viewModel.height,
                                weight: $viewModel.weight,
                                isHeightError: viewModel.isHeightError,
                                isWeightError: viewModel.isWeightError,
                                hasAnyError: viewModel.hasError
                            )
                        }
                        .padding(.vertical, 16)
                        
                        VStack (alignment: .leading, spacing: 4) {
                            Text("Body measurements")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(Color(AppColors.grayScale400))
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
                        }

                        validationErrors
                        
                        Spacer(minLength: 172)
                        VStack(spacing: 8) {
                            Text("Not sure with your measurements?")
                                .font(.body15Regular)
                            
                            RoolaButton(
                                buttonTitle: "Measure with AI",
                                buttonColor: AppColors.primaryButton,
                                action: {
                                    isShowingAIMeasurement = true
                                }
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.85)
                            .padding(.bottom, 8)
                            RoolaButton(
                                buttonTitle: "Save",
                                buttonColor: AppColors.primaryWhite,
                                action: saveUser
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.85)
                            .padding(.bottom, 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .onTapGesture {
                endEditing()
            }
    }
    
    var updateUserView: some View {
            VStack(alignment: .leading, spacing: 0) {

                VStack(spacing: 30) {
                    
                        if isEditing {
                            ScrollView(showsIndicators: false) {
                                VStack (alignment: .leading, spacing: 4) {
                                    Text("Body size")
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundStyle(Color(AppColors.grayScale400))
                                    BodySizeCard(
                                        height: $viewModel.height,
                                        weight: $viewModel.weight,
                                        isHeightError: viewModel.isHeightError,
                                        isWeightError: viewModel.isWeightError,
                                        hasAnyError: viewModel.hasError
                                    )
                                }
                                Spacer(minLength: 30)
                                VStack (alignment: .leading, spacing: 4) {
                                    Text("Body measurements")
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundStyle(Color(AppColors.grayScale400))
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
                                }
                                
                                validationErrors
                                
                                Spacer(minLength: 100)
                                
                                VStack (spacing: 20){
                                    RoolaButton(
                                        buttonTitle: "Update",
                                        buttonColor: AppColors.primaryPurple,
                                        action: saveUser
                                    )
                                    RoolaButton(
                                        buttonTitle: "Cancel",
                                        buttonColor: AppColors.primaryWhite,
                                        action: {
                                            isEditing = false
                                        }
                                    )
                                }
                                .frame(width: UIScreen.main.bounds.width * 0.85)
                                .padding(.bottom, 25)
                            }
                        } else {
                            ScrollView(showsIndicators: false) {
                                VStack (alignment: .leading, spacing: 4) {
                                    Text("Body size")
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundStyle(Color(AppColors.grayScale400))
                                    MeasurementListView(
                                        items: [
                                            MeasurementItem(label: "Height", value: viewModel.height),
                                            MeasurementItem(label: "Weight", value: viewModel.weight)
                                        ]
                                    )
                                }
                                
                                Spacer(minLength: 30)
                                
                                VStack (alignment: .leading, spacing: 4) {
                                    Text("Body measurements")
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundStyle(Color(AppColors.grayScale400))
                                    MeasurementListView(
                                        items: [
                                            MeasurementItem(label: "Chest", value: viewModel.bust),
                                            MeasurementItem(label: "Waist", value: viewModel.waist),
                                            MeasurementItem(label: "Arm length", value: viewModel.armsLength),
                                            MeasurementItem(label: "Torso length", value: viewModel.torso)
                                        ]
                                    )
                                }
                                
                                validationErrors
                                
                                Spacer(minLength: 103)
                                
                                VStack(spacing:20){
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .onTapGesture {
                endEditing()
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
        
        withAnimation {
            viewModel.triggerSuccess()
        }
    }
}

// MARK: - Previews
#Preview("Create Mode") {
    NavigationStack {
        UserInputView()
            .modelContainer(for: User.self, inMemory: true)
    }
}

#Preview("Update Mode") {
    let container = try! ModelContainer(for: User.self,
                                        configurations: .init(isStoredInMemoryOnly: true))
    let ctx = container.mainContext
    let mock = User(bust: 95, waist: 80, torso: 60, arms_length: 55)
    ctx.insert(mock)
    
    return NavigationStack {
        UserInputView()
            .modelContainer(container)
    }
}
