//
//  CalculationResponse.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 24/10/25.
//

import Foundation

struct ServerResponse: Codable, Equatable {
    let recommendations: Recommendations
}

struct Recommendations: Codable, Equatable {
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
