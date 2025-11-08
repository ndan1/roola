//
//  TextField.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 07/11/25.
//

import SwiftUI

struct MeasurementField: View {
    let label: String
    let placeholder: String
    let unit: String = "cm"
    @Binding var inputText: String
    var body: some View {
        HStack(spacing: 8) {

            Text(label)
                .font(.body)
                .foregroundColor(.primary)
                .fontWeight(.medium)
            
            Spacer()
            
            TextField(placeholder, text: $inputText)
                .font(.body)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.primary)
                        
            Text(unit)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        MeasurementField(
            label: "Chest",
            placeholder: "Chest", inputText: .constant("90")
        )

        MeasurementField(
            label: "Waist",
            placeholder: "Waist",
            inputText: .constant("90")
        )
        
        MeasurementField(
            label: "Hips",
            placeholder: "Hips",
            inputText: .constant("90")
        )
    }
    .padding()
}
