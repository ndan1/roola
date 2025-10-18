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
    
    init(height: Int, weight: Int, age: Int, bust: Int, waist: Int, hips: Int, shoulder_width: Int, torso: Int, arms_length: Int) {
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
    
    init() {
        self.height = 158
        self.weight = 52
        self.age = 24
        self.bust = 84
        self.waist = 66
        self.hips = 89
        self.shoulder_width = 39
        self.torso = 59
        self.arms_length = 60
    }
}
