//
//  OCRView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 24/10/25.
//

import SwiftUI
import Vision
import PhotosUI

struct OCRView: View {
    
    @State private var recognizedText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var extractedJSON = ""
    @State private var currentStep = ""
    
    private let openAIService = OpenAIService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("OCR + AI Size Extractor")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let image = selectedImage {
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
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                            recognizedText = ""
                            extractedJSON = ""
                            currentStep = ""
                        }
                    }
                }
                
                Button {
                    processImage()
                } label: {
                    Label("Process Image", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedImage == nil ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedImage == nil || isProcessing)
                
                if isProcessing {
                    VStack {
                        ProgressView()
                        Text(currentStep)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                if !recognizedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OCR Raw Text:")
                            .font(.headline)
                        
                        TextEditor(text: .constant(recognizedText))
                            .frame(minHeight: 150)
                            .border(Color.gray, width: 1)
                            .cornerRadius(8)
                    }
                }
                
                if !extractedJSON.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Extracted JSON:")
                            .font(.headline)
                        
                        TextEditor(text: .constant(extractedJSON))
                            .frame(minHeight: 200)
                            .border(Color.green, width: 2)
                            .cornerRadius(8)
                        
                        Button {
                            UIPasteboard.general.string = extractedJSON
                        } label: {
                            Label("Copy JSON", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    func processImage() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        currentStep = "Running OCR..."
        
        Task {
            do {
                let ocrResult = try await performOCR(on: image)
                
                await MainActor.run {
                    recognizedText = ocrResult
                    currentStep = "Sending to OpenAI API..."
                }
                
                print("\n OCR Result:")
                print(ocrResult)
                
                let jsonResult = try await openAIService.extractSizeChart(from: ocrResult)
                
                await MainActor.run {
                    extractedJSON = jsonResult
                    currentStep = ""
                    isProcessing = false
                }
                
                print("\n Final JSON Result:")
                print(jsonResult)
                
            } catch {
                await MainActor.run {
                    recognizedText = "Error: \(error.localizedDescription)"
                    currentStep = ""
                    isProcessing = false
                }
                print("Error: \(error)")
            }
        }
    }
    
    func performOCR(on image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            let recognizeRequest = VNRecognizeTextRequest { (request, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let stringArray = results.compactMap { result in
                    result.topCandidates(1).first?.string
                }
                
                let resultText = stringArray.joined(separator: "\n")
                continuation.resume(returning: resultText)
            }
            
            recognizeRequest.recognitionLevel = .accurate
            
            do {
                try handler.perform([recognizeRequest])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

#Preview {
    OCRView()
}
