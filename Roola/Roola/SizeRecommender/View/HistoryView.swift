//
//  HistoryView.swift
//  Roola
//
//  Created by F Rachell K on 10/11/25.
//

import SwiftUI
import SwiftData // Added from backend version

// The static `HistoryItem` struct from the HEAD version has been removed,
// as we are now using the `MeasurementHistory` model from SwiftData.

struct HistoryView: View {
    // --- Merged from backend version ---
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeasurementHistory.createdAt, order: .reverse) private var histories: [MeasurementHistory]
    // ---
    
    // --- Kept from UI version ---
    @State private var showSortSheet = false
    @State private var selectedSort = "Last 7 days"
    // ---
    
    var body: some View {
        // Using NavigationStack from backend version as it's more modern
        // and works with the NavigationLink.
        NavigationStack {
            ZStack {
                // Kept VStack structure from UI version
                VStack {
                    // Using `histories.isEmpty` (backend) instead of `historyItems.isEmpty` (UI)
                    if histories.isEmpty {
                        // Kept detailed EmptyHistoryView from UI version
                        EmptyHistoryView()
                    } else {
                        VStack{
                            // Kept Header and Sort Button from UI version
                            HStack{
                                RoolaHeader(
                                    title: "History",
                                    isLargeTitle: true
                                )
                                
                                Button(action: {
                                    showSortSheet = true
                                }) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(AppColors.primaryPurple)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 16)
                            }
                            .padding(.top, 18)
                            
                            // --- Merged ScrollView from backend version ---
                            // This replaces the `HistoryListView` from the UI version
                            ScrollView {
                                VStack(spacing: 12) {
                                    // Removed the simple `Text("History")` from the backend version
                                    // as we now have the RoolaHeader.
                                    
                                    ForEach(histories) { history in
                                        NavigationLink(destination: HistoryDetailView(history: history)) {
                                            // Using the HistoryCard from the backend version
                                            // as it's built for the `MeasurementHistory` model
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
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16) // Adjusted padding from backend version
                                .padding(.bottom, 32)
                            }
                            // --- End of merged ScrollView ---
                        }
                    }
                }
                .background(FirstGradientBackground().ignoresSafeArea()) // Kept from UI version
            }
            // Kept sheet from UI version
            .sheet(isPresented: $showSortSheet) {
                SortSheet(selectedSort: $selectedSort)
                    .presentationDetents([.height(350)])
            }
        }
    }
    
    // --- Kept from backend version ---
    private func deleteHistory(_ history: MeasurementHistory) {
        modelContext.delete(history)
        
        do {
            try modelContext.save()
            print("✅ History deleted successfully")
        } catch {
            print("❌ Failed to delete history: \(error)")
        }
    }
    // ---
}

// --- Kept from UI version ---
struct EmptyHistoryView: View {
    var body: some View {
        VStack {
            Spacer()
                .frame(height: UIScreen.main.bounds.height * 0.15)
            VStack(spacing: 64) {
                Spacer()
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 65))
                    .foregroundColor(AppColors.primaryPurple)
                    .background(
                        Circle()
                            .fill(Color.purple.opacity(0.1))
                            .frame(width: 120, height: 120)
                    )
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Start inputing your desire outfit and \nget recommendations")
                            .font(.title2_20Medium)
                        Spacer()
                    }
                    .padding(.leading, 30)
                    
                    VStack(spacing: 16) {
                        InstructionRow(icon: "sparkles", text: "Fill in your measurements manually or use our AI")
                        InstructionRow(icon: "sparkles", text: "Fill in your product details to get your best match")
                    }
                    .padding(.horizontal, 26)
                    
                    Spacer()
                }
            }
        }
    }
}

// --- Kept from UI version ---
struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.primaryPurple)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(AppColors.primaryWhite)
                    .font(.system(size: 18))
            }
            
            Text(text)
                .font(.body16Regular)
                .foregroundColor(AppColors.primaryBlack)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

// `HistoryListView` from the UI version was removed as its
// logic was merged directly into `HistoryView`.

// --- Kept from backend version ---
// This HistoryCard is used because it works with the `MeasurementHistory` model.
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
// --- End of backend version HistoryCard ---


// --- Kept from UI version ---
struct SortSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedSort: String
    
    let sortOptions = ["Newest", "Last 7 days", "Last 30 days"]
    
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(AppColors.grayScale400.opacity(1))
                .frame(width: 60, height: 5)
                .padding(.top, 12)
            
            HStack {
                Spacer()
                Text("Sort by")
                    .font(.heading24Medium)
                Spacer()
            }
            .padding(.vertical, 24)
            .overlay(alignment: .trailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(AppColors.grayScale300)
                        .padding(.trailing, 20)
                }
            }
            
            VStack(spacing: 0) {
                ForEach(sortOptions, id: \.self) { option in
                    Button(action: { selectedSort = option }) {
                        HStack {
                            Text(option)
                                .font(.title2_20Medium)
                                .foregroundColor(AppColors.primaryBlack)
                            Spacer()
                            Circle()
                                .stroke(AppColors.primaryPurple, lineWidth: 2)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .fill(AppColors.primaryPurple)
                                        .frame(width: 14, height: 14)
                                        .opacity(selectedSort == option ? 1 : 0)
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    }
                }
            }
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.button16Bold)
                    .foregroundColor(AppColors.primaryWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.primaryPurple)
                    .cornerRadius(28)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Spacer()
        }
    }
}
// --- End of UI version SortSheet ---


// --- Preview kept from backend version ---
// This is required for the SwiftData model container
#Preview {
    HistoryView()
        .modelContainer(for: MeasurementHistory.self, inMemory: true)
}