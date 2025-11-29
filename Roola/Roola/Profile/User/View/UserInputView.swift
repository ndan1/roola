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
    
    var onFinish: (() -> Void)? = nil
    
    @State private var isEditing = false
    @State private var showMeasureGuide = false
    @State private var isShowingAIMeasurement = false
    
    private func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var shouldShowCreateFlow: Bool {
        // Tampilkan Create Flow jika:
        // 1. Tidak ada user sama sekali
        // 2. ADA user, tapi data intinya (bust/waist) masih kosong (User Draft dari AI Flow)
        if let user = existingUsers.first {
            return user.bust == 0 && user.waist == 0
        }
        return true
    }
    
    var body: some View {
        ZStack {
            // MARK: - Main Content
            VStack(alignment: .leading, spacing: 0) {
                if shouldShowCreateFlow {
                    createUserView
                } else {
                    updateUserView
                }
            }
            .onAppear(perform: loadExistingUserData)
            .onChange(of: isShowingAIMeasurement) { oldValue, newValue in
                if newValue == false {
                    loadExistingUserData()
                }
            }
            
            // MARK: - Success Popup Overlay
            if viewModel.showSuccessPopup {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .zIndex(1)
                
                SuccessPopupView {
                    handleSuccessDismissal()
                }
                .zIndex(2)
                .onAppear {
                    // Auto-dismiss after 2 seconds (Logic dipindah ke saveUser task)
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
        .toolbar(isEditing ? .hidden : .visible, for : .tabBar)
        .toolbar {
            
            // BAGIAN KIRI (LEADING)
            ToolbarItem(placement: .topBarLeading) {
                if shouldShowCreateFlow{
                    HStack(spacing: 12) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 32)
                                .foregroundColor(AppColors.primaryWhite)
                                .background(
                                    Circle()
                                        .fill(AppColors.primaryPurple)
                                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                        .overlay(
                                            Circle()
                                                .stroke(AppColors.primaryPurple, lineWidth: 1)
                                        )
                                )
                        }
                        
                        Text("Your measurements")
                            .font(.heading28Medium)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                } else {
                    Text("Your measurements")
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
                        .padding(.trailing, 8)
                }
            }
        }
    }
    
    // Helper to handle navigation after success
    private func handleSuccessDismissal() {
        withAnimation {
            viewModel.showSuccessPopup = false
            
            if let onFinish = onFinish {
                onFinish()
                return
            }
            
            if existingUsers.isEmpty || shouldShowCreateFlow {
                dismiss()
            } else {
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
                                hasAnyError: viewModel.hasError,
                                isEditing: true
                            )
                            validationBodyErrors
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
                                isChestError: viewModel.isChestError,
                                isWaistError: viewModel.isWaistError,
                                isArmLengthError: viewModel.isArmLengthError,
                                isTorsoLengthError: viewModel.isTorsoLengthError,
                                hasAnyError: viewModel.hasError,
                                isEditing: true
                            )
                        }

                        validationMeasureErrors
                        
                        Spacer(minLength: 32)
                        VStack(spacing: 8) {
                            Text("Not sure with your measurements?")
                                .font(.body16Regular)
                                .foregroundStyle(AppColors.primaryPurple)
                            
                            RoolaButton(
                                buttonTitle: "Measure with AI",
                                buttonColor: AppColors.primaryButton,
                                action: {
                                    isShowingAIMeasurement = true
                                }
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.8)
                            .padding(.bottom, 4)
                            RoolaButton(
                                buttonTitle: "Save",
                                buttonColor: AppColors.primaryWhite,
                                action: saveUser
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.8)
                            .padding(.bottom, 4)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
            }
            .onTapGesture {
                endEditing()
            }
    }
    
    var updateUserView: some View {
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
                                hasAnyError: viewModel.hasError,
                                isEditing: isEditing
                            )
                        }
                        validationBodyErrors
                        
                        VStack (alignment: .leading, spacing: 4) {
                            Text("Body measurements")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(Color(AppColors.grayScale400))
                            MeasurementsCard(
                                chest: $viewModel.bust,
                                waist: $viewModel.waist,
                                armLength: $viewModel.armsLength,
                                torsoLength: $viewModel.torso,
                                isChestError: viewModel.isChestError,
                                isWaistError: viewModel.isWaistError,
                                isArmLengthError: viewModel.isArmLengthError,
                                isTorsoLengthError: viewModel.isTorsoLengthError,
                                hasAnyError: viewModel.hasError,
                                isEditing: isEditing
                            )
                        }
                        .padding(.top)
                        
//                        if isEditing {
                            validationMeasureErrors
//                        }
                        
                        Spacer(minLength: 22)
                        
                        if isEditing {
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
                                        loadExistingUserData()
                                    }
                                )
                            }
                            .frame(width: UIScreen.main.bounds.width * 0.8)
                            .padding(.bottom, 40)
                        } else {
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
                                        isEditing.toggle()
                                    }
                                )
                            }
                            .frame(width: UIScreen.main.bounds.width * 0.8)
                            .padding(.bottom, 25)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
            }
            .onTapGesture {
                endEditing()
            }
    }
}

// MARK: - Validation UI
private extension UserInputView {
    var validationMeasureErrors: some View {
        VStack(alignment: .leading, spacing: 4) {
            if viewModel.hasMeasureErrorNull {
                Text("Please fill out this field")
                    .font(.body15Regular)
                    .foregroundColor(AppColors.errorRed)
            }

            if viewModel.hasAttemptedSave && viewModel.hasMeasureErrorNumber {
                Text("All measurements must be between 1 to 250 cm")
                    .font(.body15Regular)
                    .foregroundColor(AppColors.errorRed)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 50, alignment: .top)
    }
    
    var validationBodyErrors: some View {
        VStack(alignment: .leading, spacing: 4) {
            if viewModel.hasBodyErrorNull {
                Text("Please fill out this field")
                    .font(.body15Regular)
                    .foregroundColor(AppColors.errorRed)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 15, alignment: .top)
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
        
        withAnimation {
            viewModel.showSuccessPopup = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            let user = existingUsers.first ?? User(waist: 0)
            user.bust        = viewModel.bust        ?? 0
            user.waist       = viewModel.waist       ?? 0
            user.torso       = viewModel.torso       ?? 0
            user.arms_length = viewModel.armsLength  ?? 0
            user.height      = viewModel.height ?? 0
            user.weight      = viewModel.weight ?? 0

            if existingUsers.isEmpty {
                modelContext.insert(user)
            }
            
            try? modelContext.save()
            
            await MainActor.run {
                handleSuccessDismissal()
            }
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
