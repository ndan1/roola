//
//  MeasurementResultView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 09/11/25.
//

import SwiftUI

/// A simple view to display the final measurement results.
struct MeasurementResultView: View {
    let data: MeasurementData
    
    /// Action to dismiss the entire flow
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Measurements Complete")
                .font(.title)
                .bold()

            VStack(alignment: .leading, spacing: 15) {
                ResultRow(label: "Height", value: data.height)
                ResultRow(label: "Waist Circumference", value: data.waistCircumference)
                ResultRow(label: "Chest Circumference", value: data.chestCircumference)
                ResultRow(label: "Torso Length", value: data.torsoLength)
                ResultRow(label: "Arms Length", value: data.armsLength)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            Spacer()
            
            Button("Done") {
                onDone()
            }
            .font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(30)
    }
}

/// A helper view for displaying a single result row
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
        }
    )
}
