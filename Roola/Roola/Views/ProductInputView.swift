//
//  ProductInputView.swift
//  Roola
//

import SwiftUI
import SwiftData

struct ProductInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    @StateObject private var viewModel = ProductFetchViewModel()
    @State private var urlInput: String = ""
    @State private var showSheet: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Paste Shopee Link")
                    .font(.headline)
                
                TextField("https://id.shp.ee/...", text: $urlInput)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await viewModel.fetchProductFromShortURL(urlInput)
                        if viewModel.fetchedClothes != nil {
                            showSheet = true
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Get Recommendation")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(urlInput.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                }
                .disabled(viewModel.isLoading || urlInput.isEmpty)
                .padding(.horizontal)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .navigationTitle("Size Finder")
            .sheet(isPresented: $showSheet) {
                if let clothes = viewModel.fetchedClothes, let user = users.first {
                    SheetView(clothes: clothes, user: user)
//                    ClothingDetailView(clothes: clothes)
                }
            }
            .onDisappear {
                viewModel.reset()
            }
        }
    }
}
