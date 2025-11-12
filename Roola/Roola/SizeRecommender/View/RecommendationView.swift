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
                // Header
                Spacer().frame(height: 20)
                HStack {
                    Text("Find your fit")
                        .font(.heading32Medium)
                    
                    Spacer()
                    
                    Button(action: {
                        showFitGuide = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.title2_20Medium)
                            .foregroundColor(AppColors.primaryPurple)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 8)
                
                Text("Fill your product details to get your best match")
                    .font(.title3_16Medium)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                
                // Form Section
                VStack(spacing: 0) {
                    HStack {
                        Text("Clothes type")
                            .font(.body16Regular)
                            .foregroundColor(AppColors.grayScale400)
                        
                        Spacer()
                        
                        Menu {
                            Button {
                                viewModel.clothingType = "t_shirt"
                            } label: {
                                Text("T-Shirt")
                                    .font(.body16Regular)
                            }

                            Button {
                                viewModel.clothingType = "blouse"
                            } label: {
                                Text("Blouse")
                                    .font(.body16Regular)
                            }

                            Button {
                                viewModel.clothingType = "long_sleeved_shirt"
                            } label: {
                                Text("Long Sleeved Shirt")
                                    .font(.body16Regular)
                            }

                            Button {
                                viewModel.clothingType = "short_sleeved_shirt"
                            } label: {
                                Text("Short Sleeved Shirt")
                                    .font(.body16Regular)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(displayClothingType)
                                    .font(.body16Regular)
                                    .foregroundColor(viewModel.clothingType.isEmpty ? .gray : .primary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.body15Regular)
                                    .foregroundColor(AppColors.primaryPurple)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    Rectangle()
                        .fill(AppColors.grayScale400.opacity(0.36))
                        .frame(height: 0.5)
                    
                    HStack {
                        Text("Fit preference")
                            .font(.body16Regular)
                            .foregroundColor(AppColors.grayScale400)
                        
                        Spacer()
                        
                        Menu {
                            Button {
                                fitPreference = "tight"
                            } label: {
                                Text("Tight")
                                    .font(.body16Regular)
                            }
                            
                            Button {
                                fitPreference = "slim"
                            } label: {
                                Text("Slim")
                                    .font(.body16Regular)
                            }
                            
                            Button {
                                fitPreference = "standard"
                            } label: {
                                Text("Standard")
                                    .font(.body16Regular)
                            }
                            
                            Button {
                                fitPreference = "relaxed"
                            } label: {
                                Text("Relaxed")
                                    .font(.body16Regular)
                            }
                            
                            Button {
                                fitPreference = "loose"
                            } label: {
                                Text("Loose")
                                    .font(.body16Regular)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(displayFitPreference)
                                    .font(.body16Regular)
                                    .foregroundColor(fitPreference.isEmpty ? .gray : .primary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.body15Regular)
                                    .foregroundColor(AppColors.primaryPurple)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(AppColors.primaryWhite.opacity(0.5))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.grayScale400.opacity(0.36), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                // Upload section
                VStack(spacing: 16) {
                    Text("Upload size chart screenshot")
                        .font(.body16Regular)
                        .foregroundColor(AppColors.grayScale400)
                    
                    if viewModel.selectedImage == nil {
                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack {
                                Text("Upload")
                                    .font(.body16Regular)
                                Image(systemName: "square.and.arrow.up")
                                    .font(.body16Regular)
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
                    
                    if let image = viewModel.selectedImage {
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
                                    .font(.button16Bold)
                                    .foregroundColor(AppColors.primaryWhite)
                                    .padding(10)
                                    .background(AppColors.grayScale400.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(6)
                        }
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
                
                Spacer()
                
                // Bottom Button
                Button {
                    if viewModel.selectedImage != nil {
                        viewModel.processImage()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if !viewModel.extractedJSON.isEmpty {
                                viewModel.getRecommendation()
                                showResults = true
                            }
                        }
                    }
                } label: {
                    Text("Find your fit")
                        .font(.button16Bold)
                        .foregroundColor(AppColors.primaryWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppColors.primaryPurple)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 110)
                
                Color.clear.frame(height: 0)
            }
            .ignoresSafeArea(edges: .bottom)
            .alert(viewModel.currentError?.title ?? "Error", isPresented: $viewModel.showErrorAlert) {
                Button("Retry", role: .cancel) {
                    viewModel.resetAllStates()
                    selectedPhoto = nil
                    viewModel.selectedImage = nil
                }
                .font(.body16Regular)
            } message: {
                Text(viewModel.currentError?.message ?? "")
                    .font(.body16Regular)
            }
            .onAppear {
                if let user = users.first {
                    viewModel.loadUserMeasurements(user: user)
                }
            }
            .sheet(isPresented: $showResults) {
                ResultsView(viewModel: viewModel, showResults: $showResults)
            }
            .sheet(isPresented: $showFitGuide) {
                FitGuideView(showFitGuide: $showFitGuide)
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
            }
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
}

// Results Sheet View
struct ResultsView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    @Binding var showResults: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let recommendations = viewModel.serverResponse?.recommendations {
                        Text("Size Recommendations")
                            .font(.title1_22Medium)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        RecommendationCard(fit: "Tight", recommendation: recommendations.tight)
                        RecommendationCard(fit: "Slim", recommendation: recommendations.slightlyTight)
                        RecommendationCard(fit: "Standard", recommendation: recommendations.regular)
                        RecommendationCard(fit: "Relaxed", recommendation: recommendations.slightlyLoose)
                        RecommendationCard(fit: "Loose", recommendation: recommendations.loose)
                        
                    } else if viewModel.isCallingAPI {
                        ProgressView("Calculating Recommendations...")
                            .font(.body16Regular)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let apiError = viewModel.apiError {
                        Text(apiError)
                            .font(.body16Regular)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Your Results")
                        .font(.title1_22Medium)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showResults = false
                    }
                    .font(.body16Regular)
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
