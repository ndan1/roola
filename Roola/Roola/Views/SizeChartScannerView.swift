//
//  SizeChartScannerView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 23/10/25.
//

import SwiftUI
import PhotosUI

struct SizeChartScannerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var extractedSizes: [SizeData] = []
    @State private var errorMessage: String?
    @State private var showingResults = false
    
    private let ocrService = OCRService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Image Preview
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Select a size chart image")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                }
                
                // Photo Picker Button
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Choose Size Chart Photo", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImage = image
                        }
                    }
                }
                
                // Scan Button
                if selectedImage != nil {
                    Button(action: {
                        Task {
                            await scanImage()
                        }
                    }) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Label("Scan Size Chart", systemImage: "text.viewfinder")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isProcessing ? Color.gray : Color.green)
                    .cornerRadius(12)
                    .disabled(isProcessing)
                    .padding(.horizontal)
                }
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Scan Size Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingResults) {
                SizeDataReviewView(sizeData: extractedSizes) {
                    dismiss()
                }
            }
        }
    }
    
    private func scanImage() async {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            let sizes = try await ocrService.extractSizeData(from: image)
            
            if sizes.isEmpty {
                errorMessage = "No size data found. Please try another image."
            } else {
                extractedSizes = sizes
                showingResults = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
    }
}

#Preview {
    SizeChartScannerView()
}
