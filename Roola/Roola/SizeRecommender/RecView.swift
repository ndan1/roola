//
//  FuzzyTestView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 30/10/25.
//
//  This view is for testing the local FuzzyRecommenderViewModel.
//

import SwiftUI

struct FuzzyTestView: View {
    
    // 1. Instantiate the ViewModel
    @StateObject private var viewModel = FuzzyRecommenderViewModel()
    
    // 2. Mock Data for Testing
    
    // Mock user data (from testView.swift)
    private let mockUser = UserMeasurements(
        bust: 91.0,
        waist: 73.0,
        hips: 100.0,
        shoulderWidth: 37.0,
        torso: 58.0,
        armLength: 55.0
    )
    
    // Mock clothes data (Blouse)
    private let mockBlouseData: ClothesData = {
        let s_measurements = SizeMeasurements(
            torso: [58.0, 58.0],     // User torso is 58.0
            bust: [92.0, 92.0],      // User bust is 91.0
            armLength: [56.0, 56.0], // User armLength is 55.0
            waist: nil
        )
        let m_measurements = SizeMeasurements(
            torso: [60.0, 60.0],
            bust: [96.0, 96.0],
            armLength: [57.0, 57.0],
            waist: nil
        )
        let l_measurements = SizeMeasurements(
            torso: [62.0, 62.0],
            bust: [100.0, 100.0],
            armLength: [58.0, 58.0],
            waist: nil
        )
        
        // This is the size chart for the "blouse"
        let sizeChart = [
            "S": s_measurements,
            "M": m_measurements,
            "L": l_measurements
        ]
        
        // This matches the ClothesData struct format
        return ClothesData(item: ["blouse": sizeChart])
    }()
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Local Fuzzy Logic Test")
                    .font(.title)
                    .fontWeight(.bold)
                
                // 3. Button to trigger calculation
                Button {
                    // Call the ViewModel function with the mock data
                    viewModel.calculateAllRecommendations(
                        userMeasurements: mockUser,
                        clothesData: mockBlouseData
                    )
                } label: {
                    Label("Calculate Recommendations", systemImage: "sparkles.gearshape")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // 4. Display Loading, Error, or Results
                
                if viewModel.isLoading {
                    ProgressView("Calculating...")
                        .padding()
                }
                
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                
                if let recommendations = viewModel.recommendations {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Recommendations")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // Display results for each fit
                        RecommendationRow(fit: "Regular", recommendation: recommendations.regular)
                        Divider()
                        RecommendationRow(fit: "Loose", recommendation: recommendations.loose)
                        Divider()
                        RecommendationRow(fit: "Slightly Loose", recommendation: recommendations.slightlyLoose)
                        Divider()
                        RecommendationRow(fit: "Slightly Tight", recommendation: recommendations.slightlyTight)
                        Divider()
                        RecommendationRow(fit: "Tight", recommendation: recommendations.tight)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

/// A helper view to display a single recommendation row
struct RecommendationRow: View {
    let fit: String
    let recommendation: FitRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(fit)
                .font(.headline)
                .foregroundColor(Color.blue)
            
            HStack {
                Text("Best Size:")
                    .fontWeight(.medium)
                Spacer()
                Text(recommendation.bestSize)
                    .font(.system(.body, design: .monospaced))
                    .padding(5)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(5)
            }
            
            HStack {
                Text("Score:")
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.1f%%", recommendation.bestScore))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Part Fits:")
                    .fontWeight(.medium)
                
                if recommendation.partFits.isEmpty {
                    Text("N/A")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    // Sort the keys for a consistent order
                    ForEach(recommendation.partFits.sorted(by: { $0.key < $1.key }), id: \.key) { part, fit in
                        HStack {
                            Text("  • \(part.capitalized):")
                                .font(.caption)
                            Text(fit)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(.top, 2)
        }
    }
}

#Preview {
    FuzzyTestView()
}
