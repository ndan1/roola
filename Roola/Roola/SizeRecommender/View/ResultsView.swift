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
            FirstGradientBackground().ignoresSafeArea()
            
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
                    HStack (alignment: .center, spacing: 8){
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
//                            .padding(.top, 8)
                        }
                        
                        Text("Recommended Size")
                            .font(isFromHistory ? .system(size: 30): .heading32Medium)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding(.top, 60)
                    
                    VStack(alignment: .center) {
                        // Size Badge
                        ZStack {
                            Circle()
                                .frame(width: UIScreen.main.bounds.width * 0.2, height: UIScreen.main.bounds.width * 0.2)
                                .foregroundColor(Color(AppColors.primaryPurple))
                                .overlay(
                                    Text(recommendation.bestSize)
                                        .foregroundColor(.white)
                                        .font(.system(size: (recommendation.bestSize == "XXL") ? 28 : recommendation.bestSize == "XXXL" ? 24 : recommendation.bestSize == "XL" ? 36 : recommendation.bestSize == "L" ? 48 : recommendation.bestSize == "M" ? 48 : recommendation.bestSize == "S" ? 48 : recommendation.bestSize == "XS" ? 36 : 18))
                                        .fontWeight(.bold)
                                )
                        }
                        .padding(.bottom, -48)
                        .padding(.top, -8)
                        .zIndex(1)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            if recommendation.bestScore < 30 {
                                Text("Looser fit may not be available for this item")
                                    .font(.caption14Italic)
                                    .foregroundColor(AppColors.grayScale300)
                            }
                            else{
                                Text("")
                                    .font(.caption14Italic)
                            }
                            Text("Fit Preference")
                                .font(.body16Regular)
                            
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
        // 🔍 DEBUG: Log data untuk troubleshooting
        print("🔍 [CHEST DEBUG] partFits[bust]: \(recommendation.partFits["bust"] ?? "nil")")
        print("🔍 [CHEST DEBUG] fitIssues[bust]: \(recommendation.fitIssues?["bust"]?.issue.rawValue ?? "nil")")
        print("🔍 [CHEST DEBUG] currentFitPreference: \(currentFitPreference)")
        
        // Check if there's a fit issue for bust
        if let bustIssue = recommendation.fitIssues?["bust"] {
            switch bustIssue.issue {
            case .tooTight:
                print("🔍 [CHEST DEBUG] → Returning chest_red (too tight)")
                return "chest_red" // Too tight = red
            case .tooLoose:
                print("🔍 [CHEST DEBUG] → Returning chest_blue (too loose)")
                return "chest_blue" // Too loose = blue
            }
        }
        
        // Check partFits for bust (normal classification)
        if let bustFit = recommendation.partFits["bust"] {
            // If the fit matches the current preference, it's green (perfect)
            if bustFit == currentFitPreference {
                print("🔍 [CHEST DEBUG] → Returning chest_green (perfect fit: \(bustFit) == \(currentFitPreference))")
                return "chest_green"
            }
            
            // ✅ FIX: Array order must be consistent
            // tight(0) → slightly-tight(1) → regular(2) → slightly-loose(3) → loose(4)
            let fitOrder = ["tight", "slightly-tight", "regular", "slightly-loose", "loose"]
            let currentIndex = fitOrder.firstIndex(of: currentFitPreference) ?? 2
            let actualIndex = fitOrder.firstIndex(of: bustFit) ?? 2
            
            // ✅ FIX: Correct direction logic
            // actualIndex > currentIndex → actual fit is LOOSER (higher index)
            // actualIndex < currentIndex → actual fit is TIGHTER (lower index)
            if actualIndex > currentIndex {
                // Actual fit is LOOSER than preference → yellow warning (distance 1) or blue (distance 2+)
                let distance = actualIndex - currentIndex
                if distance == 1 {
                    print("🔍 [CHEST DEBUG] → Returning chest_yellow (slightly looser: \(bustFit))")
                    return "chest_yellow"
                } else {
                    print("🔍 [CHEST DEBUG] → Returning chest_blue (much looser: \(bustFit))")
                    return "chest_blue"
                }
            } else if actualIndex < currentIndex {
                // Actual fit is TIGHTER than preference → yellow (distance 1) or red (distance 2+)
                let distance = currentIndex - actualIndex
                if distance == 1 {
                    print("🔍 [CHEST DEBUG] → Returning chest_yellow (slightly tighter: \(bustFit))")
                    return "chest_yellow"
                } else {
                    print("🔍 [CHEST DEBUG] → Returning chest_red (too tight: \(bustFit))")
                    return "chest_red"
                }
            }
        }
        
        // Default: green (just right)
        print("🔍 [CHEST DEBUG] → Returning chest_green (default fallback)")
        return "chest_green"
    }
    
    private func getArmImageName(recommendation: FitRecommendation) -> String {
        // Check if arm_length is used in this clothing type
        let hasArmLength = recommendation.partFits["arm_length"] != nil ||
                          recommendation.fitIssues?["arm_length"] != nil
        
        if !hasArmLength {
            return "arm_length_empty"
        }
        
        // 🔍 DEBUG: Log data untuk troubleshooting
        print("🔍 [ARM DEBUG] partFits[arm_length]: \(recommendation.partFits["arm_length"] ?? "nil")")
        print("🔍 [ARM DEBUG] fitIssues[arm_length]: \(recommendation.fitIssues?["arm_length"]?.issue.rawValue ?? "nil")")
        print("🔍 [ARM DEBUG] currentFitPreference: \(currentFitPreference)")
        
        // Check if there's a fit issue for arm_length
        if let armIssue = recommendation.fitIssues?["arm_length"] {
            switch armIssue.issue {
            case .tooTight:
                print("🔍 [ARM DEBUG] → Returning arm_length_red (too tight)")
                return "arm_length_red"
            case .tooLoose:
                print("🔍 [ARM DEBUG] → Returning arm_length_blue (too loose)")
                return "arm_length_blue"
            }
        }
        
        // Check partFits for arm_length
        if let armFit = recommendation.partFits["arm_length"] {
            if armFit == currentFitPreference {
                print("🔍 [ARM DEBUG] → Returning arm_length_green (perfect fit: \(armFit) == \(currentFitPreference))")
                return "arm_length_green"
            }
            
            // ✅ FIX: Fit order harus konsisten dengan fitHierarchy
            // tight(0) → slightly-tight(1) → regular(2) → slightly-loose(3) → loose(4)
            let fitOrder = ["tight", "slightly-tight", "regular", "slightly-loose", "loose"]
            let currentIndex = fitOrder.firstIndex(of: currentFitPreference) ?? 2
            let actualIndex = fitOrder.firstIndex(of: armFit) ?? 2
            
            // ✅ FIX: Logic direction
            // actualIndex < currentIndex → actual fit lebih TIGHT (index lebih kecil)
            // actualIndex > currentIndex → actual fit lebih LOOSE (index lebih besar)
            if actualIndex < currentIndex {
                print("🔍 [ARM DEBUG] → Returning arm_length_yellow (tighter: \(armFit))")
                return "arm_length_yellow"
            } else if actualIndex > currentIndex {
                print("🔍 [ARM DEBUG] → Returning arm_length_blue (looser: \(armFit))")
                return "arm_length_blue"
            }
        }
        
        print("🔍 [ARM DEBUG] → Returning arm_length_green (default fallback)")
        return "arm_length_green"
    }
    
    // MARK: - Status Indicators
    
    @ViewBuilder
    private func statusIndicators(recommendation: FitRecommendation) -> some View {
        let status = getOverallStatus(recommendation: recommendation)
        
        // Determine message based on clothing type
        let shortSleevedTypes = ["short_sleeved_shirt", "t-shirt", "t_shirt"]
        let isShortSleeved = shortSleevedTypes.contains(viewModel.clothingType.lowercased())
        let perfectMessage = isShortSleeved ? "Chest area is just right" : "Chest and arm area is just right"
        
        VStack(alignment: .leading, spacing: 8) {
            if status.isAllGood {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, AppColors.successGreen)
                        .font(.system(size: 24))
                    Text(perfectMessage)
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
        // Fit hierarchy untuk calculate distance
        let fitHierarchy = ["tight", "slightly-tight", "regular", "slightly-loose", "loose"]
        
        // Determine which parts to show based on clothing type
        // Short-sleeved & T-shirt: only chest (1 baris)
        // Long-sleeved & Blouse: chest + arm (2 baris terpisah, kecuali keduanya perfect)
        let shortSleevedTypes = ["short_sleeved_shirt", "t-shirt", "t_shirt"]
        let isShortSleeved = shortSleevedTypes.contains(viewModel.clothingType.lowercased())
        
        let parts = isShortSleeved ? ["bust"] : ["bust", "arm_length"]
        
        // Track status for each part individually
        var partStatuses: [String: (distance: Int, direction: String, isPerfect: Bool)] = [:]
        
        for part in parts {
            // Skip if part not used
            if recommendation.partFits[part] == nil && recommendation.fitIssues?[part] == nil {
                continue
            }
            
            let displayName = part == "bust" ? "Chest" : "Arm"
            
            // Check fit issues first (too tight/too loose)
            if let fitIssue = recommendation.fitIssues?[part] {
                if fitIssue.issue == .tooTight {
                    partStatuses[displayName] = (distance: 2, direction: "tight", isPerfect: false)
                } else {
                    partStatuses[displayName] = (distance: 2, direction: "loose", isPerfect: false)
                }
            }
            // Check if fit doesn't match preference (slightly off)
            else if let partFit = recommendation.partFits[part], partFit != currentFitPreference {
                // Calculate distance between fits
                let currentIndex = fitHierarchy.firstIndex(of: currentFitPreference) ?? 2
                let partIndex = fitHierarchy.firstIndex(of: partFit) ?? 2
                let distance = abs(currentIndex - partIndex)
                
                // ✅ FIX: Determine if it's tighter or looser
                // fitHierarchy = ["tight"(0), "slightly-tight"(1), "regular"(2), "slightly-loose"(3), "loose"(4)]
                // partIndex > currentIndex → part actual fit lebih LOOSE (index lebih besar)
                // partIndex < currentIndex → part actual fit lebih TIGHT (index lebih kecil)
                if partIndex > currentIndex {
                    // Part actual fit lebih loose dari preference
                    partStatuses[displayName] = (distance: distance, direction: "loose", isPerfect: false)
                } else {
                    // Part actual fit lebih tight dari preference
                    partStatuses[displayName] = (distance: distance, direction: "tight", isPerfect: false)
                }
            } else {
                // Perfect fit
                partStatuses[displayName] = (distance: 0, direction: "", isPerfect: true)
            }
        }
        
        var issues: [StatusIssue] = []
        
        // Check if both parts are perfect (for long-sleeved)
        let allPerfect = partStatuses.values.allSatisfy { $0.isPerfect }
        
        if allPerfect {
            // Already handled in statusIndicators() view - isAllGood
            return (isAllGood: true, issues: [])
        }
        
        // Process each part SEPARATELY (2 baris untuk long-sleeved)
        // Order: Chest first, then Arm
        for partName in ["Chest", "Arm"] {
            guard let status = partStatuses[partName] else { continue }
            
            // ✅ FIX: Jika ada part yang perfect DAN ada part lain yang tidak perfect,
            // tetap tampilkan yang perfect dengan message "just right"
            if status.isPerfect {
                // Check if there are other parts that are NOT perfect
                let hasOtherIssues = partStatuses.values.contains { !$0.isPerfect }
                
                if hasOtherIssues {
                    // Show "just right" message for this perfect part
                    issues.append(StatusIssue(
                        part: "\(partName.lowercased())-perfect",
                        message: "\(partName) area is just right",
                        icon: "checkmark.circle.fill",
                        iconForeground: .white,
                        iconBackground: AppColors.successGreen
                    ))
                }
                continue
            }
            
            let distance = status.distance
            let direction = status.direction
            
            if direction == "tight" {
                if distance == 1 {
                    // Yellow warning
                    issues.append(StatusIssue(
                        part: "\(partName.lowercased())-tight-1",
                        message: "\(partName) area is slightly tight",
                        icon: "exclamationmark.circle.fill",
                        iconForeground: .black,
                        iconBackground: Color(hex: "FEC901").opacity(0.5)
                    ))
                } else if distance >= 2 {
                    // Red X
                    issues.append(StatusIssue(
                        part: "\(partName.lowercased())-tight-2",
                        message: "\(partName) area is too tight",
                        icon: "xmark.circle.fill",
                        iconForeground: .white,
                        iconBackground: Color.red
                    ))
                }
            } else if direction == "loose" {
                if distance == 1 {
                    // Yellow warning
                    issues.append(StatusIssue(
                        part: "\(partName.lowercased())-loose-1",
                        message: "\(partName) area slightly loose",
                        icon: "exclamationmark.circle.fill",
                        iconForeground: .black,
                        iconBackground: Color(hex: "FEC901").opacity(0.5)
                    ))
                } else if distance >= 2 {
                    // Blue arrow (very loose)
                    issues.append(StatusIssue(
                        part: "\(partName.lowercased())-loose-2",
                        message: "\(partName) area is very loose",
                        icon: "arrow.left.arrow.right.circle.fill",
                        iconForeground: .black,
                        iconBackground: Color(hex: "A7DCFF")
                    ))
                }
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
