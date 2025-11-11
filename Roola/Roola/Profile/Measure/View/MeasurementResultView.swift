//
//  MeasurementResultView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 09/11/25.
//

import SwiftUI
import SwiftData

struct MeasurementResultView: View {
    let data: MeasurementData?
    
    @State private var chest: Int?
    @State private var waist: Int?
    @State private var armLength: Int?
    @State private var torsoLength: Int?
    
    @State private var hasAttemptedSave: Bool = false
    
    var onDone: () -> Void
    var onBack: () -> Void
    var onInfo: () -> Void
    
    // MARK: - Init temporary state
    init(data: MeasurementData?, onDone: @escaping () -> Void, onBack: @escaping () -> Void, onInfo: @escaping () -> Void) {
        self.data = data
        self.onDone = onDone
        self.onBack = onBack
        self.onInfo = onInfo
        
        // We’ll initialize _chest, _waist, etc. in .onAppear instead of here
        // since @State can’t be initialized directly from init with optional
    }
    
    // MARK: - Error Checks
    private var isChestError: Bool {
        hasAttemptedSave && ((chest ?? 0) > 250 || chest == nil)
    }
    
    private var isWaistError: Bool {
        hasAttemptedSave && ((waist ?? 0) > 250 || waist == nil)
    }
    
    private var isArmLengthError: Bool {
        hasAttemptedSave && ((armLength ?? 0) > 250 || armLength == nil)
    }
    
    private var isTorsoLengthError: Bool {
        hasAttemptedSave && ((torsoLength ?? 0) > 250 || torsoLength == nil)
    }
    
    private var hasError: Bool {
        isChestError || isWaistError || isArmLengthError || isTorsoLengthError
    }
    
    private var isOver250Error: Bool {
        hasAttemptedSave && (
            (chest ?? 0) > 250 ||
            (waist ?? 0) > 250 ||
            (armLength ?? 0) > 250 ||
            (torsoLength ?? 0) > 250
        )
    }
    
    private var hasEmptyError: Bool {
        hasAttemptedSave && (
            chest == nil ||
            waist == nil ||
            armLength == nil ||
            torsoLength == nil
        )
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoolaHeader(
                title: "Your measurement",
                onBack: onBack,
                onInfo: onInfo
            )

            Group {
                if data != nil {
                    VStack(spacing: 30) {
                        Group {
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
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if hasEmptyError {
                                    Text("Please fill in all fields")
                                        .font(.body15Regular)
                                        .foregroundColor(AppColors.errorRed)
                                }
                                
                                if isOver250Error {
                                    Text("Number must be below 250 cm")
                                        .font(.body15Regular)
                                        .foregroundColor(AppColors.errorRed)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                        }
                        
                        Spacer()
                        
                        RoolaButton(
                            buttonTitle: "Save",
                            buttonColor: AppColors.primaryPurple,
                            action: {
                                hasAttemptedSave = true
                                if !hasError {
                                    onDone()
                                }
                            }
                        )
                        .frame(width: UIScreen.main.bounds.width * 0.8)
                        .padding(.bottom, 50)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top,10)
                    .onAppear {
                        chest = Int(data?.chestCircumference ?? 0)
                        waist = Int(data?.waistCircumference  ?? 0)
                        armLength = Int(data?.armsLength  ?? 0)
                        torsoLength = Int(data?.torsoLength  ?? 0)
                    }
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
    }
}


struct ResultRow: View {
    let label: String
    let value: Double
    
    // Formatter to show one decimal place
    private var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        return f
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
            Spacer()
            Text("\(formatter.string(from: NSNumber(value: value)) ?? "0.0") cm")
                .font(.headline)
                .bold()
        }
    }
}

// 6. The Preview must be updated to provide a mock SwiftData container
#Preview {
    MeasurementResultView(
        data: MeasurementData(  // Pass dummy for preview
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
