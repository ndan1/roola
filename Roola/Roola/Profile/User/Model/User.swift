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
    var bust: Int
    var waist: Int
    var torso: Int
    var arms_length: Int
    
    init(height: Int = 0, bust: Int = 0, waist: Int, torso: Int = 0, arms_length: Int = 0) {
        self.height = height
        self.bust = bust
        self.waist = waist
        self.torso = torso
        self.arms_length = arms_length
    }
}
