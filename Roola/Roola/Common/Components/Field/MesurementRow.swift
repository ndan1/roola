//
//  Test test.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 10/11/25.
//

import SwiftUI

struct MeasurementField: View {
    var label: String
    var unit: String
    @Binding var value: Int?
    var isError: Bool = false
    var isEditing: Bool = true
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            // LEFT SECTION
            HStack(spacing: 4) {
                Text(label)
                    .font(.body16Regular)
                    .foregroundColor(AppColors.primaryBlack)
                
                if isError {
                    Image(systemName: "exclamationmark.circle")
                        .font(.body16Regular)
                        .foregroundColor(AppColors.errorRed)
                }
            }
            
            Spacer()
            
            // RIGHT SECTION (tappable)
            HStack(spacing: 4) {
                if isEditing {
                    TextField("", value: $value, format: .number)
                        .font(.body16Regular)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($isFocused)
                        .fontWeight(.medium)
                        .frame(height: 20)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("\(value ?? 0)")
                        .font(.body16Regular)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primaryBlack)
                        .frame(height: 20)
                }

                Text(unit)
                    .font(.body16Regular)
                    .foregroundColor(AppColors.grayScale300)
                    .fontWeight(.medium)
            }
            .frame(width: 120, alignment: .trailing)
            .contentShape(Rectangle())
            .onTapGesture {
                if isEditing {
                    isFocused = true
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(isEditing ? AppColors.primaryWhite.opacity(0.8) : AppColors.primaryPurple.opacity(0.2))
    }
}


struct MeasurementRow: View {
    var label: String
    var unit: String
    @Binding var value: Int?
    var isError: Bool = false
    var isEditing: Bool = true

    var body: some View {
        MeasurementField(label: label, unit: unit, value: $value, isError: isError, isEditing: isEditing)
            .overlay(
                Rectangle().stroke(isError ? AppColors.errorRed : AppColors.grayScale300, lineWidth: 0.5)
            )
    }
}


struct TopMeasurementRow: View {
    var label: String
    var unit: String
    @Binding var value: Int?
    var isError: Bool = false
    var isEditing: Bool = true
    var cornerRadius: CGFloat = 12

    var body: some View {
        MeasurementField(label: label, unit: unit, value: $value, isError: isError, isEditing: isEditing)
            .cornerRadius(cornerRadius, corners: [.topLeft, .topRight])
            .overlay(
                RoundedCorner(radius: cornerRadius, corners: [.topLeft, .topRight])
                    .stroke(isError ? AppColors.errorRed : AppColors.grayScale300, lineWidth: 0.5)
            )
    }
}


extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}


struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
struct BottomMeasurementRow: View {
    var label: String
    var unit: String
    @Binding var value: Int?
    var isError: Bool = false
    var isEditing: Bool = true
    var cornerRadius: CGFloat = 12

    var body: some View {
        MeasurementField(label: label, unit: unit, value: $value, isError: isError, isEditing: isEditing)
            .cornerRadius(cornerRadius, corners: [.bottomLeft, .bottomRight])
            .overlay(
                RoundedCorner(radius: cornerRadius, corners: [.bottomLeft, .bottomRight])
                    .stroke(isError ? AppColors.errorRed : AppColors.grayScale300, lineWidth: 0.5)
            )
    }
}

#Preview {
    
    struct PreviewWrapper: View {
        // State for the "normal" card
        @State private var topValue: Int? = 90
        @State private var midValue: Int? = 60
        @State private var botValue: Int? = 95
        
        // State for the "error" card
        @State private var topErrValue: Int? = nil
        @State private var midErrValue: Int? = 300
        @State private var botErrValue: Int? = 40
        
        var body: some View {
            ScrollView {
                VStack(spacing: 30) {
                    
                    // Editing Mode
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Editing Mode (Background Putih)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 0) {
                            TopMeasurementRow(label: "Chest", unit: "cm", value: $topValue, isEditing: true)
                            MeasurementRow(label: "Waist", unit: "cm", value: $midValue, isEditing: true)
                            MeasurementRow(label: "Arm Length", unit: "cm", value: $midValue, isEditing: true)
                            BottomMeasurementRow(label: "Torso", unit: "cm", value: $botValue, isEditing: true)
                        }
                    }
                    
                    // Non-Editing Mode
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Non-Editing Mode (Background Ungu)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 0) {
                            TopMeasurementRow(label: "Chest", unit: "cm", value: $topValue, isEditing: false)
                            MeasurementRow(label: "Waist", unit: "cm", value: $midValue, isEditing: false)
                            MeasurementRow(label: "Arm Length", unit: "cm", value: $midValue, isEditing: false)
                            BottomMeasurementRow(label: "Torso", unit: "cm", value: $botValue, isEditing: false)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // This tells the preview to show our wrapper
    return PreviewWrapper()
}
