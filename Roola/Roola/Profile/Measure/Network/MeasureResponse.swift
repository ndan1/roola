//
//  MeasureModel.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 09/11/25.
//

import Foundation

// MARK: - API Response Structs
// These structs are built to parse the exact JSON response you provided.

/// The top-level response object from the API
struct MeasurementResponse: Codable {
    let id: String
    let status: String
    let output: MeasurementOutput
}

/// The "output" object containing the status and measurement data
struct MeasurementOutput: Codable {
    let status: String
    let measurements: MeasurementData
}

/// The "measurements" object with the final values
struct MeasurementData: Codable {
    let armsLength: Double
    let chestCircumference: Double
    let height: Double
    let torsoLength: Double
    let waistCircumference: Double

    // Using CodingKeys to map snake_case JSON to camelCase Swift properties
    enum CodingKeys: String, CodingKey {
        case armsLength = "arms_length"
        case chestCircumference = "chest_circumference"
        case height
        case torsoLength = "torso_length"
        case waistCircumference = "waist_circumference"
    }
}
