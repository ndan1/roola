//
//  ClothingDetailView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 18/10/25.
//


import SwiftUI

struct ClothingDetailView: View {
    let clothes: Clothes

    // These computed properties check if any variant has arm or waist data.
    // This decides if we should show the column at all.
    private var hasArmLength: Bool {
        clothes.product_sizes.contains { $0.clothes_arm_length_min != nil }
    }
    private var hasWaist: Bool {
        clothes.product_sizes.contains { $0.clothes_waist_min != nil }
    }

    var body: some View {
        List {
            Section("Size Chart (cm)") {
                // Grid is perfect for creating table-like layouts.
                Grid(alignment: .leading, horizontalSpacing: 16) {
                    // --- TABLE HEADER ---
                    GridRow {
                        Text("Size").fontWeight(.bold)
                        Text("Torso").fontWeight(.bold)
                        Text("Bust").fontWeight(.bold)
                        if hasArmLength {
                            Text("Arm").fontWeight(.bold)
                        }
                        if hasWaist {
                            Text("Waist").fontWeight(.bold)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    Divider()

                    // --- TABLE ROWS ---
                    ForEach(clothes.product_sizes, id: \.size_name) { variant in
                        GridRow {
                            Text(variant.size_name).fontWeight(.semibold)
                            Text(formatMeasurement(min: variant.clothes_torso_min, max: variant.clothes_torso_max))
                            Text(formatMeasurement(min: variant.clothes_bust_min, max: variant.clothes_bust_max))
                            
                            // Conditionally show arm length data
                            if hasArmLength {
                                if let min = variant.clothes_arm_length_min, let max = variant.clothes_arm_length_max {
                                    Text(formatMeasurement(min: min, max: max))
                                } else {
                                    Text("-") // Placeholder for empty data
                                }
                            }
                            
                            // Conditionally show waist data
                            if hasWaist {
                                if let min = variant.clothes_waist_min, let max = variant.clothes_waist_max {
                                    Text(formatMeasurement(min: min, max: max))
                                } else {
                                    Text("-")
                                }
                            }
                        }
                        .font(.callout)
                        Divider()
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(clothes.product_name)
    }
    
    private func formatMeasurement(min: Int, max: Int) -> String {
        return min == max ? "\(min)" : "\(min)-\(max)"
    }
}
