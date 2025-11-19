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
                    .fill(AppColors.primaryPurple.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppColors.primaryPurple)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(history.productName)
                    .font(.body16Regular)
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(history.shopName)
                    .font(.body15Regular)
                    .foregroundColor(AppColors.grayScale300)
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
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(history.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
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
