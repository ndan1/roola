//
//  data.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 18/10/25.
//

import Foundation
import SwiftData

@Model
public class User {
    var height: Int
    var weight: Int
    var age: Int
    
    var bust: Int
    var waist: Int
    var hips: Int
    var shoulder_width: Int
    var torso: Int
    var arms_length: Int
    
    init(height: Int = 0, weight: Int = 0, age: Int = 0, bust: Int = 0, waist: Int = 0, hips: Int = 0, shoulder_width: Int = 0, torso: Int = 0, arms_length: Int = 0) {
        self.height = height
        self.weight = weight
        self.age = age
        self.bust = bust
        self.waist = waist
        self.hips = hips
        self.shoulder_width = shoulder_width
        self.torso = torso
        self.arms_length = arms_length
    }
}
