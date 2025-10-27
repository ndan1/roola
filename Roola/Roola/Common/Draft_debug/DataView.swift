//
//  DataView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 23/10/25.
//


// DataView.swift

import SwiftUI
import SwiftData

struct DataView: View {
    @Query var clothes: [Clothes]
    @Query var users: [User]
    
    private var user: User? {
        users.first
    }

    var body: some View {
        NavigationStack {
            List {
                // User Data Section (no changes here)
                if let currentUser = user {
                    Section(header: Text("My Measurements")) {
                        HStack { Text("Height"); Spacer(); Text("\(currentUser.height) cm") }
                        HStack { Text("Weight"); Spacer(); Text("\(currentUser.weight) kg") }
                        HStack { Text("Bust"); Spacer(); Text("\(currentUser.bust) cm") }
                        HStack { Text("Waist"); Spacer(); Text("\(currentUser.waist) cm") }
                    }
                }
                
                // --- MODIFIED SECTION ---
                Section(header: Text("Clothing Catalog")) {
                    ForEach(clothes) { item in
                        // Wrap the existing view in a NavigationLink
                        NavigationLink(destination: ClothingDetailView(clothes: item)) {
                            VStack(alignment: .leading) {
                                Text(item.product_name)
                                    .fontWeight(.bold)
                                Text("Type: \(item.product_type)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Roola")
        }
    }
}