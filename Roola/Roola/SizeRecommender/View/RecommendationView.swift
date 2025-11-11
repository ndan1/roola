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
            FirstGradientBackground()
            
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
                // Auto-trigger recommendation ketika OCR extraction selesai
                if !newValue.isEmpty && !viewModel.isCallingAPI {
                    viewModel.getRecommendation()
                }
            }
            .onChange(of: viewModel.serverResponse) { oldValue, newValue in
                // Auto-show results ketika recommendation selesai
                if newValue != nil && !viewModel.isCallingAPI {
                    showResults = true
                }
            }
            .fullScreenCover(isPresented: $showResults) {
                ResultsView(
                    viewModel: viewModel,
                    showResults: $showResults,
                    onTryAgain: {
                        // Reset semua fields ketika Try Again diklik
                        resetAllFields()
                    },
                    initialFitPreference: fitPreference.isEmpty ? "standard" : fitPreference
                )
            }
            .sheet(isPresented: $showFitGuide) {
                FitGuideView(showFitGuide: $showFitGuide)
            }
            
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
        }
    }
    
    // MARK: - Subviews
    
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
        Button {
            if viewModel.selectedImage != nil {
                viewModel.processImage()
                // onChange observers akan handle sisanya:
                // 1. onChange(extractedJSON) → auto call getRecommendation()
                // 2. onChange(serverResponse) → auto set showResults = true
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


struct RecommendationCard: View {
    let fit: String
    let recommendation: FitRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(fit)
                    .font(.headline)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text(recommendation.bestSize)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack {
                Text("Match Score:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f%%", recommendation.bestScore))
                    .fontWeight(.semibold)
            }
            
            if !recommendation.partFits.isEmpty {
                Divider()
                
                Text("Part Fits:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(recommendation.partFits.sorted(by: { $0.key < $1.key }), id: \.key) { part, fit in
                        HStack {
                            Text(part.capitalized)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(fit)
                                .fontWeight(.medium)
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Fit Guide Modal
struct FitGuideView: View {
    @Binding var showFitGuide: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
            
            // Header
            HStack {
                Spacer()
                Text("Fit guide")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .overlay(
                Button(action: {
                    showFitGuide = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.system(size: 16, weight: .medium))
                }
                    .padding(.trailing, 20),
                alignment: .trailing
            )
            .padding(.top, 16)
            .padding(.bottom, 20)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GuideStepView(
                        number: "1",
                        title: "Choose your type of clothes"
                    )
                    
                    GuideStepView(
                        number: "2",
                        title: "Choose your fit preference",
                        subtitle: "Standard is how we think is best for you"
                    )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        GuideStepView(
                            number: "3",
                            title: "Upload screenshot of your product's size chart"
                        )
                        
                        HStack(spacing: 12) {
                            // Placeholder for left image
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 30))
                                            .foregroundColor(.gray)
                                        Text("Size Chart")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                            
                            // Placeholder for right image
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "doc.text")
                                            .font(.system(size: 30))
                                            .foregroundColor(.gray)
                                        Text("Product Description")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                        .padding(.top, 8)
                    }
                    
                    GuideStepView(
                        number: "4",
                        title: "Find the best size for your outfit"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

struct GuideStepView: View {
    let number: String
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text("\(number).")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    RecommendationView()
        .modelContainer(for: User.self, inMemory: true)
}
