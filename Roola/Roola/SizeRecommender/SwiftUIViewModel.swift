//
//  FuzzyRecommenderViewModel.swift
//  Roola
//
//  Created by Lin Dan Christiano on 30/10/25.
//
//  This file is a port of the Python fuzzy logic from main.py and config.json.
//  It runs the recommendation engine locally instead of calling an API.
//

import Foundation
import Combine

// MARK: - Fuzzy Logic Configuration (from config.json)

/// Represents the configuration for a single clothing type (e.g., "t_shirt").
fileprivate struct ClothingConfig {
    let partWeights: [String: Double]
    let relevantParts: [RelevantPart]
}

/// Represents the configuration for a single body part (e.g., "bust").
fileprivate struct RelevantPart {
    let partName: String
    let easeUniverse: [Double] // min, max, step. Note: We'll primarily use min/max.
    let fitFunctions: [String: [Double]] // "tight": [a, b, c, d]
}

/// This dictionary holds the entire configuration, translated from config.json.
fileprivate let RECOMMENDER_CONFIG: [String: ClothingConfig] = [
    "t_shirt": ClothingConfig(
        partWeights: [
            "bust": 0.6,
            "torso": 0.4
        ],
        relevantParts: [
            RelevantPart(
                partName: "bust",
                easeUniverse: [-10, 41, 1],
                fitFunctions: [
                    "tight": [-10, -5, -2, 0],
                    "slightly-tight": [-2, 0, 2, 4],
                    "regular": [0, 2, 4, 8],
                    "slightly-loose": [6, 10, 16, 20],
                    "loose": [18, 20, 41, 41]
                ]
            ),
            RelevantPart(
                partName: "torso",
                easeUniverse: [-10, 21, 1],
                fitFunctions: [
                    "tight": [-10, -10, -5, -4],
                    "slightly-tight": [-5, -4, 0, 1],
                    "regular": [0, 1, 5, 6],
                    "slightly-loose": [5, 6, 10, 12],
                    "loose": [10, 13, 21, 21]
                ]
            )
        ]
    ),
    "short_sleeved_shirt": ClothingConfig(
        partWeights: [
            "bust": 0.6,
            "torso": 0.4
        ],
        relevantParts: [
            RelevantPart(
                partName: "bust",
                easeUniverse: [-10, 41, 1],
                fitFunctions: [
                    "tight": [-10, -5, -2, 0],
                    "slightly-tight": [-2, 0, 2, 4],
                    "regular": [0, 2, 4, 8],
                    "slightly-loose": [6, 10, 16, 20],
                    "loose": [18, 20, 41, 41]
                ]
            ),
            RelevantPart(
                partName: "torso",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-10, -10, -5, -4],
                    "slightly-tight": [-5, -4, 0, 1],
                    "regular": [0, 1, 5, 6],
                    "slightly-loose": [5, 6, 10, 12],
                    "loose": [10, 13, 21, 21]
                ]
            )
        ]
    ),
    "blouse": ClothingConfig(
        partWeights: [
            "bust": 0.5,
            "torso": 0.3,
            "shoulder_width": 0,
            "arm_length": 0.2
        ],
        relevantParts: [
            RelevantPart(
                partName: "bust",
                easeUniverse: [-10, 41, 1],
                fitFunctions: [
                    "tight": [-10, -5, -2, 0],
                    "slightly-tight": [-2, 0, 2, 6],
                    "regular": [4, 6, 10, 12],
                    "slightly-loose": [10, 14, 16, 20],
                    "loose": [18, 20, 41, 41]
                ]
            ),
            RelevantPart(
                partName: "torso",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-10, -10, -5, -4],
                    "slightly-tight": [-5, -4, 0, 1],
                    "regular": [0, 1, 5, 6],
                    "slightly-loose": [5, 6, 10, 12],
                    "loose": [10, 13, 21, 21]
                ]
            ),
            RelevantPart(
                partName: "arm_length",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-5, -5, -5, -2],
                    "slightly-tight": [-2, -1, 0, 1],
                    "regular": [0, 1, 2, 3],
                    "slightly-loose": [2, 3, 4, 5],
                    "loose": [4, 5, 21, 21]
                ]
            )
        ]
    ),
    "long_sleeved_shirt": ClothingConfig(
        partWeights: [
            "bust": 0.5,
            "torso": 0.3,
            "shoulder_width": 0,
            "arm_length": 0.2
        ],
        relevantParts: [
            RelevantPart(
                partName: "bust",
                easeUniverse: [-10, 41, 1],
                fitFunctions: [
                    "tight": [-10, -5, -2, 0],
                    "slightly-tight": [-2, 0, 2, 4],
                    "regular": [0, 2, 4, 8],
                    "slightly-loose": [6, 10, 16, 20],
                    "loose": [18, 20, 41, 41]
                ]
            ),
            RelevantPart(
                partName: "torso",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-10, -10, -5, -4],
                    "slightly-tight": [-5, -4, 0, 1],
                    "regular": [0, 1, 5, 6],
                    "slightly-loose": [5, 6, 10, 12],
                    "loose": [10, 13, 21, 21]
                ]
            ),
            RelevantPart(
                partName: "arm_length",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-5, -5, -5, -2],
                    "slightly-tight": [-2, -1, 0, 1],
                    "regular": [0, 1, 2, 3],
                    "slightly-loose": [2, 3, 4, 5],
                    "loose": [4, 5, 21, 21]
                ]
            )
        ]
    )
]

// MARK: - Fuzzy Logic Helpers (Ported from skfuzzy)

/// A Swift implementation of Python's `skfuzzy.trapmf`.
/// Calculates the membership value for a point `x` in a trapezoidal function
/// defined by `[a, b, c, d]`.
///
/// - Parameters:
///   - x: The value to evaluate.
///   - params: A 4-element array `[a, b, c, d]` defining the trapezoid.
/// - Returns: A membership value between 0.0 and 1.0.
fileprivate func interpretTrapezoidalMembership(x: Double, params: [Double]) -> Double {
    guard params.count == 4 else { return 0.0 }
    let (a, b, c, d) = (params[0], params[1], params[2], params[3])

    if x <= a || x >= d { return 0.0 }
    if x >= b && x <= c { return 1.0 }
    if x > a && x < b { return (x - a) / (b - a) }
    if x > c && x < d { return (d - x) / (d - c) }
    return 0.0
}

// MARK: - Recommendation ViewModel

@MainActor
class FuzzyRecommenderViewModel: ObservableObject {

    /// The final recommendation results for all fits.
    @Published var recommendations: Recommendations?
    
    /// True when the calculation is in progress.
    @Published var isLoading: Bool = false
    
    /// Holds any error message that occurs during calculation.
    @Published var errorMessage: String?
    
    private let ALL_FITS = ["tight", "slightly-tight", "regular", "slightly-loose", "loose"]
    
    /// The main entry point for calculating recommendations.
    /// This replaces the network call from `testView.swift`.
    ///
    /// - Parameters:
    ///   - userMeasurements: A `UserMeasurements` struct (from `CalculationRequest.swift`).
    ///   - clothesData: A `ClothesData` struct (from `CalculationRequest.swift`).
    public func calculateAllRecommendations(userMeasurements: UserMeasurements, clothesData: ClothesData) {
        
        self.isLoading = true
        self.errorMessage = nil
        self.recommendations = nil
        
        // --- 1. Get Config & Validate ---
        guard let clothesType = clothesData.item.keys.first,
              let config = RECOMMENDER_CONFIG[clothesType] else {
            self.errorMessage = "No configuration found for clothing type '\(clothesData.item.keys.first ?? "unknown")'."
            self.isLoading = false
            return
        }
        
        guard let sizeChartStructs = clothesData.item[clothesType], !sizeChartStructs.isEmpty else {
            self.errorMessage = "No size data found for '\(clothesType)'."
            self.isLoading = false
            return
        }

        // --- 2. Convert Inputs to formats used by the Python logic ---
        
        // Convert `UserMeasurements` struct to a simple dictionary
        let userMeasurementsDict = userMeasurementsToDictionary(userMeasurements)
        
        // Convert `[String: SizeMeasurements]` to `[String: [String: [Double]]]`
        let availableSizes = transformSizeChart(sizeChartStructs)
        
        // --- 3. Run Recommendation for All Fits (mirrors api.py) ---
        var allRecommendations: [String: FitRecommendation] = [:]

        for fit in ALL_FITS {
            let (bestSize, scores, partFits) = get_size_recommendation(
                user_measurements: userMeasurementsDict,
                clothes_db: availableSizes,
                config: config, // Pass the specific config
                desired_fit: fit
            )
            
            if let bestSize = bestSize, let bestScore = scores[bestSize] {
                let recommendation = FitRecommendation(
                    bestScore: bestScore,
                    bestSize: bestSize,
                    partFits: partFits
                )
                allRecommendations[fit] = recommendation
            } else {
                // Could not find a recommendation for this fit.
                // You could add error handling here if needed.
                print("Could not generate recommendation for fit: \(fit)")
            }
        }
        
        // --- 4. Assemble Final `Recommendations` Struct ---
        // We must ensure all keys exist for the `Recommendations` struct.
        // If a fit is missing, we create a placeholder.
        guard let loose = allRecommendations["loose"],
              let regular = allRecommendations["regular"],
              let slightlyLoose = allRecommendations["slightly-loose"],
              let slightlyTight = allRecommendations["slightly-tight"],
              let tight = allRecommendations["tight"]
        else {
            self.errorMessage = "Failed to calculate all required fit profiles. Some recommendations may be missing."
            // Even if some are missing, try to set what we have
            self.recommendations = Recommendations(
                loose: allRecommendations["loose"] ?? .empty,
                regular: allRecommendations["regular"] ?? .empty,
                slightlyLoose: allRecommendations["slightly-loose"] ?? .empty,
                slightlyTight: allRecommendations["slightly-tight"] ?? .empty,
                tight: allRecommendations["tight"] ?? .empty
            )
            self.isLoading = false
            return
        }
        
        self.recommendations = Recommendations(
            loose: loose,
            regular: regular,
            slightlyLoose: slightlyLoose,
            slightlyTight: slightlyTight,
            tight: tight
        )
        self.isLoading = false
    }
    
    // MARK: - Ported Python Logic (main.py)
    
    /// Port of `get_size_recommendation` from `main.py`.
    private func get_size_recommendation(
        user_measurements: [String: Double],
        clothes_db: [String: [String: [Double]]], // e.g., ["M": ["bust": [90.0, 90.0]]]
        config: ClothingConfig,
        desired_fit: String
    ) -> (best_size: String?, scores: [String: Double], part_fits: [String: String]) {
        
        var sizeScores: [String: Double] = [:]

        for (size, garmentRanges) in clothes_db {
            var partScores: [String: Double] = [:]

            for partConfig in config.relevantParts {
                let part = partConfig.partName
                
                guard let userMeas = user_measurements[part],
                      let garmentRange = garmentRanges[part], garmentRange.count == 2 else {
                    continue
                }
                
                let gMin = garmentRange[0]
                let gMax = garmentRange[1]

                let effectiveEase = _calculate_effective_ease(
                    user_meas: userMeas,
                    g_min: gMin,
                    g_max: gMax,
                    part_config: partConfig,
                    desired_fit: desired_fit
                )
                
                guard let desiredFitParams = partConfig.fitFunctions[desired_fit] else {
                    continue
                }
                
                let score = interpretTrapezoidalMembership(x: effectiveEase, params: desiredFitParams) * 100
                partScores[part] = score
            }

            if partScores.isEmpty {
                continue
            }

            let partWeights = config.partWeights
            var overallScore: Double = 0
            var totalWeight: Double = 0
            
            for (part, score) in partScores {
                if let weight = partWeights[part] {
                    overallScore += score * weight
                    totalWeight += weight
                }
            }
            
            sizeScores[size] = totalWeight > 0 ? (overallScore / totalWeight) : 0
        }

        if sizeScores.isEmpty {
            return (nil, [:], [:])
        }

        // Find the size with the best score
        let bestSize = sizeScores.max(by: { $0.value < $1.value })?.key
        
        var partFits: [String: String] = [:]
        if let bestSize = bestSize, let bestSizeGarmentRanges = clothes_db[bestSize] {
            partFits = _get_part_fit_details(
                user_measurements: user_measurements,
                best_size_garment_ranges: bestSizeGarmentRanges,
                config: config
            )
        }
        
        return (best_size: bestSize, scores: sizeScores, part_fits: partFits)
    }

    /// Port of `_calculate_effective_ease` from `main.py`.
    private func _calculate_effective_ease(
        user_meas: Double,
        g_min: Double,
        g_max: Double,
        part_config: RelevantPart,
        desired_fit: String
    ) -> Double {
        
        // Case 1: Fixed size garment (no range)
        if g_min == g_max {
            return g_min - user_meas
        }
        
        // Case 2: Ranged garment
        else {
            // User is significantly smaller than the garment's resting state -> Loose
            if user_meas < g_min {
                return g_min - user_meas
            }
            // User is larger than the garment's max stretch -> Too tight
            else if user_meas > g_max {
                return g_max - user_meas
            }
            // User is within the intended range of the garment
            else {
                guard let fitParams = part_config.fitFunctions[desired_fit], fitParams.count == 4,
                      let tightParams = part_config.fitFunctions["tight"], tightParams.count == 4 else {
                    // Fallback: return midpoint ease
                    return ((g_min + g_max) / 2) - user_meas
                }
                
                let idealEase = (fitParams[1] + fitParams[2]) / 2
                let tightEase = (tightParams[1] + tightParams[2]) / 2
                
                let midpoint = (g_min + g_max) / 2
                let maxDeviation = (g_max - g_min) / 2
                let deviation = abs(user_meas - midpoint)
                let deviationRatio = maxDeviation > 0 ? (deviation / maxDeviation) : 0
                
                let effectiveEase = idealEase + deviationRatio * (tightEase - idealEase)
                return effectiveEase
            }
        }
    }

    /// Port of `_get_part_fit_details` from `main.py`.
    private func _get_part_fit_details(
        user_measurements: [String: Double],
        best_size_garment_ranges: [String: [Double]],
        config: ClothingConfig
    ) -> [String: String] {
        
        var partDetails: [String: String] = [:]
        
        for partConfig in config.relevantParts {
            let part = partConfig.partName
            
            guard let userMeas = user_measurements[part],
                  let garmentRange = best_size_garment_ranges[part], garmentRange.count == 2 else {
                continue
            }
            
            let (g_min, g_max) = (garmentRange[0], garmentRange[1])
            
            let actualEase: Double
            if g_min == g_max {
                actualEase = g_min - userMeas // Fixed size
            } else { // Ranged garment
                if userMeas < g_min {
                    actualEase = g_min - userMeas
                } else {
                    // Use midpoint ease for ranged garment actual fit
                    let midpoint = (g_min + g_max) / 2
                    actualEase = midpoint - userMeas
                }
            }
            
            var bestFitName: String? = nil
            var maxMembership: Double = -1.0

            for (fitName, fitParams) in partConfig.fitFunctions {
                let membership = interpretTrapezoidalMembership(x: actualEase, params: fitParams)
                if membership > maxMembership {
                    maxMembership = membership
                    bestFitName = fitName
                }
            }
            
            if let bestFitName = bestFitName {
                partDetails[part] = bestFitName
            }
        }
        return partDetails
    }
    
    // MARK: - Data Transformation Helpers
    
    /// Converts the `UserMeasurements` struct to the dictionary format used by the logic.
    private func userMeasurementsToDictionary(_ measurements: UserMeasurements) -> [String: Double] {
        return [
            "bust": measurements.bust,
            "waist": measurements.waist,
            "hips": measurements.hips,
            "shoulder_width": measurements.shoulderWidth,
            "torso": measurements.torso,
            "arm_length": measurements.armLength
        ].compactMapValues { $0 } // Removes nil optionals if any (though struct has non-optionals)
    }
    
    /// Converts the `SizeMeasurements` structs into the dictionary format used by the logic.
    /// from: `["M": SizeMeasurements(torso: [70, 70], ...)]`
    /// to:   `["M": ["torso": [70, 70], ...]]`
    private func transformSizeChart(_ sizeChart: [String: SizeMeasurements]) -> [String: [String: [Double]]] {
        var transformedChart = [String: [String: [Double]]]()
        
        for (sizeName, measurements) in sizeChart {
            var partRanges = [String: [Double]]()
            
            partRanges["torso"] = measurements.torso
            partRanges["bust"] = measurements.bust
            
            if let armLength = measurements.armLength {
                partRanges["arm_length"] = armLength
            }
            if let waist = measurements.waist {
                partRanges["waist"] = waist
            }
            
            transformedChart[sizeName] = partRanges
        }
        
        return transformedChart
    }
}

// MARK: - Helper Extension

/// Adds a convenience empty state for FitRecommendation, useful for placeholders.
extension FitRecommendation {
    static var empty: FitRecommendation {
        FitRecommendation(bestScore: 0, bestSize: "N/A", partFits: [:])
    }
}
