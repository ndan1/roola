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
    
    @Query(sort: \MeasurementHistory.createdAt, order: .reverse) private var allHistories: [MeasurementHistory]
    
    @State private var showSortSheet = false
    @State private var selectedSort = "Last 7 days"
    
    private var filteredHistories: [MeasurementHistory] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedSort {
        case "Newest":
            return allHistories
        case "Last 7 days":
            guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) else {
                return allHistories
            }
            return allHistories.filter { $0.createdAt >= sevenDaysAgo }
        case "Last 30 days":
            guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now)) else {
                return allHistories
            }
            return allHistories.filter { $0.createdAt >= thirtyDaysAgo }
        default:
            return allHistories
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if allHistories.isEmpty {
                    EmptyHistoryView()
                } else {
                    VStack {
                        HStack {
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
                            .padding(.trailing, 18)
                        }
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(filteredHistories) { history in
                                    NavigationLink(destination: HistoryDetailView(history: history)) {
                                        HistoryCard(history: history)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .background(FirstGradientBackground().ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSortSheet) {
            SortSheet(selectedSort: $selectedSort)
                .presentationDetents([.height(350)])
        }
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
                            .font(.title3)
                            .fontWeight(.semibold)
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

// MARK: - History Card (From Logic Example)
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

#Preview("Filled State") {

    @MainActor
    func createFilledContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: MeasurementHistory.self, configurations: config)
            let context = container.mainContext
            
            let mockRecommendations = """
            {
                "tight": { "bestSize": "S", "bestScore": 85.0 },
                "standard": { "bestSize": "M", "bestScore": 95.0 },
                "loose": { "bestSize": "L", "bestScore": 90.0 }
            }
            """
            
            let history1 = MeasurementHistory(
                productName: "Classic T-Shirt",
                shopName: "The Cotton Co.",
                clothingType: "t_shirt",
                selectedFitPreference: "standard",
                recommendationsJSON: mockRecommendations,
                userBust: 85.5,
                userWaist: 65.0,
                userTorso: 42.0,
                userArmLength: 55.0
            )
            
            history1.createdAt = Date().addingTimeInterval(-86400 * 2)
            
            let history2 = MeasurementHistory(
                productName: "Silk Blouse",
                shopName: "Elegant Wears",
                clothingType: "blouse",
                selectedFitPreference: "slim",
                recommendationsJSON: mockRecommendations,
                userBust: 86.0,
                userWaist: 66.0,
                userTorso: 43.0,
                userArmLength: 56.0
            )
            history2.createdAt = Date().addingTimeInterval(-86400 * 5)
            
            let history3 = MeasurementHistory(
                productName: "Long Sleeve",
                shopName: "Urban Store",
                clothingType: "long_sleeved_shirt",
                selectedFitPreference: "relaxed",
                recommendationsJSON: mockRecommendations,
                userBust: 84.0,
                userWaist: 64.0,
                userTorso: 41.0,
                userArmLength: 54.0
            )
            history3.createdAt = Date().addingTimeInterval(-86400 * 10)
            
            context.insert(history1)
            context.insert(history2)
            context.insert(history3)
            
            return container
        } catch {
            fatalError("Failed to create in-memory container: \(error)")
        }
    }
    return HistoryView()
        .modelContainer(createFilledContainer())
}
