//
//  RecommendationView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 04/11/25.
//

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
    
    var body: some View {
        ZStack {
            FirstGradientBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                formSection
                uploadSection
                Spacer()
                bottomButton
                Color.clear.frame(height: 0)
            }
            .ignoresSafeArea(edges: .bottom)
            .onAppear {
                if let user = users.first {
                    viewModel.loadUserMeasurements(user: user)
                }
            }
            .onChange(of: viewModel.extractedJSON) { oldValue, newValue in
                if !newValue.isEmpty && !viewModel.isCallingAPI {
                    viewModel.getRecommendation()
                }
            }
            .onChange(of: viewModel.serverResponse) { oldValue, newValue in
                if newValue != nil && !viewModel.isCallingAPI {
                    showResults = true
                }
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
                if !newValue && (viewModel.isProcessing || viewModel.isCallingAPI) {
                    showNoInternetPage = true
                }
            }
            .fullScreenCover(isPresented: $showResults) {
                ResultsView(
                    viewModel: viewModel,
                    showResults: $showResults,
                    onTryAgain: {
                        resetAllFields()
                    },
                    initialFitPreference: fitPreference.isEmpty ? "standard" : fitPreference
                )
            }
            .sheet(isPresented: $showFitGuide) {
                FitGuideView(showFitGuide: $showFitGuide)
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
            }
        }
        .overlay {
            // OCRErrorModal di-render sebagai overlay untuk memastikan muncul di atas semua konten
            if viewModel.showErrorAlert, let error = viewModel.currentError {
                OCRErrorModal(
                    error: error,
                    onRetry: {
                        viewModel.resetAllStates()
                        selectedPhoto = nil
                        viewModel.selectedImage = nil
                    },
                    isPresented: $viewModel.showErrorAlert
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showErrorAlert)
            }
            
            // NoInternetModal untuk validasi sebelum processing
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
        .fullScreenCover(isPresented: $showNoInternetPage) {
            NoInternetPage(onRetry: {
                showNoInternetPage = false
                resetAllFields()
            })
        }
    }
    
    // MARK: - Subviews
    // All subviews below are from the right version (7b2d507...)
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)
            
            HStack {
                Text("Find your fit")
                    .font(.heading32Medium)
                
                Spacer()
                
                Button(action: {
                    showFitGuide = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(AppColors.primaryPurple)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 8)
            
            Text("Fill your product details to get your best match")
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                clothingTypeRow
                
                Rectangle()
                    .fill(AppColors.grayScale400.opacity(0.36))
                    .frame(height: 0.5)
                
                fitPreferenceRow
            }
            .background(AppColors.primaryWhite.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.grayScale400.opacity(0.36), lineWidth: 1)
            )
            
            // Validation errors
            if showClothingTypeError {
                HStack {
                    Text("• Please fill in this field")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            
            if showFitPreferenceError {
                HStack {
                    Text("• Please fill in this field")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, showClothingTypeError ? 4 : 8)
            }
        }
        .padding(.horizontal, 24)
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
                Button("Slim") { fitPreference = "slim" }
                Button("Standard") { fitPreference = "standard" }
                Button("Relaxed") { fitPreference = "relaxed" }
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
    
    private var uploadSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("Upload size chart screenshot")
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
            .padding(.horizontal, 24)
            .background(AppColors.primaryWhite.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.grayScale400.opacity(0.36), lineWidth: 1)
            )
            
            // Validation error for image
            if showImageError {
                HStack {
                    Text("• Please fill in this field")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
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
                    .stroke(AppColors.primaryPurple, lineWidth: 1)
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
    
    private var bottomButton: some View {
        Button {
            // Validate all fields
            let hasClothingType = !viewModel.clothingType.isEmpty
            let hasFitPreference = !fitPreference.isEmpty
            let hasImage = viewModel.selectedImage != nil
            
            // Show errors for empty fields
            showClothingTypeError = !hasClothingType
            showFitPreferenceError = !hasFitPreference
            showImageError = !hasImage
            
            // Only proceed if all fields are filled
            if hasClothingType && hasFitPreference && hasImage {
                // Check internet connection first
                if !networkMonitor.isConnected {
                    showNoInternetModal = true
                    return
                }
                
                viewModel.processImage()
            }
        } label: {
            Text(viewModel.isProcessing || viewModel.isCallingAPI ? "Processing..." : "Find your fit")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background((viewModel.isProcessing || viewModel.isCallingAPI) ? Color.gray : AppColors.primaryPurple)
                .cornerRadius(30)
        }
        .disabled(viewModel.isProcessing || viewModel.isCallingAPI)
        .padding(.horizontal, 24)
        .padding(.bottom, 110)
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
    
    // MARK: - Helper Functions
    
    private func resetAllFields() {
        // Reset foto
        viewModel.selectedImage = nil
        selectedPhoto = nil
        
        // Reset clothing type
        viewModel.clothingType = ""
        
        // Reset fit preference
        fitPreference = ""
        
        // Reset all view model states
        viewModel.resetAllStates()
        
        print("✅ All fields reset")
    }
}

// MARK: - Preview
#Preview {
    RecommendationView()
        .modelContainer(for: User.self, inMemory: true)
}
