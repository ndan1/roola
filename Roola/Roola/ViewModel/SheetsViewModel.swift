//
//  SheetViewModel.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 18/10/25.
//

import SwiftUI
import Combine

// MARK: - Fuzzy Logic Recommendation Engine & Configuration

enum FitPreference: String, CaseIterable, Comparable {
    case skinny = "Skinny"
    case slim = "Slim"
    case regular = "Regular"
    case loose = "Loose"
    
    private var sortOrder: Int {
        switch self {
        case .skinny: return 0
        case .slim: return 1
        case .regular: return 2
        case .loose: return 3
        }
    }
    
    static func < (lhs: FitPreference, rhs: FitPreference) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }
    
    func distance(to other: FitPreference) -> Int {
        return abs(self.sortOrder - other.sortOrder)
    }
}

fileprivate struct TrapezoidalFunction {
    let a, b, c, d: Double
}

fileprivate struct FitProfile {
    let fit: FitPreference
    let score: Double
}

fileprivate struct FuzzyEngine {
    
    static let fitFunctions: [FitPreference: TrapezoidalFunction] = [
        .skinny:  TrapezoidalFunction(a: -2, b: 0, c: 2, d: 4),
        .slim:    TrapezoidalFunction(a: 2, b: 4, c: 7, d: 10),
        .regular: TrapezoidalFunction(a: 7, b: 10, c: 14, d: 17),
        .loose:   TrapezoidalFunction(a: 14, b: 17, c: 22, d: 25)
    ]
    
    static func interpretMembership(value: Double, in function: TrapezoidalFunction) -> Double {
        let (a, b, c, d) = (function.a, function.b, function.c, function.d)
        if value <= a || value >= d { return 0.0 }
        if value >= b && value <= c { return 1.0 }
        if value > a && value < b { return (value - a) / (b - a) }
        if value > c && value < d { return (d - value) / (d - c) }
        return 0.0
    }
    
    static func findBestFitProfile(for ease: Double) -> FitProfile {
        var bestFit: FitPreference = .regular
        var highestScore: Double = 0.0
        
        for (fit, function) in fitFunctions {
            let score = interpretMembership(value: ease, in: function)
            if score > highestScore {
                highestScore = score
                bestFit = fit
            }
        }
        return FitProfile(fit: bestFit, score: highestScore * 100)
    }
}

fileprivate struct RecommenderConfig {
    let relevantParts: [String]
    let partWeights: [String: Double]
}

fileprivate let RECOMMENDER_CONFIG: [String: RecommenderConfig] = [
    "T-Shirt": RecommenderConfig(relevantParts: ["bust", "torso"], partWeights: ["bust": 0.7, "torso": 0.3]),
]

@MainActor
class SheetViewModel: ObservableObject {
    @Published var recommendedSize: String = "Calculating..."
    @Published var selectedSize: String = ""
    @Published var desiredFit: FitPreference = .regular
    
    @Published var selectedSizeFitCategory: FitPreference? = nil
    
    private var clothes: Clothes?
    private var user: User?
    private var cancellables = Set<AnyCancellable>()

    init() {
        $desiredFit
            .dropFirst()
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.calculateBestSizeWithFuzzyLogic()
            }
            .store(in: &cancellables)
        
        $selectedSize
            .dropFirst()
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateSelectedSizeFitCategory()
            }
            .store(in: &cancellables)
    }
    
    func setup(clothes: Clothes, user: User?) {
        self.clothes = clothes
        self.user = user
        calculateBestSizeWithFuzzyLogic()
    }
    
    private func calculateBestSizeWithFuzzyLogic() {
        guard let user = self.user, let clothes = self.clothes else {
            recommendedSize = "N/A"
            return
        }
        
        guard let config = RECOMMENDER_CONFIG[clothes.product_type] ?? RECOMMENDER_CONFIG["T-Shirt"] else {
            recommendedSize = "Unsupported"
            return
        }
        
        var sizeProfiles: [String: FitProfile] = [:]

        for sizeVariant in clothes.product_sizes {
            var partEaseValues: [String: Double] = [:]
            
            for part in config.relevantParts {
                let userMeasurement: Double?
                let garmentMeasurement: Double?
                
                switch part {
                case "bust":
                    userMeasurement = Double(user.bust)
                    garmentMeasurement = Double((sizeVariant.clothes_bust_min + sizeVariant.clothes_bust_max) / 2)
                case "torso":
                    userMeasurement = Double(user.torso)
                    garmentMeasurement = Double((sizeVariant.clothes_torso_min + sizeVariant.clothes_torso_max) / 2)
                case "waist":
                    userMeasurement = Double(user.waist)
                    if let min = sizeVariant.clothes_waist_min, let max = sizeVariant.clothes_waist_max {
                        garmentMeasurement = Double(min + max) / 2.0
                    } else {
                        garmentMeasurement = nil
                    }
                default:
                    userMeasurement = nil; garmentMeasurement = nil
                }
                
                if let userM = userMeasurement, let garmentM = garmentMeasurement {
                    partEaseValues[part] = garmentM - userM
                }
            }
            
            var totalWeightedEase: Double = 0
            var totalWeight: Double = 0
            for (part, ease) in partEaseValues {
                if let weight = config.partWeights[part] {
                    totalWeightedEase += ease * weight
                    totalWeight += weight
                }
            }
            
            if totalWeight > 0 {
                let averageEase = totalWeightedEase / totalWeight
                sizeProfiles[sizeVariant.size_name] = FuzzyEngine.findBestFitProfile(for: averageEase)
            }
        }
    
        var bestMatch: (name: String, profile: FitProfile)?
        var minDistance = Int.max

        for (sizeName, profile) in sizeProfiles {
            let distance = desiredFit.distance(to: profile.fit)
            
            if distance < minDistance {
                minDistance = distance
                bestMatch = (name: sizeName, profile: profile)
            } else if distance == minDistance {
                if let currentBest = bestMatch, profile.score > currentBest.profile.score {
                    bestMatch = (name: sizeName, profile: profile)
                }
            }
        }
        
        if let bestSize = bestMatch {
            recommendedSize = bestSize.name
            if selectedSize.isEmpty { selectedSize = bestSize.name }
        } else {
            recommendedSize = "No Fit"
            if selectedSize.isEmpty { selectedSize = clothes.product_sizes.map { $0.size_name }.sorted().first ?? "" }
        }
        
        updateSelectedSizeFitCategory()
    }
    
    private func updateSelectedSizeFitCategory() {
        guard let user = user,
              let clothes = clothes,
              let config = RECOMMENDER_CONFIG[clothes.product_type] ?? RECOMMENDER_CONFIG["T-Shirt"],
              let sizeVariant = clothes.product_sizes.first(where: { $0.size_name == selectedSize })
        else {
            self.selectedSizeFitCategory = nil
            return
        }
        
        var partEaseValues: [String: Double] = [:]
        for part in config.relevantParts {
            let userMeasurement: Double?
            let garmentMeasurement: Double?
            switch part {
            case "bust":
                userMeasurement = Double(user.bust); garmentMeasurement = Double(sizeVariant.clothes_bust_min + sizeVariant.clothes_bust_max) / 2.0
            case "torso":
                userMeasurement = Double(user.torso); garmentMeasurement = Double(sizeVariant.clothes_torso_min + sizeVariant.clothes_torso_max) / 2.0
            default:
                userMeasurement = nil; garmentMeasurement = nil
            }
            
            if let userM = userMeasurement, let garmentM = garmentMeasurement {
                partEaseValues[part] = garmentM - userM
            }
        }

        var totalWeightedEase: Double = 0
        var totalWeight: Double = 0
        for (part, ease) in partEaseValues {
            if let weight = config.partWeights[part] {
                totalWeightedEase += ease * weight
                totalWeight += weight
            }
        }
        
        if totalWeight > 0 {
            let averageEase = totalWeightedEase / totalWeight
            self.selectedSizeFitCategory = FuzzyEngine.findBestFitProfile(for: averageEase).fit
        } else {
            self.selectedSizeFitCategory = nil
        }
    }
}
