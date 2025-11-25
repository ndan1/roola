
//
//  StaticMeasurementView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 11/11/25.
//

import SwiftUI

// MARK: - Top Row (rounded top)
struct TopStaticMeasurementRow: View {
    let label: String
    let value: Int?
    let unit: String = "cm"
    let isError: Bool
    let cornerRadius: CGFloat = 12

    var body: some View {
        StaticRowContent(label: label, value: value, unit: unit, isError: isError)
            .background(AppColors.primaryPurple.opacity(0.01))
            .clipShape(RoundedCorner(radius: cornerRadius, corners: [.topLeft, .topRight]))
            .overlay(
                RoundedCorner(radius: cornerRadius, corners: [.topLeft, .topRight])
                    .stroke(isError ? AppColors.errorRed : AppColors.grayScale400.opacity(0.36), lineWidth: 1)
            )
    }
}

// MARK: - Middle Row (no rounded corners)
struct MidStaticMeasurementRow: View {
    let label: String
    let value: Int?
    let unit: String = "cm"
    let isError: Bool

    var body: some View {
        StaticRowContent(label: label, value: value, unit: unit, isError: isError)
            .background(AppColors.primaryPurple.opacity(0.01))
            .overlay(
                Rectangle()
                    .stroke(isError ? AppColors.errorRed : AppColors.grayScale400.opacity(0.36), lineWidth: 1)
            )
    }
}

// MARK: - Bottom Row (rounded bottom)
struct BottomStaticMeasurementRow: View {
    let label: String
    let value: Int?
    let unit: String = "cm"
    let isError: Bool
    let cornerRadius: CGFloat = 12

    var body: some View {
        StaticRowContent(label: label, value: value, unit: unit, isError: isError)
            .background(AppColors.primaryPurple.opacity(0.01))
            .clipShape(RoundedCorner(radius: cornerRadius, corners: [.bottomLeft, .bottomRight]))
            .overlay(
                RoundedCorner(radius: cornerRadius, corners: [.bottomLeft, .bottomRight])
                    .stroke(isError ? AppColors.errorRed : AppColors.grayScale400.opacity(0.36), lineWidth: 1)
            )
    }
}

// MARK: - Shared row content (DRY)
private struct StaticRowContent: View {
    let label: String
    let value: Int?
    let unit: String
    let isError: Bool

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text(label)
                    .font(.body16Regular)
                    .foregroundColor(AppColors.primaryBlack)

                if isError {
                    Image(systemName: "exclamationmark.circle")
                        .font(.body14Regular)
                        .foregroundColor(AppColors.errorRed)
                }
            }

            Spacer()
            HStack(spacing: 4) {
                if let value = value {
                    Text("\(value)")
                        .font(.body16Regular)
                        .foregroundColor(AppColors.primaryBlack)
                        .fontWeight(.medium)
                } else {
                    Text("—")
                        .font(.body16Regular)
                        .foregroundColor(AppColors.grayScale300)
                }
                
                Text(unit)
                    .font(.body16Regular)
                    .foregroundColor(AppColors.grayScale300)
                    .fontWeight(.medium)
            }
            .frame(width: 120, alignment: .trailing)
        }
        .padding()
        .background(AppColors.primaryWhite.opacity(0.8))
    }
}

struct MeasurementItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Int?
    let unit: String = "cm"
    let isError: Bool = false
}

struct MeasurementListView: View {
    let items: [MeasurementItem]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { idx in
                let item = items[idx]

                Group {
                    if idx == 0 {
                        TopStaticMeasurementRow(
                            label: item.label,
                            value: item.value,
                            isError: item.isError
                        )
                    } else if idx == items.count - 1 {
                        BottomStaticMeasurementRow(
                            label: item.label,
                            value: item.value,
                            isError: item.isError
                        )
                    } else {
                        MidStaticMeasurementRow(
                            label: item.label,
                            value: item.value,
                            isError: item.isError
                        )
                    }
                }

                if idx < items.count - 1 {
                    Divider()
                        .background(AppColors.grayScale300)
                }
            }
        }
        .background(AppColors.primaryPurple.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.grayScale300, lineWidth: 1)
        )
    }
}

#Preview {
    MeasurementListView(
        items: [
            MeasurementItem(label: "Chest", value: 92),
            MeasurementItem(label: "Waist", value: 80),
            MeasurementItem(label: "Arm Length", value: 49),
            MeasurementItem(label: "Torso", value: nil)
        ]
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
