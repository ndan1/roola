//
//  HistoryView.swift
//  Roola
//
//  Created by F Rachell K on 10/11/25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeasurementHistory.createdAt, order: .reverse) private var histories: [MeasurementHistory]
    
    var body: some View {
        NavigationStack {
            ZStack {
                FirstGradientBackground()
                
                if histories.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            Text("History")
                                .font(.heading32Medium)
                                
                            ForEach(histories) { history in
                                NavigationLink(destination: HistoryDetailView(history: history)) {
                                    HistoryCard(history: history)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteHistory(history)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            .padding(.top, 64)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
    }
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No History Yet")
                .font(.heading24Medium)
                .foregroundColor(.gray)
            
            Text("Your saved measurements will appear here")
                .font(.body16Regular)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
    
    private func deleteHistory(_ history: MeasurementHistory) {
        modelContext.delete(history)
        
        do {
            try modelContext.save()
            print("✅ History deleted successfully")
        } catch {
            print("❌ Failed to delete history: \(error)")
        }
    }
}

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
                    .foregroundColor(Color(hex: "#838383"))
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

#Preview {
    HistoryView()
        .modelContainer(for: MeasurementHistory.self, inMemory: true)
}
