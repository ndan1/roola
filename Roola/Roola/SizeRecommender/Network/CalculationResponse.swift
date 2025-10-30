//
//  CalculationResponse.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 24/10/25.
//

import Foundation

struct ServerResponse: Codable {
    let recommendations: Recommendations
}

struct Recommendations: Codable {
    let loose: FitRecommendation
    let regular: FitRecommendation
    let slightlyLoose: FitRecommendation
    let slightlyTight: FitRecommendation
    let tight: FitRecommendation
    
    enum CodingKeys: String, CodingKey {
        case loose, regular
        case slightlyLoose = "slightly-loose"
        case slightlyTight = "slightly-tight"
        case tight
    }
}

struct FitRecommendation: Codable {
    let bestScore: Double
    let bestSize: String
    let partFits: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case bestScore = "best_score"
        case bestSize = "best_size"
        case partFits = "part_fits"
    }
}
