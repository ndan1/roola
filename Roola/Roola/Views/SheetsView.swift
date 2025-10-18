//
//  SheetView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 18/10/25.
//

import SwiftUI
import SwiftData

struct SheetView: View {
    // MARK: - Properties
    
    // Inputs from the previous view
    let clothes: Clothes
    
    // Environment and Data Fetching
    @Environment(\.dismiss) var dismiss
    @Query var users: [User]
    private var user: User? { users.first }
    
    // The source of truth for our view's state and logic
    @StateObject private var viewModel = SheetViewModel()
    
    // Computed property for available size names, which remains in the View
    private var availableSizes: [String] {
        clothes.product_sizes.map { $0.size_name }.sorted()
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - DEBUGGING CHECK
            Group {
                if let currentUser = user {
                    Text("✅ User Data Loaded: Bust is \(currentUser.bust, specifier: "%.1f") cm")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("❌ User Data Not Found")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            // MARK: - END DEBUGGING CHECK
            
            Text("Your Best Fit Recommendation")
                .font(.headline)
                .padding(.top)
            
            HStack(alignment: .center, spacing: 30) {
                // Left side: Recommendation and Size Picker
                VStack(spacing: 15) {
                    Text(viewModel.recommendedSize) // Read from ViewModel
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .frame(minHeight: 70)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    // Size Selection Buttons
                    HStack(spacing: 10) {
                        ForEach(availableSizes, id: \.self) { size in
                            Button(action: {
                                viewModel.selectSize(size) // Tell ViewModel about the interaction
                            }) {
                                Text(size)
                                    .fontWeight(.medium)
                                    .frame(width: 45, height: 45)
                                    .background(viewModel.selectedSize == size ? Color.black : Color(UIColor.systemGray5)) // UI depends on ViewModel state
                                    .foregroundColor(viewModel.selectedSize == size ? .white : .primary) // UI depends on ViewModel state
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                
                // Right side: Clothing Icon
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 80))
                    .frame(width: 120, height: 160)
                    .foregroundStyle(.secondary)
            }
            
            // FIT PREFERENCE SLIDER
            VStack(spacing: 8) {
                Text("Adjust Your Fit Preference")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // This Picker now binds directly to the ViewModel's desiredFit property
                Picker("Desired Fit", selection: $viewModel.desiredFit) {
                    ForEach(FitPreference.allCases, id: \.self) { fit in
                        Text(fit.rawValue).tag(fit)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.top, 10)
            
            // Dismiss Button
            Button("Done") {
                dismiss()
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.black)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
        .onAppear {
            // Pass the necessary data to the ViewModel when the view first appears
            viewModel.setup(clothes: clothes, user: user)
        }
    }
}
