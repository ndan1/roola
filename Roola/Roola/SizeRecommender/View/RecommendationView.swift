//
//  RecommendationView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 04/11/25.
//

import SwiftUI
import Vision
import PhotosUI

struct RecommendationView: View {
    
    // 1. Ganti semua @State dengan @StateObject ViewModel
    @StateObject private var viewModel = RecommendationViewModel()
    
    // 2. Hanya sisakan @State untuk PhotosPicker
    @State private var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("OCR + AI Size Extractor")
                    .font(.title)
                    .fontWeight(.bold)
                
                // 3. Panggil sub-view yang membaca dari ViewModel
                imageDisplayView
                
                PhotosPicker(
                    selection: $selectedPhoto, // Tetap pakai @State
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
                    // 4. Panggil fungsi ViewModel
                    viewModel.handlePhotoSelection(newValue)
                }
                
                processButtonView
                
                ocrResultView
                
                apiSectionView
                
            }
            .padding()
            .alert(viewModel.currentError?.title ?? "Error", isPresented: $viewModel.showErrorAlert) {
                Button("Retry", role: .cancel) {
                    // 5. Panggil fungsi ViewModel
                    viewModel.resetAllStates()
                    // Juga reset image picker
                    selectedPhoto = nil
                    viewModel.selectedImage = nil
                }
            } message: {
                Text(viewModel.currentError?.message ?? "")
            }
        }
    }
    
    // MARK: - Sub-Views (Sekarang membaca dari viewModel)
    
    @ViewBuilder
    private var imageDisplayView: some View {
        // 6. Baca dari viewModel.selectedImage
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
                // 7. Panggil viewModel.processImage()
                viewModel.processImage()
            } label: {
                Label("1. Process Image (OCR + AI)", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.selectedImage == nil ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            // 8. Baca state dari viewModel
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
        // 9. Baca dari viewModel.recognizedText
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
        // 10. Baca dari viewModel.extractedJSON
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
                
                // 11. Bind ke viewModel.clothingType
                TextField("Enter Clothing Type (e.g., blouse)", text: $viewModel.clothingType)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button {
                    Task {
                        // 12. Panggil viewModel.getRecommendation()
                        await viewModel.getRecommendation()
                    }
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
                    ProgressView("Getting recommendation...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                
                apiResultView
            }
        }
    }
    
    @ViewBuilder
    private var apiResultView: some View {
        // 13. Baca dari viewModel.serverResponse dan viewModel.apiError
        if let serverResponse = viewModel.serverResponse {
            VStack(alignment: .leading, spacing: 5) {
                Text("API Recommendation Result:")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                let regularRec = serverResponse.recommendations.regular
                Text("Regular Fit: \(regularRec.bestSize)")
                    .font(.body)
                Text("Score: \(String(format: "%.1f", regularRec.bestScore))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                let looseRec = serverResponse.recommendations.loose
                Text("Loose Fit: \(looseRec.bestSize)")
                    .font(.body)
                    .padding(.top, 5)
                Text("Score: \(String(format: "%.1f", looseRec.bestScore))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.1))
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
