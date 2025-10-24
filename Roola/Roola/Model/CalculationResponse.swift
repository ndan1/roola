//
//  CalculationResponse.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 24/10/25.
//

import Foundation

struct CalculationResponse: Codable {
    let userMeasurements: UserMeasurementsResponse
    let clothesData: [String: [String: [Double]]]

    enum CodingKeys: String, CodingKey {
        case userMeasurements = "user_measurements"
        case clothesData = "clothes_data"
    }
}

struct UserMeasurementsResponse: Codable {
    let bust: Double
    let waist: Double
    let hips: Double
    let shoulder_width: Double
    let torso: Double
    let arm_length: Double
}

//{
//  "user_measurements": {
//    "bust": 91.0,
//    "waist": 73.0,
//    "hips": 100.0,
//    "shoulder_width": 37.0,
//    "torso": 58.0,
//    "arm_length": 55.0
//  },
//  "clothes_data": {
//    "blouse": {
//      "XS": {"torso": [63.0, 63.0], "bust": [94.0, 94.0], "arm_length": [59.0, 59.0]}
//    }
//  }
//}
