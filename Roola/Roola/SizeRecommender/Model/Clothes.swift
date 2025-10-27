//
//  data.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 18/10/25.
//

import Foundation
import SwiftData

@Model
public class Clothes {
    var product_id : String
    var product_name : String
    var product_type: String
    var product_sizes: [Variant]
    
    init(product_id: String, product_name: String, product_type: String, product_sizes: [Variant]) {
        self.product_id = product_id
        self.product_name = product_name
        self.product_type = product_type
        self.product_sizes = product_sizes
    }
}

@Model
public class Variant {
    var size_name : String
    var clothes_torso_min : Int
    var clothes_torso_max : Int
    var clothes_bust_min : Int
    var clothes_bust_max : Int
    var clothes_arm_length_min : Int?
    var clothes_arm_length_max : Int?
    var clothes_waist_min : Int?
    var clothes_waist_max : Int?
    var error_tolerance : Int?
    
    init(size_name: String, clothes_torso_min: Int, clothes_torso_max: Int, clothes_bust_min: Int, clothes_bust_max: Int, clothes_arm_length_min: Int? = nil, clothes_arm_length_max: Int? = nil, clothes_waist_min: Int? = nil, clothes_waist_max: Int? = nil, error_tolerance: Int? = nil) {
        self.size_name = size_name
        self.clothes_torso_min = clothes_torso_min
        self.clothes_torso_max = clothes_torso_max
        self.clothes_bust_min = clothes_bust_min
        self.clothes_bust_max = clothes_bust_max
        self.clothes_arm_length_min = clothes_arm_length_min
        self.clothes_arm_length_max = clothes_arm_length_max
        self.clothes_waist_min = clothes_waist_min
        self.clothes_waist_max = clothes_waist_max
        self.error_tolerance = error_tolerance
    }
}
