//
//  SheetViewModel.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 18/10/25.
//

import SwiftUI
import Combine

// MARK: - Fuzzy Logic Recommendation Engine & Configuration

/// Represents the desired fit preference of the user.
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
    static let fitFunctions: [FitPreference: TrapezoidalFunction] = [
        .skinny:  TrapezoidalFunction(a: -2, b: 0, c: 2, d: 4),
        .slim:    TrapezoidalFunction(a: 2, b: 4, c: 7, d: 10),
        .regular: TrapezoidalFunction(a: 7, b: 10, c: 14, d: 17),
        .loose:   TrapezoidalFunction(a: 14, b: 17, c: 22, d: 25)
    ]
    
    /// Calculates the degree of membership (0.0 to 1.0) for a value in a trapezoidal fuzzy set.
    static func interpretMembership(value: Double, in function: TrapezoidalFunction) -> Double {
        let (a, b, c, d) = (function.a, function.b, function.c, function.d)
        if value <= a || value >= d { return 0.0 }
        if value >= b && value <= c { return 1.0 }
        if value > a && value < b { return (value - a) / (b - a) }
        if value > c && value < d { return (d - value) / (d - c) }
        return 0.0
    }
    
    /// Calculates a fit score (0-100) based on the ease and desired fit.
    static func calculateFuzzyFitScore(ease: Double, desiredFit: FitPreference) -> Double {
        guard let membershipFunc = fitFunctions[desiredFit] else { return 0.0 }
        let degree = interpretMembership(value: ease, in: membershipFunc)
        return degree * 100
    }
}

/// Configuration for a specific clothing type.
fileprivate struct RecommenderConfig {
    let relevantParts: [String]
    let partWeights: [String: Double]
}

/// Central configuration mapping clothing types to their recommendation settings.
fileprivate let RECOMMENDER_CONFIG: [String: RecommenderConfig] = [
    "T-Shirt": RecommenderConfig(relevantParts: ["bust", "waist"], partWeights: ["bust": 0.7, "waist": 0.3]),
    "Jeans": RecommenderConfig(relevantParts: ["waist", "hip", "inseam"], partWeights: ["waist": 0.5, "hip": 0.4, "inseam": 0.1])
]


@MainActor
class SheetViewModel: ObservableObject {
    // MARK: - Published Properties for the View
    
    @Published var recommendedSize: String = "Calculating..."
    @Published var selectedSize: String = ""
    @Published var desiredFit: FitPreference = .regular
    
    // MARK: - Private Properties
    private var clothes: Clothes?
    private var user: User?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to changes in the 'desiredFit' property
        $desiredFit
            .dropFirst() // Ignore the initial value
            .sink { [weak self] _ in
                self?.calculateBestSizeWithFuzzyLogic()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Configures the view model with the necessary data and runs the initial calculation.
    func setup(clothes: Clothes, user: User?) {
        self.clothes = clothes
        self.user = user
        calculateBestSizeWithFuzzyLogic()
    }
    
    /// Updates the currently selected size.
    func selectSize(_ size: String) {
        self.selectedSize = size
    }
    
    // MARK: - Private Calculation Logic
    
    private func calculateBestSizeWithFuzzyLogic() {
        guard let user = self.user, let clothes = self.clothes else {
            recommendedSize = "N/A"
            return
        }
        
        // TODO: Replace "T-Shirt" with a dynamic property from your `clothes` model
        guard let config = RECOMMENDER_CONFIG["T-Shirt"] else {
            recommendedSize = "Unsupported"
            return
        }
        
        var sizeScores: [String: Double] = [:]

        for sizeVariant in clothes.product_sizes {
            var partScores: [String: Double] = [:]
            
            for part in config.relevantParts {
                let userMeasurement: Double?
                let garmentMeasurement: Double?
                
                switch part {
                case "bust":
                    userMeasurement = Double(user.bust)
                    garmentMeasurement = Double((sizeVariant.clothes_bust_min + sizeVariant.clothes_bust_max) / 2)
                case "waist":
                    userMeasurement = Double(user.torso)
                    garmentMeasurement = Double((sizeVariant.clothes_torso_min + sizeVariant.clothes_torso_max) / 2)
                default:
                    userMeasurement = nil; garmentMeasurement = nil
                }
                
                if let userM = userMeasurement, let garmentM = garmentMeasurement {
                    let ease = garmentM - userM
                    let score = FuzzyEngine.calculateFuzzyFitScore(ease: ease, desiredFit: desiredFit)
                    partScores[part] = score
                }
            }
            
            var overallScore: Double = 0
            var totalWeight: Double = 0
            
            for (part, score) in partScores {
                if let weight = config.partWeights[part] {
                    overallScore += score * weight
                    totalWeight += weight
                }
            }
            sizeScores[sizeVariant.size_name] = totalWeight > 0 ? (overallScore / totalWeight) : 0
        }
        
        if let bestSize = sizeScores.max(by: { $0.value < $1.value }), bestSize.value > 0 {
            recommendedSize = bestSize.key
            selectedSize = bestSize.key
        } else {
            recommendedSize = "No Fit"
            selectedSize = clothes.product_sizes.map { $0.size_name }.sorted().first ?? ""
        }
    }
}
