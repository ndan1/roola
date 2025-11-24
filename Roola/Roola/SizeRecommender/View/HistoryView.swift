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
    @State private var searchText = ""
    
    private var filteredHistories: [MeasurementHistory] {
        let now = Date()
        let calendar = Calendar.current
        
        var dateFiltered: [MeasurementHistory]
        
        switch selectedSort {
        case "Newest":
            return allHistories
        case "Last 7 days":
            if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) {
                    dateFiltered = allHistories.filter { $0.createdAt >= sevenDaysAgo }
                } else {
                    dateFiltered = allHistories
                }
        case "Last 30 days":
            if let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now)) {
                    dateFiltered = allHistories.filter { $0.createdAt >= thirtyDaysAgo }
                } else {
                    dateFiltered = allHistories
                }
        default:
            return allHistories
        }
        if searchText.isEmpty {
            return dateFiltered
        } else {
            return dateFiltered.filter { history in
                // Case insensitive search
                history.productName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search", text: $searchText)
                            .font(.body)
                            .submitLabel(.search)
                        
                        Button(action: {
                            showSortSheet = true
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .resizable()
                                .frame(width: 22, height: 22)
                                .foregroundColor(AppColors.primaryPurple)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)
                
                // 3. Content List
                if filteredHistories.isEmpty {
                    Spacer()
                    if searchText.isEmpty && allHistories.isEmpty {
                        EmptyHistoryView()
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                                .padding(.bottom, 8)
                            Text("No history found")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                }else {
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
                        .padding(.vertical, 8)
                    }
                    .clipped()
                }
            }
            .background(FirstGradientBackground().ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("History")
                        .font(.heading28Medium)
                        .foregroundStyle(.primary)
                }
            }
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
                brandName: "The Cotton Co.",
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
                brandName: "Elegant Wears",
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
                brandName: "Urban Store",
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
