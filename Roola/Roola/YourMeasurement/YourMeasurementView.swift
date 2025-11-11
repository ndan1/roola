//
//  YourMeasurementView.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 10/11/25.
//

import SwiftUI

struct YourMeasurementView: View {
    
    @State private var isShowingInfoModal: Bool = false
    
    // ... (all your other @State variables)
    @State private var chest: Int? = nil
    @State private var waist: Int? = nil
    @State private var armLength: Int? = nil
    @State private var torsoLength: Int? = nil
    @State private var hasAttemptedSave: Bool = false
    
    // ... (all your computed properties like isChestError, hasError, etc.)
    private var isChestError: Bool {
        if !hasAttemptedSave { return false }
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
    
    private var hasError: Bool {
        isChestError || isWaistError || isArmLengthError || isTorsoLengthError
    }
    
    private var isOver250Error: Bool {
        if !hasAttemptedSave { return false }
        return (chest ?? 0) > 250 || (waist ?? 0) > 250 || (armLength ?? 0) > 250 || (torsoLength ?? 0) > 250
    }
    
    private var hasEmptyError: Bool {
        if !hasAttemptedSave { return false }
        return chest == nil || waist == nil || armLength == nil || torsoLength == nil
    }
    
    var body: some View {
        ZStack{
            // ... (your background and main VStack)
            FirstGradientBackground()
            
            VStack(spacing: 0){
                
                YourBodyMeasureNavbar(title: "Your Measurement") {
                    print("Back Tapped")
                } infoAction: {
                    isShowingInfoModal = true // This is correct
                }
                .padding(.top, UIScreen.main.bounds.height * 0.06)
                .padding(.bottom, 31)
                
                VStack{
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
                    
                    // --- Error Messages ---
                    VStack(alignment: .leading, spacing: 4) {
                        if hasEmptyError {
                            Text("• Please fill in all fields")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                        
                        if isOver250Error {
                            Text("• Number must be below 250 cm")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // ... (your RoolaButton)
                    RoolaButton(
                        buttonTitle: "Save",
                        buttonColor: AppColors.primaryPurple,
                        action: {
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
        .sheet(isPresented: $isShowingInfoModal) {
            MeasureGuideModal()
            // --- ADD THIS LINE ---
                .presentationDetents([.fraction(0.7), .fraction(0.8)])
        }
    }
}

// ... Your MeasurementsCard, MeasurementRow, TopMeasurementRow,
// ... and BottomMeasurementRow structs would be here ...


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
            
            TopMeasurementRow(label: "Chest", value: $chest, isError: isChestError)
            
            
            
            MeasurementRow(label: "Waist", value: $waist, isError: isWaistError)
            
            
            
            MeasurementRow(label: "Arm length", value: $armLength, isError: isArmLengthError)
            
            
            
            BottomMeasurementRow(label: "Torso length", value: $torsoLength, isError: isTorsoLengthError)
        }
    }
}


#Preview {
    YourMeasurementView()
}

