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
    @State private var showFilterSheet = false
    @State private var searchText = ""
    
    // FILTER STATES
    @State private var selectedTimeRange = "All Time"
    @State private var selectedClothesTypes: Set<String> = []
    
    private var filteredHistories: [MeasurementHistory] {
        let now = Date()
        let calendar = Calendar.current
        
        // 1. Filter by Time Range
        var timeFiltered: [MeasurementHistory]
        
        switch selectedTimeRange {
        case "Last 7 days":
            if let date = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) {
                timeFiltered = allHistories.filter { $0.createdAt >= date }
            } else { timeFiltered = allHistories }
            
        case "Last 30 days":
            if let date = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now)) {
                timeFiltered = allHistories.filter { $0.createdAt >= date }
            } else { timeFiltered = allHistories }
            
        case "Last 90 days":
            if let date = calendar.date(byAdding: .day, value: -90, to: calendar.startOfDay(for: now)) {
                timeFiltered = allHistories.filter { $0.createdAt >= date }
            } else { timeFiltered = allHistories }
            
        case "This month":
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)
            timeFiltered = allHistories.filter {
                let month = calendar.component(.month, from: $0.createdAt)
                let year = calendar.component(.year, from: $0.createdAt)
                return month == currentMonth && year == currentYear
            }
            
        default: // "All Time"
            timeFiltered = allHistories
        }
        
        // 2. Filter by Clothes Type
        var typeFiltered: [MeasurementHistory]
        if selectedClothesTypes.isEmpty {
            typeFiltered = timeFiltered
        } else {
            typeFiltered = timeFiltered.filter { history in
                selectedClothesTypes.contains(history.clothingType)
            }
        }
        
        // 3. Filter by Search Text
        if searchText.isEmpty {
            return typeFiltered
        } else {
            return typeFiltered.filter { history in
                history.productName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !filteredHistories.isEmpty {
                // MARK: - Search Bar Area
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search", text: $searchText)
                                .font(.body)
                                .submitLabel(.search)
                            
                            Button(action: {
                                showFilterSheet = true
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "slider.horizontal.3")
                                        .resizable()
                                        .frame(width: 22, height: 22)
                                        .foregroundColor(AppColors.primaryPurple)
                                    
                                    if isFilterActive {
                                        Circle()
                                            .fill(.red)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 2, y: -2)
                                    }
                                }
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
                }
                
                // MARK: - Content List (Updated to List)
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
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) { // Spacing antar kartu
                            ForEach(filteredHistories) { history in
                                
                                // Gunakan Wrapper Custom SwipeableCard
                                SwipeableCard {
                                    // Masukkan HistoryCard asli kamu di sini
                                    HistoryCard(history: history)
                                } onDelete: {
                                    // Panggil fungsi delete kamu
                                    deleteHistory(history)
                                }
                                .padding(.horizontal, 20) // Padding kiri kanan layar
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    .scrollContentBackground(.hidden)
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
                        .padding(.leading, 6)
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(
                activeTimeRange: $selectedTimeRange,
                activeClothesTypes: $selectedClothesTypes
            )
            .presentationDetents([.fraction(0.95)])
        }
    }
    
    private var isFilterActive: Bool {
        return selectedTimeRange != "All Time" || !selectedClothesTypes.isEmpty
    }
    
    private func deleteHistory(_ history: MeasurementHistory) {
        // Hapus dari context
        modelContext.delete(history)
        do {
            // Simpan perubahan
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
