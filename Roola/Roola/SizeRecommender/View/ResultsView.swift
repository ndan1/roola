//
//  ResultsView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 11/11/25.
//

import SwiftUI

struct ResultsView: View {
    @StateObject private var viewModel: ResultsViewModel
    @Binding var showResults: Bool
    var isFromHistory: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    init(
        recommendationViewModel: RecommendationViewModel,
        showResults: Binding<Bool>,
        initialFitPreference: String = "standard",
        isFromHistory: Bool = false,
        onTryAgain: (() -> Void)? = nil
    ) {
        self._showResults = showResults
        self.isFromHistory = isFromHistory
        
        let vm = ResultsViewModel(
            recommendationViewModel: recommendationViewModel,
            initialFitPreference: initialFitPreference
        )
        vm.onTryAgain = onTryAgain
        vm.onClose = {
            showResults.wrappedValue = false
        }
        
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack {
            FirstGradientBackground().ignoresSafeArea()
            
            if viewModel.recommendationViewModel.isCallingAPI {
                ProgressView("Calculating Recommendations...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let apiError = viewModel.recommendationViewModel.apiError {
                errorView(message: apiError)
            } else if let recommendation = viewModel.currentRecommendation {
                resultContent(recommendation: recommendation)
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            viewModel.setInitialSliderPosition()
        }
    }
    
    // MARK: - Error View
    
    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Text("Error")
                .font(.title)
                .fontWeight(.bold)
            Text(message)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
            Button("Try Again") {
                showResults = false
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(AppColors.primaryPurple)
            .foregroundColor(.white)
            .cornerRadius(25)
        }
        .padding()
    }
    
    // MARK: - Result Content
    
    @ViewBuilder
    private func resultContent(recommendation: FitRecommendation) -> some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    recommendationSection(recommendation: recommendation)
                    
                    Spacer()
                        .frame(height: 140)
                }
                .padding(.horizontal, 16)
            }
            
            if !isFromHistory {
                actionButtons
            }
            
            if viewModel.showSaveModal {
                SaveResultModal(
                    isPresented: $viewModel.showSaveModal,
                    productName: $viewModel.productName,
                    shopName: $viewModel.shopName,
                    onSave: {
                        viewModel.saveToHistory()
                    }
                )
                .transition(.opacity)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showSaveModal)
            }
            
            if viewModel.showSuccessModal {
                SaveSuccessModal()
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showSuccessModal)
            }
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 8) {
            if isFromHistory {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(AppColors.primaryWhite)
                        .background(
                            Circle()
                                .fill(AppColors.primaryPurple)
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        )
                }
            }
            
            Text("Recommended Size")
                .font(isFromHistory ? .system(size: 30): .heading32Medium)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.top, 60)
    }
    
    // MARK: - Recommendation Section
    
    @ViewBuilder
    private func recommendationSection(recommendation: FitRecommendation) -> some View {
        VStack(alignment: .center) {
            sizeBadge(recommendation: recommendation)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Fit Preference")
                    .font(.body16Regular)
                
                SliderWithLabels(sliderValue: $viewModel.sliderValue)
                    .padding(.horizontal, -16)
                
                bodyVisualization(recommendation: recommendation)
                    .padding(.bottom, -42)
                    .padding(.leading, UIScreen.main.bounds.width * 0.05)
                
                warningText(recommendation: recommendation)
                
                statusIndicators(recommendation: recommendation)
            }
            .padding(8)
            .padding(.top, 38)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(12)
            
            noteText
        }
    }
    
    // MARK: - Size Badge
    
    @ViewBuilder
    private func sizeBadge(recommendation: FitRecommendation) -> some View {
        ZStack {
            Circle()
                .frame(width: UIScreen.main.bounds.width * 0.2, height: UIScreen.main.bounds.width * 0.2)
                .foregroundColor(Color(AppColors.primaryPurple))
                .overlay(
                    Text(recommendation.bestSize)
                        .foregroundColor(.white)
                        .font(getSizeFont(for: recommendation.bestSize))
                        .fontWeight(.bold)
                )
        }
        .padding(.bottom, -48)
        .padding(.top, -8)
        .zIndex(1)
    }
    
    private func getSizeFont(for size: String) -> Font {
        switch size {
        case "XXXL": return .system(size: 24)
        case "XXL": return .system(size: 28)
        case "XL", "XS": return .system(size: 36)
        case "L", "M", "S": return .system(size: 48)
        default: return .system(size: 18)
        }
    }
    
    // MARK: - Body Visualization
    
    @ViewBuilder
    private func bodyVisualization(recommendation: FitRecommendation) -> some View {
        ZStack {
            Image(viewModel.getBustImageName(recommendation: recommendation))
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
            
            Image(viewModel.getArmImageName(recommendation: recommendation))
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
        }
    }
    
    // MARK: - Warning Text
    
    @ViewBuilder
    private func warningText(recommendation: FitRecommendation) -> some View {
        if recommendation.bestScore < 30 {
            Text("The selected size may not fit well on your preferences because...")
                .font(.caption14Italic)
                .foregroundColor(AppColors.grayScale300)
        } else {
            Text("")
                .font(.caption14Italic)
        }
    }
    
    // MARK: - Note Text
    
    @ViewBuilder
    private var noteText: some View {
        Text("Note : Measurements can differ by ± 1 – 2 cm due to material variation.")
            .font(.caption14Italic)
            .foregroundStyle(Color(hex: "838383"))
            .padding(.vertical, 4)
    }
    
    // MARK: - Status Indicators
    
    @ViewBuilder
    private func statusIndicators(recommendation: FitRecommendation) -> some View {
        let status = viewModel.getOverallStatus(recommendation: recommendation)
        
        VStack(alignment: .leading, spacing: 8) {
            if status.isAllGood {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, AppColors.successGreen)
                        .font(.system(size: 24))
                    Text(viewModel.getPerfectFitMessage())
                        .font(.caption14Italic)
                        .foregroundStyle(Color(hex: "838383"))
                }
            } else {
                ForEach(status.issues, id: \.part) { issue in
                    HStack {
                        Image(systemName: issue.icon)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(issue.iconForeground, issue.iconBackground)
                            .font(.system(size: 24))
                        Text(issue.message)
                            .font(.caption14Italic)
                            .foregroundStyle(Color(hex: "838383"))
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                RoolaButton(
                    buttonTitle: "Save Result",
                    buttonColor: AppColors.primaryPurple,
                    action: {
                        viewModel.showSaveModal = true
                    }
                )
                RoolaButton(
                    buttonTitle: "Try Again",
                    buttonColor: AppColors.primaryWhite,
                    action: {
                        viewModel.onTryAgain?()
                        showResults = false
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, UIScreen.main.bounds.height * 0.05)
        }
    }
}

// MARK: - Supporting Models

struct StatusIssue {
    let part: String
    let message: String
    let icon: String
    let iconForeground: Color
    let iconBackground: Color
}

// MARK: - Slider Component

struct SliderWithLabels: View {
    @Binding var sliderValue: Float
    let labels = ["Tight", "Slim", "Standard", "Relaxed", "Loose"]

    var body: some View {
        VStack {
            Slider(
                value: $sliderValue,
                in: 0...4,
                step: 1
            ) { didChange in
                print("Did change: \(didChange)")
            }
            .padding(.horizontal)
            .tint(Color(AppColors.primaryPurple))
            .padding(.bottom, -16)

            HStack(alignment: .top, spacing: 0) {
                ForEach(0..<labels.count, id: \.self) { index in
                    let isSelected = (Int(round(sliderValue)) == index)
                    
                    VStack(spacing: 4) {
                        Text("•")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                        
                        Text(labels[index])
                            .font(.caption)
                            .foregroundColor(isSelected ? AppColors.primaryPurple : .black)
                            .fontWeight(isSelected ? .bold : .regular)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, -8)
        }
    }
}

// MARK: - Preview

#Preview {
    ResultsView(
        recommendationViewModel: RecommendationViewModel(),
        showResults: .constant(true)
    )
}
