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
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerSection
                formSection
                uploadSection
                Spacer()
                bottomButton
                Color.clear.frame(height: 0)
            }
            .ignoresSafeArea(edges: .bottom)
            .background(
                FirstGradientBackground().ignoresSafeArea()
            )
            if viewModel.isProcessing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                ProgressLoading(
                    title: "Analyzing Chart",
                    subtitle: viewModel.currentStep,
                    duration: 3.0
                )
                .zIndex(1)
                .transition(.scale.combined(with: .opacity))
            }
            
            // MARK: - Layer 3: Error Modal
            if viewModel.showErrorAlert, let error = viewModel.currentError {
                Color.black.opacity(0.4).ignoresSafeArea()
                
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
                .zIndex(2)
            }
        }
        // MARK: - Logic & Modifiers
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
        // Animation for state changes in the ZStack
        .animation(.spring(), value: viewModel.isProcessing)
        .animation(.spring(), value: viewModel.showErrorAlert)
    }
  
    // ... (Rest of your subviews: headerSection, formSection, etc. remain exactly the same)
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            RoolaHeader(
                title: "Find your fit",
                onInfo: {
                    showFitGuide = true
                },
                isLargeTitle: true
            )
            
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
        RoolaButton(
            buttonTitle: "Find your fit",
            buttonColor: AppColors.primaryPurple,
            action: {
                if viewModel.selectedImage != nil {
                    viewModel.processImage()
                }
            }
        )
        .disabled(viewModel.isProcessing || viewModel.isCallingAPI || viewModel.selectedImage == nil)
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
