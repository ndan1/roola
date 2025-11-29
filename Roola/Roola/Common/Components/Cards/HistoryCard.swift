//
//  HistoryCard.swift
//  Roola
//
//  Created by Lin Dan Christiano on 19/11/25.
//

import SwiftUI

struct HistoryCard: View {
    let history: MeasurementHistory
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.primaryPurple)
                    .frame(width: 50, height: 50)
                
                Text(history.bestSize ?? "N/A")
                    .font(.heading28Medium)
                    .foregroundColor(Color.white)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(history.productName)
                    .font(.body18Medium)
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(history.brandName)
                    .font(.body15Regular)
                    .foregroundColor(Color(hex: "#4E4E4E"))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(displayClothingType(history.clothingType))
                        .font(.caption)
                        .foregroundColor(AppColors.primaryPurple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.primaryPurple.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text(displayFitPreference(history.selectedFitPreference))
                        .font(.caption)
                        .foregroundColor(AppColors.primaryPurple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.primaryPurple.opacity(0.1))
                        .cornerRadius(6)
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(history.createdAt))
                    .font(.body15Regular)
                    .foregroundColor(Color(hex: "#4E4E4E"))
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func displayClothingType(_ type: String) -> String {
        switch type {
        case "t_shirt": return "T-Shirt"
        case "blouse": return "Blouse"
        case "long_sleeved_shirt": return "Long Sleeve"
        case "short_sleeved_shirt": return "Short Sleeve"
        default: return type.capitalized
        }
    }
    
    private func displayFitPreference(_ preference: String) -> String {
        return preference.capitalized
    }
}

#Preview {
    let sampleJSON = """
    {
        "recommendations": {
            "loose": {"bestScore": 85.0, "bestSize": "L", "partFits": {}},
            "regular": {"bestScore": 90.0, "bestSize": "M", "partFits": {}},
            "slightly-loose": {"bestScore": 88.0, "bestSize": "M", "partFits": {}},
            "slightly-tight": {"bestScore": 87.0, "bestSize": "S", "partFits": {}},
            "tight": {"bestScore": 82.0, "bestSize": "S", "partFits": {}}
        }
    }
    """
    
    return HistoryCard(history: MeasurementHistory(
        productName: "Classic T-Shirt",
        brandName: "Roola",
        clothingType: "short_sleeved_shirt",
        selectedFitPreference: "slightly-loose",
        recommendationsJSON: sampleJSON,
        userBust: 90.0,
        userWaist: 75.0,
        userTorso: 60.0,
        userArmLength: 55.0
    ))
}
