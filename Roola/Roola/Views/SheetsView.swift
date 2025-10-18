//
//  SheetsView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 18/10/25.
//

import SwiftUI
import SwiftData

// MARK: - Fuzzy Logic Recommendation Engine

/// Represents the desired fit preference of the user. This can be controlled by a UI element.
enum FitPreference: String, CaseIterable {
    case skinny = "Skinny"
    case slim = "Slim"
    case regular = "Regular"
    case loose = "Loose"
}

/// Defines the four points of a trapezoidal membership function [a, b, c, d] for fuzzy logic.
fileprivate struct TrapezoidalFunction {
    let a, b, c, d: Double
}

/// A collection of fuzzy logic calculation helpers.
fileprivate struct FuzzyEngine {
    
    /// Defines the membership functions for each fit type based on clothing 'ease'.
    /// Ease is the difference (in cm) between the garment's measurement and the user's measurement.
    static let fitFunctions: [FitPreference: TrapezoidalFunction] = [
        .skinny:  TrapezoidalFunction(a: -2, b: 0, c: 2, d: 4),
        .slim:    TrapezoidalFunction(a: 2, b: 4, c: 7, d: 10),
        .regular: TrapezoidalFunction(a: 7, b: 10, c: 14, d: 17),
        .loose:   TrapezoidalFunction(a: 14, b: 17, c: 22, d: 25)
    ]
    
    /// Calculates the degree of membership (0.0 to 1.0) for a value in a trapezoidal fuzzy set.
    /// This is the Swift equivalent of `skfuzzy.interp_membership`.
    static func interpretMembership(value: Double, in function: TrapezoidalFunction) -> Double {
        let (a, b, c, d) = (function.a, function.b, function.c, function.d)
        
        // Value is outside the bounds of the function
        if value <= a || value >= d { return 0.0 }
        // Value is in the core, fully-membership range
        if value >= b && value <= c { return 1.0 }
        // Value is on the rising slope
        if value > a && value < b { return (value - a) / (b - a) }
        // Value is on the falling slope
        if value > c && value < d { return (d - value) / (d - c) }
        
        return 0.0 // Default fallback
    }
    
    /// Calculates a fit score (0-100) based on the ease and desired fit.
    static func calculateFuzzyFitScore(ease: Double, desiredFit: FitPreference) -> Double {
        guard let membershipFunc = fitFunctions[desiredFit] else {
            return 0.0
        }
        
        let degree = interpretMembership(value: ease, in: membershipFunc)
        return degree * 100
    }
}

// MARK: - Recommender Configuration

/// Configuration for a specific clothing type, defining relevant parts and their importance.
fileprivate struct RecommenderConfig {
    let relevantParts: [String]
    let partWeights: [String: Double]
}

/// Central configuration mapping clothing types to their recommendation settings.
/// **Note:** We map "waist" from the logic to the "torso" measurement in your SwiftData model.
fileprivate let RECOMMENDER_CONFIG: [String: RecommenderConfig] = [
    // Configuration for T-Shirts
    "T-Shirt": RecommenderConfig(
        relevantParts: ["bust", "waist"],
        partWeights: ["bust": 0.7, "waist": 0.3]
    ),
    // Configuration for Jeans
    "Jeans": RecommenderConfig(
        relevantParts: ["waist", "hip", "inseam"],
        partWeights: ["waist": 0.5, "hip": 0.4, "inseam": 0.1]
    )
    // You can add more clothing types like "Jacket", "Pants", etc. here.
]


struct SheetView: View {
    // Inputs from the previous view
    let clothes: Clothes
    
    // Environment and Data Fetching
    @Environment(\.dismiss) var dismiss
    @Query var users: [User]
    private var user: User? { users.first }
    
    // State for the view
    @State private var recommendedSize: String = "Calculating..."
    @State private var selectedSize: String = ""
    
    // **NEW**: State for the user's desired fit. This can be controlled by a Picker in the UI.
    @State private var desiredFit: FitPreference = .regular
    
    // A computed property for available size names
    private var availableSizes: [String] {
        clothes.product_sizes.map { $0.size_name }.sorted() // Sort them for consistent order
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - DEBUGGING CHECK
            // Add this block to verify user data.
            Group {
                if let currentUser = user {
                    Text("✅ User Data Loaded: Bust is \(currentUser.bust, specifier: "%.1f") cm")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("❌ User Data Not Found")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            // MARK: - END DEBUGGING CHECK
            
            Text("Your Best Fit Recommendation")
                .font(.headline)
                .padding(.top)
            
            // You could add a Picker here to allow the user to change their fit preference
            // Example:
            // Picker("Desired Fit", selection: $desiredFit) {
            //     ForEach(FitPreference.allCases, id: \.self) { Text($0.rawValue) }
            // }
            // .pickerStyle(.segmented)
            
            HStack(alignment: .center, spacing: 30) {
                // Left side: Recommendation and Size Picker
                VStack(spacing: 15) {
                    Text(recommendedSize)
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .frame(minHeight: 70)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    // Size Selection Buttons
                    HStack(spacing: 10) {
                        ForEach(availableSizes, id: \.self) { size in
                            Button(action: {
                                selectedSize = size
                            }) {
                                Text(size)
                                    .fontWeight(.medium)
                                    .frame(width: 45, height: 45)
                                    .background(selectedSize == size ? Color.black : Color(UIColor.systemGray5))
                                    .foregroundColor(selectedSize == size ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                
                // Right side: Clothing Icon
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 80))
                    .frame(width: 120, height: 160)
                    .foregroundStyle(.secondary)
            }
            
            // Dismiss Button
            Button("Done") {
                dismiss()
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.black)
            .foregroundColor(.white)
            .cornerRadius(12)
            
        }
        .padding()
        .onAppear(perform: calculateBestSizeWithFuzzyLogic) // Use the new logic
        // If you add a picker, you might want to re-calculate when the fit changes:
        // .onChange(of: desiredFit) { _, _ in calculateBestSizeWithFuzzyLogic() }
    }
    
    /// **[REPLACED]** Calculates the best size by comparing user measurements to the clothing's variants using fuzzy logic.
    private func calculateBestSizeWithFuzzyLogic() {
        // 1. Ensure we have user data and a valid config for the clothing type
        guard let user = user else {
            recommendedSize = "N/A"
            return
        }
        
        // TODO: Replace "T-Shirt" with a property from your `clothes` model, like `clothes.product_type`
        guard let config = RECOMMENDER_CONFIG["T-Shirt"] else {
            recommendedSize = "Unsupported"
            print("Error: No recommender config found for this clothing type.")
            return
        }
        
        var sizeScores: [String: Double] = [:]
        
        // 2. Iterate through each available size variant
        for sizeVariant in clothes.product_sizes {
            var partScores: [String: Double] = [:]
            
            // 3. For each relevant body part, calculate the fuzzy fit score
            for part in config.relevantParts {
                let userMeasurement: Double?
                let garmentMeasurement: Double?
                
                // Map the part name to the actual data model properties
                // **Note**: We use the average of min/max for the garment's dimension.
                switch part {
                case "bust":
                    userMeasurement = Double(user.bust)
                    garmentMeasurement = Double((sizeVariant.clothes_bust_min + sizeVariant.clothes_bust_max) / 2)
                case "waist": // Mapping "waist" from config to "torso" in the data model
                    userMeasurement = Double(user.torso)
                    garmentMeasurement = Double((sizeVariant.clothes_torso_min + sizeVariant.clothes_torso_max) / 2)
                // Add cases for "hip", "inseam", etc., if your models support them
                default:
                    userMeasurement = nil
                    garmentMeasurement = nil
                }
                
                // Calculate ease and fuzzy score
                if let userM = userMeasurement, let garmentM = garmentMeasurement {
                    let ease = garmentM - userM
                    let score = FuzzyEngine.calculateFuzzyFitScore(ease: ease, desiredFit: desiredFit)
                    partScores[part] = score
                }
            }
            
            // 4. Calculate the final weighted score for this size variant
            var overallScore: Double = 0
            var totalWeight: Double = 0
            
            for (part, score) in partScores {
                if let weight = config.partWeights[part] {
                    overallScore += score * weight
                    totalWeight += weight
                }
            }
            
            let finalScore = totalWeight > 0 ? (overallScore / totalWeight) : 0
            sizeScores[sizeVariant.size_name] = finalScore
        }
        
        // 5. Find the size with the highest score
        if let bestSize = sizeScores.max(by: { a, b in a.value < b.value }), bestSize.value > 0 {
            recommendedSize = bestSize.key
            selectedSize = bestSize.key
        } else {
            recommendedSize = "No Fit"
            selectedSize = availableSizes.first ?? ""
        }
    }
}
