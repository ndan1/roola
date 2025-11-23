//
//  MeasurementCard.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 11/11/25.
//  Created by Georgius Kenny Gunawan on 10/11/25.

import SwiftUI

struct YourMeasurementView: View {
    
    @State private var chest: Int? = nil
    @State private var waist: Int? = nil
    @State private var armLength: Int? = nil
    @State private var torsoLength: Int? = nil
    @State private var height: Int? = nil
    @State private var weight: Int? = nil
    
    @State private var hasAttemptedSave: Bool = false
    

    private var isChestError: Bool {
        // Don't show any error until save is tapped
        if !hasAttemptedSave { return false }
        // Now, check for either error
        return (chest ?? 0) > 250 || chest == nil
    }
    
    private var isWaistError: Bool {
        if !hasAttemptedSave { return false }
        return (waist ?? 0) > 250 || waist == nil
    }
    
    private var isArmLengthError: Bool {
        if !hasAttemptedSave { return false }
        return (armLength ?? 0) > 250 || armLength == nil
    }
    
    private var isTorsoLengthError: Bool {
        if !hasAttemptedSave { return false }
        return (torsoLength ?? 0) > 250 || torsoLength == nil
    }
    
    private var isHeightError: Bool {
        if !hasAttemptedSave { return false }
        return (height ?? 0) > 250 || height == nil
    }
    
    private var isWeightError: Bool {
        if !hasAttemptedSave { return false }
        return (weight ?? 0) > 250 || weight == nil
    }
    
    // This property now only becomes true *after* save is attempted
    private var hasError: Bool {
        isChestError || isWaistError || isArmLengthError || isTorsoLengthError || isHeightError || isWeightError
    }
    
    // --- 2. UPDATED ERROR MESSAGE LOGIC ---
    // These also wait for 'hasAttemptedSave'
    
    private var isOver250Error: Bool {
        if !hasAttemptedSave { return false }
        return (chest ?? 0) > 250 || (waist ?? 0) > 250 || (armLength ?? 0) > 250 || (torsoLength ?? 0) > 250 || (height ?? 0) > 250 || (weight ?? 0) > 250
    }
    
    private var hasEmptyError: Bool {
        if !hasAttemptedSave { return false }
        return chest == nil || waist == nil || armLength == nil || torsoLength == nil || height == nil || weight == nil
    }

    var body: some View {
        ZStack{
            FirstGradientBackground()
            
            VStack(spacing: 0){
                
                RoolaHeader(title: "") {
                    print("test")
                } onInfo: {
                    print("test")
                }

                Group{
                    BodySizeCard(height: $height,
                                 weight: $weight,
                                 isHeightError: isHeightError,
                                 isWeightError: isWeightError,
                                 hasAnyError: hasError
                    )
                    
                    MeasurementsCard(
                        chest: $chest,
                        waist: $waist,
                        armLength: $armLength,
                        torsoLength: $torsoLength,
                        isChestError: isChestError,
                        isWaistError: isWaistError,
                        isArmLengthError: isArmLengthError,
                        isTorsoLengthError: isTorsoLengthError,
                        hasAnyError: hasError
                    )
                    
                    // --- 3. STACKED ERROR MESSAGES ---
                    // By removing 'else', both messages can appear.
                    VStack(alignment: .leading, spacing: 4) {
                        if hasEmptyError {
                            Text("Please fill in all fields")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                        
                        if isOver250Error {
                            Text("Number must be below 250 cm")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8) // Give the error block some space
                }
                
                Spacer() // Pushes the button to the bottom
                
                // 4. Save Button
                RoolaButton(
                    buttonTitle: "Save",
                    buttonColor: AppColors.primaryPurple,
                    action: {
                        // This single line will trigger all the error checks
                        hasAttemptedSave = true
                        
                        if !hasError {
                            print("Data saved! Chest: \(chest ?? 0), Waist: \(waist ?? 0), ...")
                        }
                    }
                )
                .padding(.bottom, UIScreen.main.bounds.height * 0.088)
                
            }
            .padding(.horizontal, 31)
        }
    }
}

// ... Your MeasurementsCard, MeasurementRow, TopMeasurementRow,
// ... and BottomMeasurementRow structs would be here ...

struct BodySizeCard: View {
    
    @Binding var height: Int?
    @Binding var weight: Int?
    
    var isHeightError: Bool
    var isWeightError: Bool
    var hasAnyError: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            
            TopMeasurementRow(label: "Height", unit: "cm", value: $height, isError: isHeightError)
            
            BottomMeasurementRow(label: "Weight", unit: "cm", value: $weight, isError: isWeightError)
        }
    }
}


struct MeasurementsCard: View {
    
    @Binding var chest: Int?
    @Binding var waist: Int?
    @Binding var armLength: Int?
    @Binding var torsoLength: Int?
    
    var isChestError: Bool
    var isWaistError: Bool
    var isArmLengthError: Bool
    var isTorsoLengthError: Bool
    var hasAnyError: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            
            TopMeasurementRow(label: "Chest", unit:"cm", value: $chest, isError: isChestError)
            
            
            
            MeasurementRow(label: "Waist", unit:"cm", value: $waist, isError: isWaistError)
            
            
            
            MeasurementRow(label: "Arm length", unit:"cm", value: $armLength, isError: isArmLengthError)
            
            
            
            BottomMeasurementRow(label: "Torso length", unit:"cm", value: $torsoLength, isError: isTorsoLengthError)
        }
    }
}


#Preview {
    YourMeasurementView()
}
