//
//  MeasurementResultView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 09/11/25.
//

import SwiftUI
import SwiftData

struct MeasurementResultView: View {
    let data: MeasurementData?  // New: Accept data from API/dummy
    @State var isPresented: Bool = false
    
    var onDone: () -> Void
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            FirstGradientBackground()
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // ✅ Always stays at the top
                HStack(spacing: 20) {
                    Button(action: onBack ?? { }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(AppColors.primaryWhite)
                            .background(
                                Circle()
                                .fill(AppColors.primaryPurple)
                            )
                    }
                    
                    Text("Your measurements")
                        .font(.heading24Medium)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented.toggle()
                        print($isPresented)
                    }) {
                        Image(systemName: "info.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(AppColors.primaryPurple)
                    }
                }
                .padding()
                .padding(.horizontal, 10)

                // ✅ Main content area
                Group {
                    if let data = data {
                        VStack(spacing: 30) {
                            VStack(alignment: .leading, spacing: 15) {
                                ResultRow(label: "Waist Circumference", value: data.waistCircumference)
                                ResultRow(label: "Chest Circumumference", value: data.chestCircumference)
                                ResultRow(label: "Torso Length", value: data.torsoLength)
                                ResultRow(label: "Arms Length", value: data.armsLength)
                                ResultRow(label: "Height", value: data.height)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.top, 20)
                            
                            Spacer()
                            
                            RoolaButton(
                                buttonTitle: "Save",
                                buttonColor: AppColors.primaryPurple,
                                action: onDone
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.8)
                            .padding(.bottom, 50)
                        }
                        .padding(30)
                    } else {
                        VStack(spacing: 10) {
                            Text("Measurement Data Not Found")
                                .font(.title2)
                            Text("Please try the measurement again.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 40)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 45)
        }
    }
}

/// A helper view for displaying a single result row
/// (This view remains unchanged as it already accepts a Double)
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
        }
    )
}
