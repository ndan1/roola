//
//  OCRModel.swift
//  Roola
//
//  Created by Lin Dan Christiano on 04/11/25.
//

import Foundation

// MARK: - Structs for Decoding AI JSON
// These structs match the new JSON format you expect from the AI
struct OCRResponse: Codable {
    let sizes: [SizeDetail]
}

struct SizeDetail: Codable {
    let size: String
    let clothesTorsoMin: Double
    let clothesTorsoMax: Double
    let clothesBustMin: Double
    let clothesBustMax: Double
    let clothesArmMin: Double?
    let clothesArmMax: Double?
    let clothesWaistMin: Double?
    let clothesWaistMax: Double?

    enum CodingKeys: String, CodingKey {
        case size
        case clothesTorsoMin = "clothes_torso_min"
        case clothesTorsoMax = "clothes_torso_max"
        case clothesBustMin = "clothes_bust_min"
        case clothesBustMax = "clothes_bust_max"
        case clothesArmMin = "clothes_arm_min"
        case clothesArmMax = "clothes_arm_max"
        case clothesWaistMin = "clothes_waist_min"
        case clothesWaistMax = "clothes_waist_max"
    }
}
