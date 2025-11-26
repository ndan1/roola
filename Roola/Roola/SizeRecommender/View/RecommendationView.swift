//
//  RecommendationView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 04/11/25.
//

/*
 
 STRUCTURE OF RecommendationView
 
 body
 ├── mainContent (VStack)
 │   ├── headerSection
 │   ├── formSection
 │   │   ├── formInputs
 │   │   └── formValidationErrors
 │   ├── uploadSection
 │   │   ├── uploadContent
 │   │   └── uploadValidationError
 │   └── bottomButton
 ├── loadingOverlay
 └── errorModals
 
*/

import SwiftUI
import Vision
import PhotosUI
import SwiftData

struct RecommendationView: View {
    
    @StateObject private var viewModel = RecommendationViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @Query private var users: [User]
    @State private var showResults = false
    @State private var fitPreference: String = ""
    @State private var showFitGuide = false
    
    // Network monitoring
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showNoInternetModal = false
    @State private var showNoInternetPage = false
    
    // Validation states
    @State private var showClothingTypeError = false
    @State private var showFitPreferenceError = false
    @State private var showImageError = false
    
    @State private var isAnimationFinished = false
    @State private var timeoutTask: Task<Void, Never>? = nil
    @State private var showTimeoutAlert = false
    @State private var isVisualLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                mainContent
                loadingOverlay
                errorModals
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 2. Buat Custom Title di Kiri (Leading)
                ToolbarItem(placement: .topBarLeading) {
                    Text("Find Your Fit")
                        .font(.heading28Medium)
                        .foregroundStyle(.primary)
                        .padding(.leading, 6)
                }
                
                // 3. Tombol Info tetap di Kanan (Trailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showFitGuide.toggle() }) {
                        Image(systemName: "info.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(AppColors.primaryPurple)
                    }
                }
            }
            .toolbar(isVisualLoading ? .hidden : .visible, for: .navigationBar)
            .toolbar(isVisualLoading ? .hidden : .visible, for: .tabBar)
            .alert("Request Timeout", isPresented: $showTimeoutAlert) {
                Button("OK") {
                    resetProcessingState()
                }
            } message: {
                Text("The request took too long to process. Please try again.")
            }
            .fullScreenCover(isPresented: $showNoInternetPage) {
                NoInternetPage(onRetry: {
                    showNoInternetPage = false
                    resetAllFields()
                })
            }
            .animation(.spring(), value: viewModel.isProcessing)
            .animation(.spring(), value: viewModel.showErrorAlert)
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
//            headerSection
            Text("Fill your product details to get your best match")
                .font(.body16Medium)
                .foregroundColor(.primary)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            formSection
            uploadSection
            Spacer()
            bottomButton
            Color.clear.frame(height: 0)
        }
        .padding(.top, 16)
        .ignoresSafeArea(edges: .bottom)
        .background(
            FirstGradientBackground().ignoresSafeArea()
        )
        .onAppear {
            loadUserData()
        }
        .onChange(of: viewModel.extractedJSON) { oldValue, newValue in
            handleExtractedJSONChange(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: viewModel.serverResponse) { oldValue, newValue in
            handleServerResponseChange(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: viewModel.clothingType) { oldValue, newValue in
            if !newValue.isEmpty {
                showClothingTypeError = false
            }
        }
        .onChange(of: fitPreference) { oldValue, newValue in
            if !newValue.isEmpty {
                showFitPreferenceError = false
            }
        }
        .onChange(of: viewModel.selectedImage) { oldValue, newValue in
            if newValue != nil {
                showImageError = false
            }
        }
        .onChange(of: networkMonitor.isConnected) { oldValue, newValue in
            handleNetworkChange(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: showResults) { oldValue, newValue in
            // Ketika user kembali dari ResultsView (showResults berubah dari true ke false)
            if oldValue == true && newValue == false {
                resetAllFields()
            }
        }
        .fullScreenCover(isPresented: $showResults) {
            NavigationStack {
                resultsView
            }
        }
        .sheet(isPresented: $showFitGuide) {
            fitGuideView
        }
    }
    
    // MARK: - Loading Overlay
    
    @ViewBuilder
    private var loadingOverlay: some View {
        if isVisualLoading {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .transition(.opacity)
            
            ProgressLoading(
                title: "Hang Tight...",
                subtitle: "We're tailoring this for you.",
                duration: 4.0,
                onFinish: {
                    handleAnimationFinished()
                }
            )
            .zIndex(1)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Error Modals
    
    @ViewBuilder
    private var errorModals: some View {
        Group {
            if viewModel.showErrorAlert, let error = viewModel.currentError {
                OCRErrorModal(
                    error: error,
                    onRetry: {
                        viewModel.resetAllStates()
                        selectedPhoto = nil
                        viewModel.selectedImage = nil
                        isVisualLoading = false
                        timeoutTask?.cancel()
                    },
                    isPresented: $viewModel.showErrorAlert
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showErrorAlert)
            }
            
            if showNoInternetModal {
                NoInternetModal(
                    isPresented: $showNoInternetModal,
                    onRetry: {
                        showNoInternetModal = false
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showNoInternetModal)
            }
        }
    }
    
    // MARK: - Results & Fit Guide Views
    
    private var resultsView: some View {
        ResultsView(
            recommendationViewModel: viewModel,
            showResults: $showResults,
            initialFitPreference: fitPreference.isEmpty ? "standard" : fitPreference,
            isFromHistory: false,
            onTryAgain: {
                resetAllFields()
            }
        )
    }
    
    private var fitGuideView: some View {
        FitGuideView(showFitGuide: $showFitGuide)
            .presentationDetents([.fraction(0.75)])
            .presentationDragIndicator(.visible)
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 0) {
            formInputs
            formValidationErrors
        }
        .padding(.horizontal, 24)
    }
    
    private var formInputs: some View {
        VStack(spacing: 0) {
            // Clothing Type Row dengan border individual
            clothingTypeRow
                .background(AppColors.primaryWhite.opacity(0.5))
                .cornerRadius(12, corners: [.topLeft, .topRight])
                .overlay(
                    RoundedCorner(radius: 12, corners: [.topLeft, .topRight])
                        .stroke(showClothingTypeError ? AppColors.errorRed : AppColors.grayScale400.opacity(0.36), lineWidth: 1)
                )
            
            // Fit Preference Row dengan border individual
            fitPreferenceRow
                .background(AppColors.primaryWhite.opacity(0.5))
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                .overlay(
                    RoundedCorner(radius: 12, corners: [.bottomLeft, .bottomRight])
                        .stroke(showFitPreferenceError ? AppColors.errorRed : AppColors.grayScale400.opacity(0.36), lineWidth: 1)
                )
        }
    }
    
    @ViewBuilder
    private var formValidationErrors: some View {
        if showClothingTypeError || showFitPreferenceError {
            HStack {
                Text("Please fill out this field")
                    .font(.caption)
                    .foregroundColor(AppColors.errorRed)
                Spacer()
            }
            .padding(.top, 4)
        }
    }
    
    private var clothingTypeRow: some View {
        HStack {
            Text("Clothes type")
                .foregroundColor(AppColors.grayScale400)
            
            Spacer()
            
            Menu {
                Button("T-Shirt") { viewModel.clothingType = "t_shirt" }
                Button("Blouse") { viewModel.clothingType = "blouse" }
                Button("Long Sleeved Shirt") { viewModel.clothingType = "long_sleeved_shirt" }
                Button("Short Sleeved Shirt") { viewModel.clothingType = "short_sleeved_shirt" }
            } label: {
                HStack(spacing: 4) {
                    Text(displayClothingType)
                        .foregroundColor(viewModel.clothingType.isEmpty ? .gray : .primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(AppColors.primaryPurple)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var fitPreferenceRow: some View {
        HStack {
            Text("Fit preference")
                .foregroundColor(AppColors.grayScale400)
            
            Spacer()
            
            Menu {
                Button("Tight") { fitPreference = "tight" }
//                Button("Slim") { fitPreference = "slim" }
                Button("Standard") { fitPreference = "standard" }
//                Button("Relaxed") { fitPreference = "relaxed" }
                Button("Loose") { fitPreference = "loose" }
            } label: {
                HStack(spacing: 4) {
                    Text(displayFitPreference)
                        .foregroundColor(fitPreference.isEmpty ? .gray : .primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(AppColors.primaryPurple)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Upload Section
    
    private var uploadSection: some View {
        VStack(spacing: 0) {
            VStack (alignment: .leading) {
                HStack(spacing: 0) {
                    Text("*")
                        .font(.caption14Italic)
                        .foregroundStyle(Color.red)
                    Text("Currently only available for woman’s top")
                        .font(.caption14Italic)
                        .foregroundStyle(AppColors.grayScale300)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
            uploadContent
            uploadValidationError
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
       
    }
    
    private var uploadContent: some View {
        VStack(spacing: 16) {
            Text("Upload product's size chart screenshot")
                .font(.body)
                .foregroundColor(AppColors.grayScale400)
            
            if viewModel.selectedImage == nil {
                uploadButton
            }
            
            if let image = viewModel.selectedImage {
                imagePreview(image: image)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppColors.primaryWhite.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(showImageError ? AppColors.errorRed : AppColors.grayScale400.opacity(0.36), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var uploadValidationError: some View {
        if showImageError {
            HStack {
                Text("Please fill out this field")
                    .font(.caption)
                    .foregroundColor(AppColors.errorRed)
                Spacer()
            }
            .padding(.top, 4)
        }
    }
    
    private var uploadButton: some View {
        PhotosPicker(
            selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack {
                Text("Upload")
                    .fontWeight(.medium)
                Image(systemName: "square.and.arrow.up")
            }
            .foregroundColor(AppColors.primaryPurple)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(AppColors.primaryWhite.opacity(0.5))
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(AppColors.grayScale300, lineWidth: 1)
            )
        }
        .onChange(of: selectedPhoto) { oldValue, newValue in
            viewModel.handlePhotoSelection(newValue)
        }
    }
    
    private func imagePreview(image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 180)
                .clipped()
                .cornerRadius(12)
            
            Button {
                viewModel.selectedImage = nil
                selectedPhoto = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.primaryWhite)
                    .padding(10)
                    .background(AppColors.grayScale400.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(6)
        }
    }
    
    // MARK: - Bottom Button
    
    private var bottomButton: some View {
        RoolaButton(
            buttonTitle: "Find your fit",
            buttonColor: AppColors.primaryPurple,
            action: {
                handleFindYourFit()
            }
        )
        .disabled(viewModel.isProcessing || viewModel.isCallingAPI)
        .padding(.horizontal, 24)
        .padding(.bottom, 110)
    }
    
    // MARK: - LOGIC FUNCTIONS
        
    private func handleAnimationFinished() {
        isAnimationFinished = true
        checkAndShowResults()
    }
    
    private func handleServerResponseChange(oldValue: ServerResponse?, newValue: ServerResponse?) {
        if newValue != nil && !viewModel.isCallingAPI {
            checkAndShowResults()
        }
    }
    
    private func checkAndShowResults() {
        if viewModel.serverResponse != nil && isAnimationFinished {
            timeoutTask?.cancel()
            isVisualLoading = false
            showResults = true
        }
    }
    
    private func startTimeoutTimer() {
        timeoutTask?.cancel()
        
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
            
            if !Task.isCancelled {
                await MainActor.run {
                    if !showResults {
                        handleTimeout()
                    }
                }
            }
        }
    }
    
    private func handleTimeout() {
        // Hentikan semua proses
//        resetProcessingState()
        viewModel.resetAllStates()
        isVisualLoading = false
        isAnimationFinished = false
        showTimeoutAlert = true
    }
    
    private func resetProcessingState() {
        viewModel.isProcessing = false
        viewModel.isCallingAPI = false
        isAnimationFinished = false
        }

    
    // MARK: - Helper Functions
    
    private func loadUserData() {
        if let user = users.first {
            viewModel.loadUserMeasurements(user: user)
        }
    }
    
    private func handleExtractedJSONChange(oldValue: String, newValue: String) {
        if !newValue.isEmpty && !viewModel.isCallingAPI {
            viewModel.getRecommendation()
        }
    }
    
    private func handleNetworkChange(oldValue: Bool, newValue: Bool) {
        if !newValue && (viewModel.isProcessing || viewModel.isCallingAPI) {
            showNoInternetPage = true
        }
    }
    
    private func handleFindYourFit() {
        showClothingTypeError = false
        showFitPreferenceError = false
        showImageError = false
        
        var hasError = false
        
        if viewModel.clothingType.isEmpty {
            showClothingTypeError = true
            hasError = true
        }
        
        if fitPreference.isEmpty {
            showFitPreferenceError = true
            hasError = true
        }
        
        if viewModel.selectedImage == nil {
            showImageError = true
            hasError = true
        }
        
        if hasError {
            return
        }
        
        if !networkMonitor.isConnected {
            showNoInternetModal = true
            return
        }
        
        isAnimationFinished = false
                
        viewModel.processImage {
            self.isVisualLoading = true
            
            self.startTimeoutTimer()
        }
    }
    
    private var displayClothingType: String {
        switch viewModel.clothingType {
        case "t_shirt": return "T-Shirt"
        case "blouse": return "Blouse"
        case "long_sleeved_shirt": return "Long Sleeved Shirt"
        case "short_sleeved_shirt": return "Short Sleeved Shirt"
        default: return "Select clothing type"
        }
    }
    
    private var displayFitPreference: String {
        switch fitPreference {
        case "tight": return "Tight"
        case "slim": return "Slim"
        case "standard": return "Standard"
        case "relaxed": return "Relaxed"
        case "loose": return "Loose"
        default: return "Select fit preference"
        }
    }
    
    private func resetAllFields() {
        viewModel.selectedImage = nil
        selectedPhoto = nil
        viewModel.clothingType = ""
        fitPreference = ""
        viewModel.resetAllStates()
    }
}

// MARK: - Preview
#Preview {
    RecommendationView()
        .modelContainer(for: User.self, inMemory: true)
}
