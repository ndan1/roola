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
    var shopName: String
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
        shopName: String,
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
        self.shopName = shopName
        self.clothingType = clothingType
        self.selectedFitPreference = selectedFitPreference
        self.createdAt = Date()
        self.recommendationsJSON = recommendationsJSON
        self.userBust = userBust
        self.userWaist = userWaist
        self.userTorso = userTorso
        self.userArmLength = userArmLength
    }
}
