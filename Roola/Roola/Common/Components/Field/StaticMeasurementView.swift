//
//  StaticMeasurementView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 11/11/25.
//

import SwiftUI

struct MeasurementItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Int?
    let unit: String = "cm"
}

struct MeasurementListView: View {
    var items: [MeasurementItem]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                MeasurementDisplayRow(
                    label: item.label,
                    value: item.value,
                    unit: item.unit,
                    cornerRadius: cornerRadius(for: index)
                )
                
                // Add divider between rows except for last one
                if index < items.count - 1 {
                    Divider()
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // Helper for rounded corners (top/bottom only)
    private func cornerRadius(for index: Int) -> CGFloat {
        if index == 0 || index == items.count - 1 {
            return 12
        } else {
            return 0
        }
    }
}

struct MeasurementDisplayRow: View {
    var label: String
    var value: Int?
    var unit: String = "cm"
    var isError: Bool = false
    var cornerRadius: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text(label)
                    .font(.body)
                if isError {
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            if let value = value {
                Text("\(value)")
                    .font(.body)
                    .foregroundColor(.primary)
            } else {
                Text("—")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Text(unit)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(isError ? Color.red : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    MeasurementListView(
        items: [
            MeasurementItem(label: "Chest", value: 92),
            MeasurementItem(label: "Waist", value: 80,),
            MeasurementItem(label: "Arm Length", value: 49),
            MeasurementItem(label: "Torso", value: nil)
        ]
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
