//
//  APIResultResponse.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 24/10/25.
//

//import Foundation
//
//struct APIResponse: Codable {
//    let recommendations: [String: FitRecommendation]
//}
//
//struct FitRecommendation: Codable {
//    let bestSize: String?
//    let bestScore: Double?
//    let partFits: [String: String]?
//    let allSizeScores: [String: Double]?
//
//    // --- Error Case Properties ---
//    // Based on your api.py code, these fields appear on failure
//    let error: String?
//
//    let details: [String: String]?
//
//    enum CodingKeys: String, CodingKey {
//        case bestSize = "best_size"
//        case bestScore = "best_score"
//        case partFits = "part_fits"
//        case allSizeScores = "all_size_scores"
//        case error
//        case details
//    }
//}
