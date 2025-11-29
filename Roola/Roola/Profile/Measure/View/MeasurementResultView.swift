//
//  MeasurementResultView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 09/11/25.
//

import SwiftUI
import SwiftData

struct MeasurementResultView: View {
    
    @StateObject private var viewModel: MeasurementResultViewModel
    @State private var showMeasureGuide = false
    
    // MARK: - Init
    init(data: MeasurementData?, onDone: @escaping () -> Void, onBack: @escaping () -> Void, onInfo: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: MeasurementResultViewModel(
            data: data,
            onDone: onDone,
            onBack: onBack,
            onInfo: onInfo
        ))
    }
    
    // NEW: Helper to dismiss keyboard
    private func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoolaHeader(
                title: "Your measurement",
                onInfo: {
                    showMeasureGuide.toggle()
                },
                isLargeTitle: true
            )

            if viewModel.data != nil {
                // NEW: Wrapped in ScrollView to prevent overflow with new fields
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // NEW: Body Size Card (Height & Weight)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Body size")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(Color(AppColors.grayScale400))
                            
                            BodySizeCard(
                                height: $viewModel.height,
                                weight: $viewModel.weight,
                                isHeightError: viewModel.isHeightError,
                                isWeightError: viewModel.isWeightError,
                                hasAnyError: viewModel.hasError,
                                isEditing: true // Allow editing immediately
                            )
                        }
                        
                        // Existing Measurements Card
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Body measurements")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(Color(AppColors.grayScale400))
                                
                            MeasurementsCard(
                                chest: $viewModel.chest,
                                waist: $viewModel.waist,
                                armLength: $viewModel.armLength,
                                torsoLength: $viewModel.torsoLength,
                                
                                isChestError: viewModel.isChestError,
                                isWaistError: viewModel.isWaistError,
                                isArmLengthError: viewModel.isArmLengthError,
                                isTorsoLengthError: viewModel.isTorsoLengthError,
                                hasAnyError: viewModel.hasError,
                                isEditing: true
                            )
                        }
                        
                        // Validation Errors
                        VStack(alignment: .leading, spacing: 4) {
                            if viewModel.hasEmptyError {
                                Text("Please fill in all fields")
                                    .font(.body15Regular)
                                    .foregroundColor(AppColors.errorRed)
                            }
                            
                            if viewModel.isOver250Error {
                                Text("Number must be below 250 cm")
                                    .font(.body15Regular)
                                    .foregroundColor(AppColors.errorRed)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        
                        Spacer(minLength: 20)
                        
                        // Buttons
                        VStack (alignment: .center, spacing: 20){
                            RoolaButton(
                                buttonTitle: "Save",
                                buttonColor: AppColors.primaryPurple,
                                action: viewModel.saveTapped
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.85) // Slight width adjustment to match others
                            
                            RoolaButton(
                                buttonTitle: "Retake",
                                buttonColor: AppColors.primaryWhite,
                                action: viewModel.retakeTapped
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.85)
                        }
                        .frame(maxWidth: .infinity, alignment: .init(horizontal: .center, vertical: .bottom))
                        .padding(.bottom, 20)
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            } else {
                // Error State
                VStack(spacing: 10) {
                    Spacer()
                    Text("Measurement Data Not Found")
                        .font(.title2)
                    Text("Please try the measurement again.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(FirstGradientBackground().ignoresSafeArea())
        // NEW: Tap gesture to dismiss keyboard
        .onTapGesture {
            endEditing()
        }
        .sheet(isPresented: $showMeasureGuide) {
            MeasureGuideModal()
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
        }
    }
}

// The Preview remains unchanged and works perfectly.
#Preview {
    MeasurementResultView(
        data: MeasurementData(
            armsLength: 49.21,
            chestCircumference: 92,
            height: 169,
            torsoLength: 54,
            waistCircumference: 82
        ),
        onDone: {
            print("Done tapped")
        },
        onBack: {
            print("Test")
        },
        onInfo: {
            print("Modal")
        }
    )
}
