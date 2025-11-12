//
//  RecommendationCards.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 11/11/25.
//

import SwiftUI

struct RecommendationCard: View {
    let fit: String
    let recommendation: FitRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(fit)
                    .font(.headline)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text(recommendation.bestSize)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack {
                Text("Match Score:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f%%", recommendation.bestScore))
                    .fontWeight(.semibold)
            }
            
            if !recommendation.partFits.isEmpty {
                Divider()
                
                Text("Part Fits:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(recommendation.partFits.sorted(by: { $0.key < $1.key }), id: \.key) { part, fit in
                        HStack {
                            Text(part.capitalized)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(fit)
                                .fontWeight(.medium)
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

//#Preview {
//    RecommendationCard(fit: <#String#>, recommendation: FitRecommendation)
//}
