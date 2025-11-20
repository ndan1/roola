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
                    RoolaHeader(
                        title: "History",
                        isLargeTitle: true
                    )
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
                            .padding(.horizontal, 20)
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
