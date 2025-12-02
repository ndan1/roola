//
//  MeasurementHistory.swift
//  Roola
//
//  Created by System on 11/11/25.
//

import Foundation
import SwiftData

@Model
public class MeasurementHistory: Identifiable {
    public var id: UUID
    var productName: String
    var brandName: String
    var productLink: String?
    var clothingType: String
    var selectedFitPreference: String
    var createdAt: Date
    
    // Saved recommendations (as JSON string for simplicity)
    var recommendationsJSON: String
    
    // User measurements at time of calculation
    var userBust: Double
    var userWaist: Double
    var userTorso: Double
    var userArmLength: Double
    
    init(
        productName: String,
        brandName: String,
        productLink: String? = nil,
        clothingType: String,
        selectedFitPreference: String,
        recommendationsJSON: String,
        userBust: Double,
        userWaist: Double,
        userTorso: Double,
        userArmLength: Double
    ) {
        self.id = UUID()
        self.productName = productName
        self.brandName = brandName
        self.productLink = productLink
        self.clothingType = clothingType
        self.selectedFitPreference = selectedFitPreference
        self.createdAt = Date()
        self.recommendationsJSON = recommendationsJSON
        self.userBust = userBust
        self.userWaist = userWaist
        self.userTorso = userTorso
        self.userArmLength = userArmLength
    }
    
    // Computed property to extract best size from recommendations JSON
    var bestSize: String? {
        guard let jsonData = recommendationsJSON.data(using: .utf8) else {
            print("❌ [bestSize] Failed to convert recommendationsJSON to Data")
            return nil
        }
        
        do {
            // Decode as ServerResponse (which has "recommendations" wrapper)
            let serverResponse = try JSONDecoder().decode(ServerResponse.self, from: jsonData)
            let recommendations = serverResponse.recommendations
            print("✅ [bestSize] Successfully decoded recommendations")
            
            // Get the recommendation based on selected fit preference
            let fitRecommendation: FitRecommendation
            print("🔍 [bestSize] selectedFitPreference: '\(selectedFitPreference)'")
            
            switch selectedFitPreference.lowercased() {
            case "loose":
                fitRecommendation = recommendations.loose
            case "regular", "standard":
                fitRecommendation = recommendations.regular
            case "slightly-loose", "slightly loose", "relaxed":
                fitRecommendation = recommendations.slightlyLoose
            case "slightly-tight", "slightly tight", "slim":
                fitRecommendation = recommendations.slightlyTight
            case "tight":
                fitRecommendation = recommendations.tight
            default:
                print("⚠️ [bestSize] Unknown fit preference '\(selectedFitPreference)', using regular")
                fitRecommendation = recommendations.regular
            }
            
            print("✅ [bestSize] Best size: '\(fitRecommendation.bestSize)'")
            return fitRecommendation.bestSize
        } catch {
            print("❌ [bestSize] Error decoding recommendations JSON: \(error)")
            print("📄 [bestSize] JSON preview: \(String(recommendationsJSON.prefix(200)))")
            return nil
        }
    }
}
