//
//  SheetView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 18/10/25.
//

import SwiftUI
import SwiftData

struct SheetView: View {
    // MARK: - Properties
    
    let clothes: Clothes
    let user: User?
    
    init(clothes: Clothes, user: User? = nil) {
        self.clothes = clothes
        self.user = user
    }
    
    @Environment(\.dismiss) var dismiss
    @Query var users: [User]
    
    @StateObject private var viewModel = SheetViewModel()
    
    private var availableSizes: [String] {
        let sizeOrder = ["XS", "S", "M", "L", "XL", "XXL", "XXXL"]
        
        return clothes.product_sizes.map { $0.size_name }.sorted {
            let firstIndex = sizeOrder.firstIndex(of: $0) ?? Int.max
            let secondIndex = sizeOrder.firstIndex(of: $1) ?? Int.max
            
            return firstIndex < secondIndex
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: 20) {
                // Recommendation and Size Picker
                VStack(spacing: 15) {
                    Text("Your best size is")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(viewModel.recommendedSize)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .frame(minHeight: 60)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(.blue)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(availableSizes, id: \.self) { size in
                                Button(action: {
                                    viewModel.selectedSize = size
                                }) {
                                    Text(size)
                                        .fontWeight(.medium)
                                        .frame(width: 40, height: 40)
                                        .background(viewModel.selectedSize == size ? Color.blue : Color(UIColor.systemGray5))
                                        .foregroundColor(viewModel.selectedSize == size ? .white : .primary)
                                }
                            }
                        }
                    }
                }
                
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 70))
                    .frame(width: 100, height: 140)
                    .foregroundStyle(.secondary)
                    .shadow(radius: 2)
            }
            .padding(.horizontal)
            
            VStack(spacing: 10) {
                Text("Selected Size Fit")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                FitIndicatorView(
                    currentFit: viewModel.selectedSizeFitCategory
                )
                .frame(height: 50)
            }
            .padding(.horizontal)
            
            Text("Notes:\nCorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis.")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Caution:\nCorem ipsum dolor sit amet, consectetur adipiscing elit.  ")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .onAppear {
            viewModel.setup(clothes: clothes, user: user)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var container: ModelContainer
        @State private var mockClothes: Clothes
        init() {
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                let tempContainer = try ModelContainer(for: Clothes.self, User.self, configurations: config)
                let user = User()
                tempContainer.mainContext.insert(user)
                let tShirtVariants = [
                    Variant(size_name: "S", clothes_torso_min: 58, clothes_torso_max: 58, clothes_bust_min: 86, clothes_bust_max: 86),
                    Variant(size_name: "M", clothes_torso_min: 60, clothes_torso_max: 60, clothes_bust_min: 92, clothes_bust_max: 92),
                    Variant(size_name: "L", clothes_torso_min: 62, clothes_torso_max: 62, clothes_bust_min: 98, clothes_bust_max: 98),
                    Variant(size_name: "XL", clothes_torso_min: 64, clothes_torso_max: 64, clothes_bust_min: 104, clothes_bust_max: 104),
                    Variant(size_name: "XXL", clothes_torso_min: 66, clothes_torso_max: 66, clothes_bust_min: 110, clothes_bust_max: 110)
                ]
                let classicTShirt = Clothes(product_id: "TS001", product_name: "Classic T-Shirt", product_type: "T-Shirt", product_sizes: tShirtVariants)
                tempContainer.mainContext.insert(classicTShirt)
                _container = State(initialValue: tempContainer)
                _mockClothes = State(initialValue: classicTShirt)
            } catch {
                fatalError("Failed to create model container for preview: \(error.localizedDescription)")
            }
        }
        var body: some View {
            VStack { Text("Preview Container") }
            .sheet(isPresented: .constant(true)) {
                SheetView(clothes: mockClothes)
                    .modelContainer(container)
            }
        }
    }
    return PreviewWrapper()
}
