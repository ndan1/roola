//
//  RecommendationView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 04/11/25.
//

import SwiftUI
import Vision
import PhotosUI
import SwiftData

struct RecommendationView: View {
    
    @StateObject private var viewModel = RecommendationViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @Query private var users: [User]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("OCR + AI Size Extractor")
                    .font(.title)
                    .fontWeight(.bold)
                
                imageDisplayView
                
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Select from Gallery", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .onChange(of: selectedPhoto) { oldValue, newValue in
                    viewModel.handlePhotoSelection(newValue)
                }
                
                processButtonView
                
                ocrResultView
                
                apiSectionView
                
            }
            .padding()
            .alert(viewModel.currentError?.title ?? "Error", isPresented: $viewModel.showErrorAlert) {
                Button("Retry", role: .cancel) {
                    viewModel.resetAllStates()
                    selectedPhoto = nil
                    viewModel.selectedImage = nil
                }
            } message: {
                Text(viewModel.currentError?.message ?? "")
            }
            .onAppear{
                if let user = users.first{
                    viewModel.loadUserMeasurements(user: user)
                }
            }
        }
    }
    
    // MARK: - Sub-Views
    
    @ViewBuilder
    private var imageDisplayView: some View {
        if let image = viewModel.selectedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .shadow(radius: 5)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 300)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No image selected")
                            .foregroundColor(.gray)
                            .font(.headline)
                    }
                )
        }
    }
    
    private var processButtonView: some View {
        VStack {
            Button {
                viewModel.processImage()
            } label: {
                Label("1. Process Image (OCR + AI)", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.selectedImage == nil ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(viewModel.selectedImage == nil || viewModel.isProcessing)
            
            if viewModel.isProcessing {
                VStack {
                    ProgressView()
                    Text(viewModel.currentStep)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private var ocrResultView: some View {
        if !viewModel.recognizedText.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("OCR Raw Text:")
                    .font(.headline)
                
                TextEditor(text: .constant(viewModel.recognizedText))
                    .frame(minHeight: 150)
                    .border(Color.gray, width: 1)
                    .cornerRadius(8)
            }
        }
    }
    
    @ViewBuilder
    private var apiSectionView: some View {
        if !viewModel.extractedJSON.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Extracted JSON:")
                    .font(.headline)
                
                TextEditor(text: .constant(viewModel.extractedJSON))
                    .frame(minHeight: 200)
                    .border(Color.green, width: 2)
                    .cornerRadius(8)
                Button {
                    UIPasteboard.general.string = viewModel.extractedJSON
                } label: {
                    Label("Copy JSON", systemImage: "doc.on.doc")
                        .font(.caption)
                }
            }
            .padding(.bottom)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Get Recommendation")
                    .font(.title2)
                    .fontWeight(.bold)
                
                TextField("Enter Clothing Type (e.g., blouse)", text: $viewModel.clothingType)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button {
                    // Panggil getRecommendation (sekarang menjalankan fuzzy lokal)
                    viewModel.getRecommendation()
                } label: {
                    Label("2. Get Recommendation", systemImage: "arrow.down.circle.dotted")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.clothingType.isEmpty ? Color.gray : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.clothingType.isEmpty || viewModel.isCallingAPI)
                
                if viewModel.isCallingAPI {
                    ProgressView("Calculating Recommendations...") // Ubah teks
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                
                // Tampilan hasil API (Sekarang menampilkan 5 hasil fuzzy)
                apiResultView
            }
        }
    }
    
    @ViewBuilder
    private var apiResultView: some View {
        // Tampilkan 5 rekomendasi
        if let recommendations = viewModel.serverResponse?.recommendations {
            VStack(alignment: .leading, spacing: 15) {
                Text("Local Fuzzy Recommendations:")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                RecommendationRow(fit: "Regular", recommendation: recommendations.regular)
                Divider()
                RecommendationRow(fit: "Loose", recommendation: recommendations.loose)
                Divider()
                RecommendationRow(fit: "Slightly Loose", recommendation: recommendations.slightlyLoose)
                Divider()
                RecommendationRow(fit: "Slightly Tight", recommendation: recommendations.slightlyTight)
                Divider()
                RecommendationRow(fit: "Tight", recommendation: recommendations.tight)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
        } else if let apiError = viewModel.apiError {
            Text(apiError)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
        }
    }
}

/// Helper view dari RecView.swift, dipindahkan ke sini
private struct RecommendationRow: View {
    let fit: String
    let recommendation: FitRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(fit)
                .font(.headline)
                .foregroundColor(Color.blue)
            
            HStack {
                Text("Best Size:")
                    .fontWeight(.medium)
                Spacer()
                Text(recommendation.bestSize)
                    .font(.system(.body, design: .monospaced))
                    .padding(5)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(5)
            }
            
            HStack {
                Text("Score:")
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.1f%%", recommendation.bestScore))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Part Fits:")
                    .fontWeight(.medium)
                
                if recommendation.partFits.isEmpty {
                    Text("N/A")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    // Sortir keys agar urutan konsisten
                    ForEach(recommendation.partFits.sorted(by: { $0.key < $1.key }), id: \.key) { part, fit in
                        HStack {
                            Text("  • \(part.capitalized):")
                                .font(.caption)
                            Text(fit)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(.top, 2)
        }
    }
}
