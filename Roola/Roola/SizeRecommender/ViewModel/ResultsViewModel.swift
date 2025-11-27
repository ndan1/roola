//
//  ResultsViewModel.swift
//  Roola
//
//  Created by Lin Dan Christiano on 19/11/25.
//

import SwiftUI
import SwiftData

@MainActor
class ResultsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var sliderValue: Float = 2.0
    @Published var showSaveModal = false
    @Published var showSuccessModal = false
    @Published var productName = ""
    @Published var brandName = ""
    @Published var productLink = ""
    
    // MARK: - Dependencies
    private var modelContext: ModelContext?
    var onTryAgain: (() -> Void)?
    var onClose: (() -> Void)?
    
    // MARK: - Data
    var recommendationViewModel: RecommendationViewModel
    var initialFitPreference: String
    
    // MARK: - Constants
    private let fitOrderMap = ["tight", "slightly-tight", "regular", "slightly-loose", "loose"]
    private let shortSleevedTypes = ["short_sleeved_shirt", "t-shirt", "t_shirt"]
    
    // MARK: - Initialization
    init(recommendationViewModel: RecommendationViewModel, initialFitPreference: String = "standard") {
        self.recommendationViewModel = recommendationViewModel
        self.initialFitPreference = initialFitPreference
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Computed Properties
    
    var currentFitPreference: String {
        let index = Int(round(sliderValue))
        return fitOrderMap[min(max(index, 0), 4)]
    }
    
    var currentRecommendation: FitRecommendation? {
        guard let recommendations = recommendationViewModel.serverResponse?.recommendations else { return nil }
        
        switch currentFitPreference {
        case "tight": return recommendations.tight
        case "slightly-tight": return recommendations.slightlyTight
        case "regular": return recommendations.regular
        case "slightly-loose": return recommendations.slightlyLoose
        case "loose": return recommendations.loose
        default: return recommendations.regular
        }
    }
    
    var isShortSleeved: Bool {
        shortSleevedTypes.contains(recommendationViewModel.clothingType.lowercased())
    }
    
    // MARK: - Public Methods
    
    func setInitialSliderPosition() {
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
    
    func saveToHistory() {
        guard let serverResponse = recommendationViewModel.serverResponse,
              let userMeasurements = recommendationViewModel.userMeasurements,
              let modelContext = modelContext else {
            print("❌ Cannot save: missing data or context")
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
        
        let linkToSave = productLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : productLink
        
        // Create history entry
        let history = MeasurementHistory(
            productName: productName,
            brandName: brandName,
            productLink: linkToSave,
            clothingType: recommendationViewModel.clothingType,
            selectedFitPreference: currentFitPreference,
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
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showSuccessModal = false
                resetForm()
                onClose?()
                onTryAgain?()
            }
        } catch {
            print("❌ Failed to save history: \(error)")
        }
    }
    
    func resetForm() {
        productName = ""
        brandName = ""
        productLink = ""
    }
    
    // MARK: - Body Part Visualization Logic
    
    func getBustImageName(recommendation: FitRecommendation) -> String {
        print("🔍 [CHEST DEBUG] partFits[bust]: \(recommendation.partFits["bust"] ?? "nil")")
        print("🔍 [CHEST DEBUG] fitIssues[bust]: \(recommendation.fitIssues?["bust"]?.issue.rawValue ?? "nil")")
        print("🔍 [CHEST DEBUG] currentFitPreference: \(currentFitPreference)")
        
        // Check if there's a fit issue for bust
        if let bustIssue = recommendation.fitIssues?["bust"] {
            switch bustIssue.issue {
            case .tooTight:
                print("🔍 [CHEST DEBUG] → Returning chest_red (too tight)")
                return "chest_red"
            case .tooLoose:
                print("🔍 [CHEST DEBUG] → Returning chest_blue (too loose)")
                return "chest_blue"
            }
        }
        
        // Check partFits for bust
        if let bustFit = recommendation.partFits["bust"] {
            if bustFit == currentFitPreference {
                print("🔍 [CHEST DEBUG] → Returning chest_green (perfect fit: \(bustFit) == \(currentFitPreference))")
                return "chest_green"
            }
            
            let currentIndex = fitOrderMap.firstIndex(of: currentFitPreference) ?? 2
            let actualIndex = fitOrderMap.firstIndex(of: bustFit) ?? 2
            
            if actualIndex > currentIndex {
                let distance = actualIndex - currentIndex
                if distance == 1 {
                    print("🔍 [CHEST DEBUG] → Returning chest_yellow (slightly looser: \(bustFit))")
                    return "chest_yellow"
                } else {
                    print("🔍 [CHEST DEBUG] → Returning chest_blue (much looser: \(bustFit))")
                    return "chest_blue"
                }
            } else if actualIndex < currentIndex {
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
        
        print("🔍 [CHEST DEBUG] → Returning chest_green (default fallback)")
        return "chest_green"
    }
    
    func getArmImageName(recommendation: FitRecommendation) -> String {
        let hasArmLength = recommendation.partFits["arm_length"] != nil ||
                          recommendation.fitIssues?["arm_length"] != nil
        
        if !hasArmLength {
            return "arm_length_empty"
        }
        
        print("🔍 [ARM DEBUG] partFits[arm_length]: \(recommendation.partFits["arm_length"] ?? "nil")")
        print("🔍 [ARM DEBUG] fitIssues[arm_length]: \(recommendation.fitIssues?["arm_length"]?.issue.rawValue ?? "nil")")
        print("🔍 [ARM DEBUG] currentFitPreference: \(currentFitPreference)")
        
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
        
        if let armFit = recommendation.partFits["arm_length"] {
            if armFit == currentFitPreference {
                print("🔍 [ARM DEBUG] → Returning arm_length_green (perfect fit: \(armFit) == \(currentFitPreference))")
                return "arm_length_green"
            }
            
            let currentIndex = fitOrderMap.firstIndex(of: currentFitPreference) ?? 2
            let actualIndex = fitOrderMap.firstIndex(of: armFit) ?? 2
            
            if actualIndex < currentIndex {
                let distance = currentIndex - actualIndex
                if distance == 1 {
                    print("🔍 [ARM DEBUG] → Returning arm_length_yellow (slightly tighter: \(armFit))")
                    return "arm_length_yellow"
                } else {
                    print("🔍 [ARM DEBUG] → Returning arm_length_red (too tight: \(armFit))")
                    return "arm_length_red"
                }
            } else if actualIndex > currentIndex {
                let distance = actualIndex - currentIndex
                if distance == 1 {
                    print("🔍 [ARM DEBUG] → Returning arm_length_yellow (slightly looser: \(armFit))")
                    return "arm_length_yellow"
                } else {
                    print("🔍 [ARM DEBUG] → Returning arm_length_blue (much looser: \(armFit))")
                    return "arm_length_blue"
                }
            }
        }
        
        print("🔍 [ARM DEBUG] → Returning arm_length_green (default fallback)")
        return "arm_length_green"
    }
    
    // MARK: - Status Logic
    
    func getOverallStatus(recommendation: FitRecommendation) -> (isAllGood: Bool, issues: [StatusIssue]) {
        let parts = isShortSleeved ? ["bust"] : ["bust", "arm_length"]
        
        var partStatuses: [String: (distance: Int, direction: String, isPerfect: Bool)] = [:]
        
        for part in parts {
            if recommendation.partFits[part] == nil && recommendation.fitIssues?[part] == nil {
                continue
            }
            
            let displayName = part == "bust" ? "Chest" : "Arm"
            
            if let fitIssue = recommendation.fitIssues?[part] {
                if fitIssue.issue == .tooTight {
                    partStatuses[displayName] = (distance: 2, direction: "tight", isPerfect: false)
                } else {
                    partStatuses[displayName] = (distance: 2, direction: "loose", isPerfect: false)
                }
            } else if let partFit = recommendation.partFits[part], partFit != currentFitPreference {
                let currentIndex = fitOrderMap.firstIndex(of: currentFitPreference) ?? 2
                let partIndex = fitOrderMap.firstIndex(of: partFit) ?? 2
                let distance = abs(currentIndex - partIndex)
                
                if partIndex > currentIndex {
                    partStatuses[displayName] = (distance: distance, direction: "loose", isPerfect: false)
                } else {
                    partStatuses[displayName] = (distance: distance, direction: "tight", isPerfect: false)
                }
            } else {
                partStatuses[displayName] = (distance: 0, direction: "", isPerfect: true)
            }
        }
        
        var issues: [StatusIssue] = []
        
        let allPerfect = partStatuses.values.allSatisfy { $0.isPerfect }
        
        if allPerfect {
            return (isAllGood: true, issues: [])
        }
        
        for partName in ["Chest", "Arm"] {
            guard let status = partStatuses[partName] else { continue }
            
            if status.isPerfect {
                let hasOtherIssues = partStatuses.values.contains { !$0.isPerfect }
                
                if hasOtherIssues {
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
                    issues.append(StatusIssue(
                        part: "\(partName.lowercased())-tight-1",
                        message: "\(partName) area will be slightly tight",
                        icon: "exclamationmark.circle.fill",
                        iconForeground: .black,
                        iconBackground: Color(hex: "FEC901").opacity(0.5)
                    ))
                } else if distance >= 2 {
                    issues.append(StatusIssue(
                        part: "\(partName.lowercased())-tight-2",
                        message: "\(partName) area will be too tight",
                        icon: "x.circle.fill",
                        iconForeground: .white,
                        iconBackground: Color.red
                    ))
                }
            } else if direction == "loose" {
                if distance == 1 {
                    issues.append(StatusIssue(
                        part: "\(partName.lowercased())-loose-1",
                        message: "\(partName) will be slightly loose",
                        icon: "exclamationmark.circle.fill",
                        iconForeground: .black,
                        iconBackground: Color(hex: "FEC901").opacity(0.5)
                    ))
                } else if distance >= 2 {
                    issues.append(StatusIssue(
                        part: "\(partName.lowercased())-loose-2",
                        message: "\(partName) area will be very loose",
                        icon: "arrow.left.arrow.right.circle.fill",
                        iconForeground: .black,
                        iconBackground: Color(hex: "A7DCFF")
                    ))
                }
            }
        }
        
        return (isAllGood: issues.isEmpty, issues: issues)
    }
    
    func getPerfectFitMessage() -> String {
        let hasArmLengthData = currentRecommendation?.partFits["arm_length"] != nil ||
                               currentRecommendation?.fitIssues?["arm_length"] != nil
        
        let shouldMentionArm = !isShortSleeved && hasArmLengthData
        return shouldMentionArm ? "Chest and arm area is just right" : "Chest area is just right"
    }
}
