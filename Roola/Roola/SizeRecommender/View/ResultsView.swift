//
//  ResultsView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 11/11/25.
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    @Binding var showResults: Bool
    var onTryAgain: (() -> Void)?
    var initialFitPreference: String = "standard"
    var isFromHistory: Bool = false  // NEW: Flag untuk view dari history
    
    @Environment(\.modelContext) private var modelContext  // NEW: SwiftData context
    @Environment(\.dismiss) private var dismiss  // NEW: For back button
    
    @State private var sliderValue: Float = 2.0
    @State private var showSaveModal = false
    @State private var showSuccessModal = false
    @State private var productName = ""
    @State private var shopName = ""
    
    // Computed property untuk mapping fit preference
    private var currentFitPreference: String {
        let fitMap = ["tight", "slightly-tight", "regular", "slightly-loose", "loose"]
        let index = Int(round(sliderValue))
        return fitMap[min(max(index, 0), 4)]
    }
    
    // Get recommendation for current slider position
    private var currentRecommendation: FitRecommendation? {
        guard let recommendations = viewModel.serverResponse?.recommendations else { return nil }
        
        switch currentFitPreference {
        case "tight": return recommendations.tight
        case "slightly-tight": return recommendations.slightlyTight
        case "regular": return recommendations.regular
        case "slightly-loose": return recommendations.slightlyLoose
        case "loose": return recommendations.loose
        default: return recommendations.regular
        }
    }
    
    var body: some View {
        ZStack {
            FirstGradientBackground()
            
            if viewModel.isCallingAPI {
                ProgressView("Calculating Recommendations...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let apiError = viewModel.apiError {
                VStack(spacing: 16) {
                    Text("Error")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(apiError)
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
            } else if let recommendation = currentRecommendation {
                resultContent(recommendation: recommendation)
            }
        }
        .onAppear {
            // Set slider position based on initial fit preference
            setInitialSliderPosition()
        }
    }
    
    // Function to map fit preference string to slider index
    private func setInitialSliderPosition() {
        let preferenceMap: [String: Float] = [
            "tight": 0.0,
            "slim": 1.0,
            "slightly-tight": 1.0,
            "standard": 2.0,
            "regular": 2.0,
            "relaxed": 3.0,
            "slightly-loose": 3.0,
            "loose": 4.0
        ]
        
        sliderValue = preferenceMap[initialFitPreference.lowercased()] ?? 2.0
        print("🎚️ Slider initialized to: \(sliderValue) for preference: \(initialFitPreference)")
    }
    
    // MARK: - Save to History
    
    private func saveToHistory() {
        guard let serverResponse = viewModel.serverResponse,
              let userMeasurements = viewModel.userMeasurements else {
            print("❌ Cannot save: missing data")
            return
        }
        
        // Encode recommendations to JSON string
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let recommendationsData = try? encoder.encode(serverResponse),
              let recommendationsJSON = String(data: recommendationsData, encoding: .utf8) else {
            print("❌ Failed to encode recommendations")
            return
        }
        
        // Create history entry
        let history = MeasurementHistory(
            productName: productName,
            shopName: shopName,
            clothingType: viewModel.clothingType,
            selectedFitPreference: initialFitPreference,
            recommendationsJSON: recommendationsJSON,
            userBust: userMeasurements.bust,
            userWaist: userMeasurements.waist,
            userTorso: userMeasurements.torso,
            userArmLength: userMeasurements.armLength
        )
        
        // Save to SwiftData
        modelContext.insert(history)
        
        do {
            try modelContext.save()
            print("✅ History saved successfully!")
            
            // Close save modal
            showSaveModal = false
            
            // Show success modal
            showSuccessModal = true
            
            // Auto-hide success modal and reset form after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showSuccessModal = false
                
                // Reset form inputs
                productName = ""
                shopName = ""
                
                // Close results view and reset all fields
                showResults = false
                onTryAgain?()
            }
        } catch {
            print("❌ Failed to save history: \(error)")
        }
    }
    
    @ViewBuilder
    private func resultContent(recommendation: FitRecommendation) -> some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack (spacing: 8){
                        if isFromHistory {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "chevron.backward.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .font(.system(size: 38))
                                    .foregroundStyle(Color(AppColors.primaryPurple), Color(AppColors.primaryWhite).opacity(0.5))
                            }
                            .padding(.top, 8)
                        }
                        
                        Text("Recommended Size")
                            .font(.heading32Medium)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding(.top, isFromHistory ? 64 : 42)
                    
                    VStack(alignment: .center) {
                        // Size Badge
                        ZStack {
                            Circle()
                                .frame(width: UIScreen.main.bounds.width * 0.2, height: UIScreen.main.bounds.width * 0.2)
                                .foregroundColor(Color(AppColors.primaryPurple))
                                .overlay(
                                    Text(recommendation.bestSize)
                                        .foregroundColor(.white)
                                        .font(.system(size: (recommendation.bestSize == "XXL" || recommendation.bestSize == "XXXL") ? 32 : 48))
                                        .fontWeight(.bold)
                                )
                        }
                        .padding(.bottom, -48)
                        .padding(.top, -8)
                        .zIndex(1)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fit Preference")
                                .font(.body16Regular)
                            
                            if recommendation.bestScore < 30 {
                                Text("This fit preference may not be ideal for your measurements")
                                    .font(.caption14Italic)
                            }
                            
                            SliderWithLabels(sliderValue: $sliderValue)
                                .padding(.horizontal, -16)
                            
                            bodyVisualization(recommendation: recommendation)
                                .padding(.bottom, -42)
                                .padding(.leading, UIScreen.main.bounds.width * 0.05)
                            
                            statusIndicators(recommendation: recommendation)
                        }
                        .padding(8)
                        .padding(.top, 38)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        Text("Note : Measurements can differ by ± 1 – 2 cm due to material variation.")
                            .font(.caption14Italic)
                            .foregroundStyle(Color(hex: "838383"))
                            .padding(.vertical, 4)
                    }
                    
                    Spacer()
                        .frame(height: 140)
                }
                .padding(.horizontal, 16)
            }
            
            // Buttons (hidden if from history)
            if !isFromHistory {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        RoolaButton(buttonTitle: "Save Result", buttonColor: AppColors.primaryPurple, action: {
                            showSaveModal = true
                        })
                        RoolaButton(buttonTitle: "Try Again", buttonColor: AppColors.primaryWhite, action: {
                            onTryAgain?()
                            showResults = false
                        })
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, UIScreen.main.bounds.height * 0.05)
                }
            }
            
            // Save Result Modal
            if showSaveModal {
                SaveResultModal(
                    isPresented: $showSaveModal,
                    productName: $productName,
                    shopName: $shopName,
                    onSave: {
                        saveToHistory()
                    }
                )
                .transition(.opacity)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSaveModal)
            }
            
            // Success Modal
            if showSuccessModal {
                SaveSuccessModal()
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSuccessModal)
            }
        }
    }
    
    // MARK: - Body Visualization
    
    @ViewBuilder
    private func bodyVisualization(recommendation: FitRecommendation) -> some View {
        ZStack {
            // Bust/Chest visualization
            Image(getBustImageName(recommendation: recommendation))
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
            
            // Arm length visualization (if used in calculation)
            Image(getArmImageName(recommendation: recommendation))
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
        }
    }
    
    private func getBustImageName(recommendation: FitRecommendation) -> String {
        // Check if there's a fit issue for bust
        if let bustIssue = recommendation.fitIssues?["bust"] {
            switch bustIssue.issue {
            case .tooTight:
                return "chest_red" // Too tight = red
            case .tooLoose:
                return "chest_blue" // Too loose = blue
            }
        }
        
        // Check partFits for bust (normal classification)
        if let bustFit = recommendation.partFits["bust"] {
            // If the fit matches the current preference, it's green (perfect)
            if bustFit == currentFitPreference {
                return "chest_green"
            }
            
            // If fit is tighter than preference
            let fitOrder = ["loose", "slightly-loose", "regular", "slightly-tight", "tight"]
            let currentIndex = fitOrder.firstIndex(of: currentFitPreference) ?? 2
            let actualIndex = fitOrder.firstIndex(of: bustFit) ?? 2
            
            if actualIndex > currentIndex {
                // Actual fit is tighter than preference → yellow warning
                return "chest_yellow"
            } else if actualIndex < currentIndex {
                // Actual fit is looser than preference → blue
                return "chest_blue"
            }
        }
        
        // Default: green (just right)
        return "chest_green"
    }
    
    private func getArmImageName(recommendation: FitRecommendation) -> String {
        // Check if arm_length is used in this clothing type
        let hasArmLength = recommendation.partFits["arm_length"] != nil ||
                          recommendation.fitIssues?["arm_length"] != nil
        
        if !hasArmLength {
            return "arm_length_empty"
        }
        
        // Check if there's a fit issue for arm_length
        if let armIssue = recommendation.fitIssues?["arm_length"] {
            switch armIssue.issue {
            case .tooTight:
                return "arm_length_red"
            case .tooLoose:
                return "arm_length_blue"
            }
        }
        
        // Check partFits for arm_length
        if let armFit = recommendation.partFits["arm_length"] {
            if armFit == currentFitPreference {
                return "arm_length_green"
            }
            
            let fitOrder = ["loose", "slightly-loose", "regular", "slightly-tight", "tight"]
            let currentIndex = fitOrder.firstIndex(of: currentFitPreference) ?? 2
            let actualIndex = fitOrder.firstIndex(of: armFit) ?? 2
            
            if actualIndex > currentIndex {
                return "arm_length_yellow"
            } else if actualIndex < currentIndex {
                return "arm_length_blue"
            }
        }
        
        return "arm_length_green"
    }
    
    // MARK: - Status Indicators
    
    @ViewBuilder
    private func statusIndicators(recommendation: FitRecommendation) -> some View {
        let status = getOverallStatus(recommendation: recommendation)
        
        VStack(alignment: .leading, spacing: 8) {
            if status.isAllGood {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, AppColors.successGreen)
                        .font(.system(size: 24))
                    Text("All parts just right")
                        .font(.caption14Italic)
                        .foregroundStyle(Color(hex: "838383"))
                }
            } else {
                // Show issues
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
    
    private func getOverallStatus(recommendation: FitRecommendation) -> (isAllGood: Bool, issues: [StatusIssue]) {
        // Group issues by type and severity
        var tooTightParts: [String] = []
        var tooLooseParts: [String] = []
        var slightlyOffParts: [(part: String, fit: String)] = []
        
        let parts = ["bust", "torso", "arm_length"]
        
        for part in parts {
            // Skip if part not used
            if recommendation.partFits[part] == nil && recommendation.fitIssues?[part] == nil {
                continue
            }
            
            let displayName = part == "bust" ? "Chest" : part.replacingOccurrences(of: "_", with: " ").capitalized
            
            // Check fit issues first (too tight/too loose)
            if let fitIssue = recommendation.fitIssues?[part] {
                if fitIssue.issue == .tooTight {
                    tooTightParts.append(displayName)
                } else {
                    tooLooseParts.append(displayName)
                }
            }
            // Check if fit doesn't match preference (slightly off)
            else if let partFit = recommendation.partFits[part], partFit != currentFitPreference {
                let fitDisplay = partFit.replacingOccurrences(of: "-", with: " ").capitalized
                slightlyOffParts.append((part: displayName, fit: fitDisplay))
            }
        }
        
        var issues: [StatusIssue] = []
        
        // Combine too tight parts into one message
        if !tooTightParts.isEmpty {
            let partsText = formatPartsList(tooTightParts)
            issues.append(StatusIssue(
                part: "tight",
                message: "\(partsText) will be too tight for this fit preference",
                icon: "xmark.circle.fill",
                iconForeground: .white,
                iconBackground: Color.red
            ))
        }
        
        // Combine too loose parts into one message
        if !tooLooseParts.isEmpty {
            let partsText = formatPartsList(tooLooseParts)
            issues.append(StatusIssue(
                part: "loose",
                message: "\(partsText) will be too loose for this fit preference",
                icon: "exclamationmark.circle.fill",
                iconForeground: .black,
                iconBackground: Color(hex: "FEC901").opacity(0.5)
            ))
        }
        
        // Combine slightly off parts by fit type
        if !slightlyOffParts.isEmpty {
            // Group by fit type
            var groupedByFit: [String: [String]] = [:]
            for item in slightlyOffParts {
                if groupedByFit[item.fit] == nil {
                    groupedByFit[item.fit] = []
                }
                groupedByFit[item.fit]?.append(item.part)
            }
            
            // Create message for each fit type
            for (fitType, parts) in groupedByFit {
                let partsText = formatPartsList(parts)
                let othersText = parts.count < 3 ? ", but others are just right" : ""
                issues.append(StatusIssue(
                    part: "slightly-off",
                    message: "\(partsText) will be \(fitType)\(othersText)",
                    icon: "exclamationmark.circle.fill",
                    iconForeground: .black,
                    iconBackground: Color(hex: "FEC901").opacity(0.5)
                ))
            }
        }
        
        return (isAllGood: issues.isEmpty, issues: issues)
    }
    
    // Helper function to format parts list like "Chest and Torso" or "Chest, Torso and Arm Length"
    private func formatPartsList(_ parts: [String]) -> String {
        guard !parts.isEmpty else { return "" }
        
        if parts.count == 1 {
            return parts[0]
        } else if parts.count == 2 {
            return "\(parts[0]) and \(parts[1])"
        } else {
            let lastPart = parts.last!
            let otherParts = parts.dropLast().joined(separator: ", ")
            return "\(otherParts) and \(lastPart)"
        }
    }
}

struct StatusIssue {
    let part: String
    let message: String
    let icon: String
    let iconForeground: Color
    let iconBackground: Color
}

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
            }.padding(.horizontal, -8)
        }
    }
}

#Preview {
    ResultsView(viewModel: RecommendationViewModel(), showResults: .constant(true))
}
