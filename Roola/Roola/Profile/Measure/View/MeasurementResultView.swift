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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoolaHeader(
                title: "Your measurement",
                onInfo: {
                    showMeasureGuide.toggle()
                },
                isLargeTitle: true
            )

            Group {
                if viewModel.data != nil {
                    VStack(spacing: 30) {
                        Group {
                            MeasurementsCard(
                                chest: $viewModel.chest,
                                waist: $viewModel.waist,
                                armLength: $viewModel.armLength,
                                torsoLength: $viewModel.torsoLength,
                                
                                isChestError: viewModel.isChestError,
                                isWaistError: viewModel.isWaistError,
                                isArmLengthError: viewModel.isArmLengthError,
                                isTorsoLengthError: viewModel.isTorsoLengthError,
                                hasAnyError: viewModel.hasError
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                // Read error states from VM
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
                        }
                        
                        Spacer()
                        
                        VStack{
                            RoolaButton(
                                buttonTitle: "Save",
                                buttonColor: AppColors.primaryPurple,
                                action: viewModel.saveTapped
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.8)
                            
                            RoolaButton(
                                buttonTitle: "Retake",
                                buttonColor: AppColors.primaryWhite,
                                action: viewModel.retakeTapped
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.8)
                        }
                        .padding(.bottom, UIScreen.main.bounds.height * 0.05)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top,10)
                } else {
                    VStack(spacing: 10) {
                        Text("Measurement Data Not Found")
                            .font(.title2)
                        Text("Please try the measurement again.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .background(FirstGradientBackground())
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
