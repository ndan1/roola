//
//  DataSeeder.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 18/10/25.
//


import Foundation
import SwiftData

enum DataSeeder {
    static func seed(context: ModelContext) {
        // --- SEED CLOTHES ---
        // Check if Clothes data already exists to avoid duplication
        let clothesDescriptor = FetchDescriptor<Clothes>()
        let existingClothes = try? context.fetch(clothesDescriptor)
        
        if existingClothes?.isEmpty ?? true {
            print("Seeding Clothes data...")
            
            // Sample Data 1: T-Shirt
            let tShirtVariants = [
                Variant(size_name: "S", clothes_torso_min: 58, clothes_torso_max: 58, clothes_bust_min: 86, clothes_bust_max: 86),
                Variant(size_name: "M", clothes_torso_min: 60, clothes_torso_max: 60, clothes_bust_min: 92, clothes_bust_max: 92),
                Variant(size_name: "L", clothes_torso_min: 62, clothes_torso_max: 62, clothes_bust_min: 98, clothes_bust_max: 98),
                Variant(size_name: "XL", clothes_torso_min: 64, clothes_torso_max: 64, clothes_bust_min: 104, clothes_bust_max: 104),
                Variant(size_name: "XXL", clothes_torso_min: 66, clothes_torso_max: 66, clothes_bust_min: 110, clothes_bust_max: 110)
            ]
            let classicTShirt = Clothes(product_id: "TS001", product_name: "Classic T-Shirt", product_type: "Top", product_sizes: tShirtVariants)
    
            context.insert(classicTShirt)
            
            print("Clothes data seeding complete.")
        } else {
            print("Clothes data already exists.")
        }
        
        // --- SEED USER ---
        // Check if a User object already exists
        let userDescriptor = FetchDescriptor<User>()
        let existingUsers = try? context.fetch(userDescriptor)
        
        if existingUsers?.isEmpty ?? true {
            print("Seeding default User data...")
            // Your User model has a convenient default initializer
            let defaultUser = User()
            context.insert(defaultUser)
            print("Default User seeding complete.")
        } else {
            print("User data already exists.")
        }
    }
}
