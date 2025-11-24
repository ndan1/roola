//
//  HistoryDetailView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 12/11/25.
//

import SwiftUI
import SwiftData
import Foundation

struct HistoryDetailView: View {
    let history: MeasurementHistory
    
    @StateObject private var viewModel = RecommendationViewModel()
    @State private var isLoading = true
    @State private var loadError: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            FirstGradientBackground()
                .ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading history...")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            } else if let error = loadError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text("Failed to Load")
                        .font(.headline)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else if viewModel.serverResponse != nil {
                ResultsView(
                    recommendationViewModel: viewModel, showResults: .constant(true), initialFitPreference: history.selectedFitPreference, isFromHistory: true, historyProductName: history.productName ,onTryAgain: nil
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadHistoryData()
        }
    }
    
    private func loadHistoryData() {
        print("🔄 [HISTORY] Loading data for: \(history.productName)")
        
        guard let jsonData = history.recommendationsJSON.data(using: .utf8) else {
            print("❌ [HISTORY] Failed to convert JSON")
            loadError = "Invalid data format"
            isLoading = false
            return
        }
        
        print("📦 [HISTORY] JSON Data size: \(jsonData.count) bytes")
        
        do {
            let serverResponse = try JSONDecoder().decode(ServerResponse.self, from: jsonData)
            print("✅ [HISTORY] Successfully decoded ServerResponse")
            
            let userMeasurements = UserMeasurements(
                bust: history.userBust,
                waist: history.userWaist,
                torso: history.userTorso,
                armLength: history.userArmLength
            )
            
            viewModel.serverResponse = serverResponse
            viewModel.clothingType = history.clothingType
            viewModel.userMeasurements = userMeasurements
            
            print("✅ [HISTORY] ViewModel configured:")
            print("   - Clothing: \(history.clothingType)")
            print("   - Preference: \(history.selectedFitPreference)")
            print("   - Size: \(serverResponse.recommendations.regular.bestSize)")
            
            isLoading = false
            print("✅ [HISTORY] View ready to display")
            
        } catch {
            print("❌ [HISTORY] Decode error: \(error)")
            loadError = "Failed to load: \(error.localizedDescription)"
            isLoading = false
        }
    }
}
