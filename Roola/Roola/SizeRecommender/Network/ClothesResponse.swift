//
//  ClothesResponse.swift
//  Roola
//
//  Created by Lin Dan Christiano on 21/10/25.
//

import Foundation

struct ClothesResponse: Codable {
    let product_id: String
    let product_name: String
    let product_type: String
    let product_sizes: [VariantResponse]
}

struct VariantResponse: Codable, Hashable {
    let size_name: String
    let clothes_torso_min: Double?
    let clothes_torso_max: Double?
    let clothes_bust_min: Double?
    let clothes_bust_max: Double?
    let clothes_arm_length_min: Double?
    let clothes_arm_length_max: Double?
    let clothes_waist_min: Double?
    let clothes_waist_max: Double?
    let clothes_hips_min: Double?
    let clothes_hips_max: Double?
    let clothes_inbeam_min: Double?
    let clothes_inbeam_max: Double?
    let error_tolerance: Double?
}
