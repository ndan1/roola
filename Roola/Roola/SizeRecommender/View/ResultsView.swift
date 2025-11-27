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
    
    var historyProductName: String? = nil
    var historyProductLink: String? = nil
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    init(
        recommendationViewModel: RecommendationViewModel,
        showResults: Binding<Bool>,
        initialFitPreference: String = "standard",
        isFromHistory: Bool = false,
        historyProductName: String? = nil,
        historyProductLink: String? = nil,
        onTryAgain: (() -> Void)? = nil
    ) {
        self._showResults = showResults
        self.isFromHistory = isFromHistory
        
        self.historyProductName = historyProductName
        self.historyProductLink = historyProductLink
        print("🔍 INIT ResultsView - Link diterima: '\(historyProductLink ?? "NIL")'")
        
        let vm = ResultsViewModel(
            recommendationViewModel: recommendationViewModel,
            initialFitPreference: initialFitPreference
        )
        if let link = historyProductLink {
            vm.productLink = link
            print("✅ ViewModel Link set to: \(vm.productLink)")
        } else {
            print("⚠️ historyProductLink is NIL")
        }
        vm.onTryAgain = onTryAgain
        vm.onClose = {
            showResults.wrappedValue = false
        }
        
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.recommendationViewModel.isCallingAPI {
                ProgressView("Calculating Recommendations...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let apiError = viewModel.recommendationViewModel.apiError {
                errorView(message: apiError)
            } else if let recommendation = viewModel.currentRecommendation {
                ZStack {
                    resultContent(recommendation: recommendation)
                    
                    if !isFromHistory {
                        actionButtons
                    } else {
                        VStack {
                            Spacer()
                            
                            if !viewModel.productLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                
                                let urlString = viewModel.productLink
                                let urlToOpen = URL(string: urlString.lowercased().hasPrefix("http") ? urlString : "https://\(urlString)")
                                
                                if let url = urlToOpen {
                                    RoolaButton(
                                        buttonTitle: "View Product",
                                        buttonColor: AppColors.primaryPurple,
                                        action: {
                                            UIApplication.shared.open(url)
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, UIScreen.main.bounds.height * 0.08)
                                }
                            }
                        }
                        .padding(.bottom, 40)
                        .ignoresSafeArea(.all, edges: .bottom)
                    }
                }
                .clipped()
            }
        }
        .background(FirstGradientBackground().ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(isFromHistory ? .hidden : .visible, for: .tabBar)
        .toolbar(viewModel.showSaveModal || viewModel.showSuccessModal ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    showResults = false
                    dismiss()
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 32)
                        .foregroundColor(AppColors.primaryWhite)
                        .background(
                            Circle()
                            .fill(AppColors.primaryPurple)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                )}
            }
            ToolbarItem(placement: .principal) {
                Text("Recommended size")
                    .font(.heading28Medium)
                    .foregroundStyle(.primary)
            }
        }
        .overlay(
            Group {
                if viewModel.showSaveModal {
                    SaveResultModal(
                        isPresented: $viewModel.showSaveModal,
                        productName: $viewModel.productName,
                        brandName: $viewModel.brandName,
                        productLink: $viewModel.productLink,
                        onSave: {
                            viewModel.saveToHistory()
                        }
                    )
                    .transition(.opacity)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showSaveModal)
//                    .padding(.horizontal)
                }
                
                if viewModel.showSuccessModal {
                    SaveSuccessModal()
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showSuccessModal)
                }
            }
        )
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
        VStack(spacing: 0) {
            if viewModel.showSaveModal || viewModel.showSuccessModal {
                HStack(spacing: 19) {
                    Button(action: {
                        showResults = false
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 32)
                            .foregroundColor(AppColors.primaryWhite)
                            .background(
                                Circle()
                                    .fill(AppColors.primaryPurple)
                                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                            )
                    }
                    Text("Recommended size")
                        .font(.heading28Medium)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Spacer()
                }
                .padding(.bottom, 5)
            }
            if isFromHistory {
                recommendationSection(recommendation: recommendation)
                    .padding(.top, 80)
//                    .padding(.bottom, 120)
            } else {
                ScrollView {
                    recommendationSection(recommendation: recommendation)
                        .padding(.top, 24)
                        .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.horizontal, 16)
    }
    // MARK: - Recommendation Section
    
    @ViewBuilder
    private func recommendationSection(recommendation: FitRecommendation) -> some View {
        VStack(alignment: .center) {
            sizeBadge(recommendation: recommendation)
            
            VStack(alignment: .leading, spacing: 8) {
                if isFromHistory, let name = historyProductName {
                    HStack {
                        Spacer()
                        Text(name)
                            .font(.heading24Medium)
                            .foregroundColor(.black)
                            .padding(.bottom, 4)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
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
            Spacer()
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
            Text("Selected size may not fit well on your preferences.")
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
                    buttonTitle: "Save",
                    buttonColor: AppColors.primaryPurple,
                    action: {
                        viewModel.showSaveModal = true
                    }
                )
            }
            .padding(.horizontal, 16)
            
        }
        .padding(.bottom, 74)
        .ignoresSafeArea(.all, edges: .bottom)
        .animation(nil, value: viewModel.showSaveModal)
        
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
    let labels = ["Tight", "", "Standard", "", "Loose"]

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
