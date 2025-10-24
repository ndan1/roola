//
//  OCR.swift
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
    
    var body: some View {
        VStack {
            Text("OCR using Vision")
                .font(.title)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .overlay(
                        Text("No image selected")
                            .foregroundColor(.gray)
                    )
            }
            
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Select from Gallery", systemImage: "photo.on.rectangle")
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
                    }
                }
            }
            
            Button {
                ocr()
            } label: {
                Label("Recognize Text", systemImage: "doc.text.viewfinder")
                    .padding()
                    .background(selectedImage == nil ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedImage == nil || isProcessing)
            
            if isProcessing {
                ProgressView("Processing...")
            }
            
            // Text editor for results
            Text("Recognized Text:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextEditor(text: $recognizedText)
                .frame(minHeight: 150)
                .border(Color.gray, width: 1)
        }
        .padding()
    }
    
    func ocr() {
        guard let image = selectedImage else {
            recognizedText = "Please select an image first"
            return
        }
        
        isProcessing = true
        
        guard let cgImage = image.cgImage else {
            recognizedText = "Failed to process image"
            isProcessing = false
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let recognizeRequest = VNRecognizeTextRequest { (request, error) in
            
            if let error = error {
                DispatchQueue.main.async {
                    recognizedText = "Error: \(error.localizedDescription)"
                    isProcessing = false
                }
                return
            }
            
            guard let results = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    recognizedText = "No text found"
                    isProcessing = false
                }
                return
            }
            
            let stringArray = results.compactMap { result in
                result.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                recognizedText = stringArray.joined(separator: "\n")
                isProcessing = false
            }
        }
        
        recognizeRequest.recognitionLevel = .accurate
        
        do {
            try handler.perform([recognizeRequest])
        } catch {
            DispatchQueue.main.async {
                recognizedText = "Error: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }
}

#Preview {
    OCRView()
}
