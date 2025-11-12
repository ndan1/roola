//
//  Test test.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 10/11/25.
//

import SwiftUI

struct MeasurementRow: View {
    var label: String
    var unit = "cm"
    @Binding var value: Int?
    var isError: Bool = false

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text(label)
                    .font(.body16Regular)
                if isError {
                    Image(systemName: "exclamationmark.circle")
                        .font(.body16Regular)
                        .foregroundColor(AppColors.errorRed)
                } else {
                    EmptyView()
                }
            }

            Spacer()

            TextField("", value: $value, format: .number)
                .font(.body16Regular)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)

            Text(unit)
                .font(.body16Regular)
                .foregroundColor(AppColors.grayScale300)
        }
        .padding()
        .background(AppColors.primaryWhite)
        .overlay(
            Rectangle()
                .stroke(isError ? AppColors.errorRed : AppColors.borderButton, lineWidth: 1)
        )
    }
}

struct TopMeasurementRow: View {
    var label: String
    var unit = "cm"
    @Binding var value: Int?
    var isError: Bool = false
    var cornerRadius: CGFloat = 12
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text(label)
                    .font(.body16Regular)
                
                if isError {
                    Image(systemName: "exclamationmark.circle")
                        .font(.body16Regular)
                        .foregroundColor(AppColors.errorRed)
                }
            }
            
            Spacer()
            
            TextField("", value: $value, format: .number)
                .font(.body16Regular)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            
            Text(unit)
                .font(.body16Regular)
                .foregroundColor(AppColors.grayScale300)
        }
        .padding()
        .background(AppColors.primaryWhite)
        .cornerRadius(cornerRadius, corners: [.topLeft, .topRight])
        
        .overlay(
            RoundedCorner(radius: cornerRadius, corners: [.topLeft, .topRight])
                .stroke(isError ? AppColors.errorRed : AppColors.grayScale300, lineWidth: 1)
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
    var unit = "cm"
    @Binding var value: Int?
    var isError: Bool = false
    var cornerRadius: CGFloat = 12
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text(label)
                    .font(.body16Regular)
                
                if isError {
                    Image(systemName: "exclamationmark.circle")
                        .font(.body16Regular)
                        .foregroundColor(AppColors.errorRed)
                }
            }
            
            Spacer()
            
            TextField("", value: $value, format: .number)
                .font(.body16Regular)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            
            Text(unit)
                .font(.body16Regular)
                .foregroundColor(AppColors.grayScale300)
        }
        .padding()
        .background(AppColors.primaryWhite)
        .cornerRadius(cornerRadius, corners: [.bottomLeft, .bottomRight])
        .overlay(
                    RoundedCorner(radius: cornerRadius, corners: [.bottomLeft, .bottomRight])
                        .stroke(isError ? AppColors.errorRed : AppColors.grayScale300, lineWidth: 1)
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
        @State private var midErrValue: Int? = 300 // Error value
        @State private var botErrValue: Int? = 40
        
        var body: some View {
            VStack(spacing: 30) {
                
                // --- EXAMPLE 1: NORMAL STATE ---
                VStack(spacing: 0) {
                    TopMeasurementRow(label: "Chest", value: $topValue)
                    Divider()
                    MeasurementRow(label: "Waist", value: $midValue)
                    Divider()
                    BottomMeasurementRow(label: "Arm Length", value: $botValue)
                }
                .cornerRadius(12) // Apply corner radius to the whole stack
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
        }
    }
    
    // This tells the preview to show our wrapper
    return PreviewWrapper()
}

