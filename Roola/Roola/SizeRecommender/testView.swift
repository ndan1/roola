////
////  testView.swift
////  Roola
////
////  Created by Hendrik Nicolas Carlo on 27/10/25.
////
//
//
//import SwiftUI
//import Vision
//import PhotosUI
//
//// MARK: - Structs for Decoding AI JSON
//// These structs match the new JSON format you expect from the AI
//struct OCRResponse: Codable {
//    let sizes: [SizeDetail]
//}
//
//struct SizeDetail: Codable {
//    let size: String
//    let clothesTorsoMin: Double
//    let clothesTorsoMax: Double
//    let clothesBustMin: Double
//    let clothesBustMax: Double
//    let clothesArmMin: Double?
//    let clothesArmMax: Double?
//    let clothesWaistMin: Double?
//    let clothesWaistMax: Double?
//
//    enum CodingKeys: String, CodingKey {
//        case size
//        case clothesTorsoMin = "clothes_torso_min"
//        case clothesTorsoMax = "clothes_torso_max"
//        case clothesBustMin = "clothes_bust_min"
//        case clothesBustMax = "clothes_bust_max"
//        case clothesArmMin = "clothes_arm_min"
//        case clothesArmMax = "clothes_arm_max"
//        case clothesWaistMin = "clothes_waist_min"
//        case clothesWaistMax = "clothes_waist_max"
//    }
//}
//
//
//struct TestOcrView: View {
//    
//    @State private var recognizedText = ""
//    @State private var selectedPhoto: PhotosPickerItem?
//    @State private var selectedImage: UIImage?
//    @State private var isProcessing = false
//    @State private var extractedJSON = ""
//    @State private var currentStep = ""
//    
//    // States for API Call
//    @State private var clothingType: String = "blouse"
//    @State private var isCallingAPI = false
//    @State private var serverResponse: ServerResponse?
//    @State private var apiError: String?
//    
//    @State private var showErrorAlert = false
//    @State private var currentError: OCRError?
//    
//    enum OCRError: Error, LocalizedError {
//        case invalidImage
//        case recognitionFailed
//        case noSizeDataFound
//        case noTextFound
//        case notUpperwear
//        case noSizeChartDetected
//        
//        var title: String {
//            switch self {
//            case .invalidImage, .noTextFound, .recognitionFailed, .noSizeDataFound:
//                return "Error"
//            case .notUpperwear, .noSizeChartDetected:
//                return "Uh Oh!"
//            }
//        }
//        
//        var message: String {
//            switch self {
//            case .invalidImage:
//                return "Invalid image format"
//            case .recognitionFailed:
//                return "Failed to recognize text from image"
//            case .noSizeDataFound:
//                return "No size data found in the image"
//            case .noTextFound:
//                return "No text found in image"
//            case .notUpperwear:
//                return "Size chart uploaded wasn't an upperwear!"
//            case .noSizeChartDetected:
//                return "There wasn't any size chart in the screenshot"
//            }
//        }
//        
//        var errorDescription: String? {
//            return message
//        }
//    }
//    
//    private let openAIService = OpenAIService()
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                Text("OCR + AI Size Extractor")
//                    .font(.title)
//                    .fontWeight(.bold)
//                
//                imageDisplayView
//                
//                PhotosPicker(
//                    selection: $selectedPhoto,
//                    matching: .images,
//                    photoLibrary: .shared()
//                ) {
//                    Label("Select from Gallery", systemImage: "photo.on.rectangle")
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//                .onChange(of: selectedPhoto) { oldValue, newValue in
//                    handlePhotoSelection(newValue)
//                }
//                
//                processButtonView
//                
//                ocrResultView
//                
//                apiSectionView
//                
//            }
//            .padding()
//            .alert(currentError?.title ?? "Error", isPresented: $showErrorAlert) {
//                Button("Retry", role: .cancel) {
//                    resetAllStates()
//                }
//            } message: {
//                Text(currentError?.message ?? "")
//            }
//        }
//    }
//    
//    @ViewBuilder
//    private var imageDisplayView: some View {
//        if let image = selectedImage {
//            Image(uiImage: image)
//                .resizable()
//                .scaledToFit()
//                .frame(maxHeight: 300)
//                .cornerRadius(12)
//                .shadow(radius: 5)
//        } else {
//            Rectangle()
//                .fill(Color.gray.opacity(0.3))
//                .frame(height: 300)
//                .cornerRadius(12)
//                .overlay(
//                    VStack {
//                        Image(systemName: "photo.badge.plus")
//                            .font(.system(size: 50))
//                            .foregroundColor(.gray)
//                        Text("No image selected")
//                            .foregroundColor(.gray)
//                            .font(.headline)
//                    }
//                )
//        }
//    }
//    
//    private var processButtonView: some View {
//        VStack {
//            Button {
//                processImage()
//            } label: {
//                Label("1. Process Image (OCR + AI)", systemImage: "wand.and.stars")
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(selectedImage == nil ? Color.gray : Color.green)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
//            .disabled(selectedImage == nil || isProcessing)
//            
//            if isProcessing {
//                VStack {
//                    ProgressView()
//                    Text(currentStep)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                .padding()
//            }
//        }
//    }
//    
//    @ViewBuilder
//    private var ocrResultView: some View {
//        if !recognizedText.isEmpty {
//            VStack(alignment: .leading, spacing: 8) {
//                Text("OCR Raw Text:")
//                    .font(.headline)
//                
//                TextEditor(text: .constant(recognizedText))
//                    .frame(minHeight: 150)
//                    .border(Color.gray, width: 1)
//                    .cornerRadius(8)
//            }
//        }
//    }
//    
//    @ViewBuilder
//    private var apiSectionView: some View {
//        if !extractedJSON.isEmpty {
//            VStack(alignment: .leading, spacing: 8) {
//                Text("AI Extracted JSON:")
//                    .font(.headline)
//                
//                TextEditor(text: .constant(extractedJSON))
//                    .frame(minHeight: 200)
//                    .border(Color.green, width: 2)
//                    .cornerRadius(8)
//                Button {
//                    UIPasteboard.general.string = extractedJSON
//                } label: {
//                    Label("Copy JSON", systemImage: "doc.on.doc")
//                        .font(.caption)
//                }
//            }
//            .padding(.bottom)
//            
//            Divider()
//            
//            VStack(alignment: .leading, spacing: 10) {
//                Text("Get Recommendation")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                
//                TextField("Enter Clothing Type (e.g., blouse)", text: $clothingType)
//                    .textFieldStyle(.roundedBorder)
//                    .autocapitalization(.none)
//                    .disableAutocorrection(true)
//                
//                Button {
//                    Task {
//                        await getRecommendation()
//                    }
//                } label: {
//                    Label("2. Get Recommendation", systemImage: "arrow.down.circle.dotted")
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(clothingType.isEmpty ? Color.gray : Color.orange)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//                .disabled(clothingType.isEmpty || isCallingAPI)
//                
//                if isCallingAPI {
//                    ProgressView("Getting recommendation...")
//                        .frame(maxWidth: .infinity, alignment: .center)
//                        .padding()
//                }
//                
//                apiResultView
//            }
//        }
//    }
//    
//    @ViewBuilder
//    private var apiResultView: some View {
//        if let serverResponse {
//            VStack(alignment: .leading, spacing: 5) {
//                Text("API Recommendation Result:")
//                    .font(.headline)
//                    .padding(.bottom, 5)
//                
//                let regularRec = serverResponse.recommendations.regular
//                Text("Regular Fit: \(regularRec.bestSize)")
//                    .font(.body)
//                Text("Score: \(String(format: "%.1f", regularRec.bestScore))")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                let looseRec = serverResponse.recommendations.loose
//                Text("Loose Fit: \(looseRec.bestSize)")
//                    .font(.body)
//                    .padding(.top, 5)
//                Text("Score: \(String(format: "%.1f", looseRec.bestScore))")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//            .padding()
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .background(Color.green.opacity(0.1))
//            .cornerRadius(10)
//            
//        } else if let apiError {
//            Text(apiError)
//                .foregroundColor(.red)
//                .multilineTextAlignment(.center)
//                .padding()
//                .frame(maxWidth: .infinity, alignment: .center)
//                .background(Color.red.opacity(0.1))
//                .cornerRadius(10)
//        }
//    }
//    
//    /// Meng-handle pemilihan foto baru
//    private func handlePhotoSelection(_ newValue: PhotosPickerItem?) {
//        Task {
//            if let data = try? await newValue?.loadTransferable(type: Data.self),
//               let uiImage = UIImage(data: data) {
//                selectedImage = uiImage
//                // Reset everything on new image
//                resetAllStates()
//            }
//        }
//    }
//    
//    /// Mereset semua state
//    private func resetAllStates() {
//        selectedPhoto = nil // Hapus item picker agar bisa pilih ulang
//        recognizedText = ""
//        extractedJSON = ""
//        currentStep = ""
//        serverResponse = nil
//        apiError = nil
//        currentError = nil
//    }
//    
//    
//    // MARK: - OCR Function
//    
//    func processImage() {
//        guard let image = selectedImage else { return }
//        
//        isProcessing = true
//        currentStep = "Running OCR..."
//        
//        // Clear previous results
//        serverResponse = nil
//        apiError = nil
//        
//        Task {
//            do {
//                let ocrResult = try await performOCR(on: image)
//                
//                await MainActor.run {
//                    recognizedText = ocrResult
//                    currentStep = "Validating size chart..."
//                }
//                
//                print("\n📝 OCR Result:")
//                print(ocrResult)
//                
//                try await validateOCRText(ocrResult)
//                
//                await MainActor.run {
//                    currentStep = "Sending to OpenAI API..."
//                }
//                
//                let jsonResult = try await openAIService.extractSizeChart(from: ocrResult)
//                
//                await MainActor.run {
//                    extractedJSON = jsonResult
//                    currentStep = ""
//                    isProcessing = false
//                }
//
//                print("\n✅ Final JSON Result:")
//                print(jsonResult)
//                
//            } catch let error as OCRError {
//                // Handle specific OCR errors
//                await MainActor.run {
//                    recognizedText = "Error: \(error.localizedDescription)"
//                    currentStep = ""
//                    isProcessing = false
//                    currentError = error
//                    showErrorAlert = true
//                }
//            } catch {
//                await MainActor.run {
//                    recognizedText = "Error: \(error.localizedDescription)"
//                    currentError = .noTextFound
//                    showErrorAlert = true
//                    currentStep = ""
//                    isProcessing = false
//                }
//                print("❌ Error: \(error)")
//            }
//        }
//    }
//    
//    func performOCR(on image: UIImage) async throws -> String {
//        guard let cgImage = image.cgImage else {
//            throw OCRError.invalidImage
//        }
//        
//        return try await withCheckedThrowingContinuation { continuation in
//            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//            
//            let recognizeRequest = VNRecognizeTextRequest { (request, error) in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                    return
//                }
//                
//                guard let results = request.results as? [VNRecognizedTextObservation] else {
//                    continuation.resume(throwing: OCRError.noTextFound)
//                    return
//                }
//                
//                let stringArray = results.compactMap { result in
//                    result.topCandidates(1).first?.string
//                }
//                
//                let resultText = stringArray.joined(separator: "\n")
//                continuation.resume(returning: resultText)
//            }
//            
//            recognizeRequest.recognitionLevel = .accurate
//            
//            do {
//                try handler.perform([recognizeRequest])
//            } catch {
//                continuation.resume(throwing: error)
//            }
//        }
//    }
//    
//    // MARK: - Validation Function
//    
//    func validateOCRText(_ text: String) async throws {
//        let lowercasedText = text.lowercased()
//        
//        let bottomWearPatterns = [
//            "panjang celana", "lingkar paha", "panjang bawahan", "inseam",
//            "lingkar pinggang celana", "panjang kaki", "leg length",
//            "thigh circumference", "pants length", "celana panjang", "celana pendek"
//        ]
//        
//        for pattern in bottomWearPatterns {
//            if lowercasedText.contains(pattern) {
//                print("❌ Detected bottom wear keyword: \(pattern)")
//                throw OCRError.notUpperwear
//            }
//        }
//        
//        let sizeChartIndicators = [
//            "size", "ukuran", "chest", "bust", "dada", "length", "panjang",
//            "shoulder", "bahu", "torso", "sleeve", "lengan", "waist", "pinggang", "cm", "inch"
//        ]
//        
//        let sizeLabels = ["xs", "s", "m", "l", "xl", "xxl"]
//        
//        var hasIndicator = false
//        var hasSizeLabel = false
//        
//        for indicator in sizeChartIndicators {
//            if lowercasedText.contains(indicator) {
//                hasIndicator = true
//                break
//            }
//        }
//        
//        for label in sizeLabels {
//            let pattern = "\\b\(label)\\b"
//            if lowercasedText.range(of: pattern, options: .regularExpression) != nil {
//                hasSizeLabel = true
//                break
//            }
//        }
//        
//        if !hasIndicator || !hasSizeLabel {
//            print("❌ No size chart detected. hasIndicator: \(hasIndicator), hasSizeLabel: \(hasSizeLabel)")
//            throw OCRError.noSizeChartDetected
//        }
//        
//        print("✅ Size chart validation passed")
//    }
//    
//    // MARK: - API Call Functions
//    
//    func getRecommendation() async {
//        isCallingAPI = true
//        apiError = nil
//        serverResponse = nil
//
//        guard let jsonData = extractedJSON.data(using: .utf8) else {
//            apiError = "Failed to read JSON data."
//            isCallingAPI = false
//            return
//        }
//        
//        let ocrResponse: OCRResponse
//        do {
//            let decoder = JSONDecoder()
//            ocrResponse = try decoder.decode(OCRResponse.self, from: jsonData)
//        } catch {
//            apiError = "Failed to parse AI JSON. Check format. \nError: \(error.localizedDescription)"
//            isCallingAPI = false
//            return
//        }
//        
//        let clothesData = transformOCRResponseToClothesData(
//            ocrResponse: ocrResponse,
//            clothingType: clothingType
//        )
//        
//        // TODO: Replace this with dynamic user data
//        let userMeasurements = UserMeasurements(
//            bust: 91.0, waist: 73.0, hips: 100.0,
//            shoulderWidth: 37.0, torso: 58.0, armLength: 55.0
//        )
//        
//        do {
//            let response = try await fetchRecommendations_(
//                userMeasurements: userMeasurements,
//                clothesData: clothesData
//            )
//            await MainActor.run {
//                serverResponse = response
//            }
//        } catch {
//            await MainActor.run {
//                apiError = "API Error: \(error.localizedDescription)"
//            }
//        }
//        
//        await MainActor.run {
//            isCallingAPI = false
//        }
//    }
//    
//    private func transformOCRResponseToClothesData(ocrResponse: OCRResponse, clothingType: String) -> ClothesData {
//        var sizeChart = [String: SizeMeasurements]()
//        
//        for detail in ocrResponse.sizes {
//            let torso = [detail.clothesTorsoMin, detail.clothesTorsoMax]
//            let bust = [detail.clothesBustMin, detail.clothesBustMax]
//            
//            let armLength: [Double]?
//            if let min = detail.clothesArmMin, let max = detail.clothesArmMax {
//                armLength = (min == 0 && max == 0) ? nil : [min, max]
//            } else {
//                armLength = nil
//            }
//
//            let waist: [Double]?
//            if let min = detail.clothesWaistMin, let max = detail.clothesWaistMax {
//                waist = (min == 0 && max == 0) ? nil : [min, max]
//            } else {
//                waist = nil
//            }
//
//            let measurements = SizeMeasurements(
//                torso: torso,
//                bust: bust,
//                armLength: armLength,
//                waist: waist
//            )
//            
//            sizeChart[detail.size] = measurements
//        }
//        
//        let itemDictionary = [clothingType: sizeChart]
//        return ClothesData(item: itemDictionary)
//    }
//
//}
//
//// MARK: - Network Function (dari file lain, biarkan di sini)
//// (Fungsi fetchRecommendations_ Anda tetap sama)
//func fetchRecommendations_(userMeasurements: UserMeasurements, clothesData: ClothesData) async throws -> ServerResponse {
//    let urlString = "http://127.0.0.1:5001/recommend"
//    
//    guard let url = URL(string: urlString) else {
//        print("Error: Invalid URL")
//        throw URLError(.badURL)
//    }
//    
//    let requestBody: Data
//    do {
//        let requestData = RequestBody(userMeasurements: userMeasurements, clothesData: clothesData)
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
//        requestBody = try encoder.encode(requestData)
//        
//        if let jsonString = String(data: requestBody, encoding: .utf8) {
//            print("Request JSON:\n\(jsonString)")
//        } else {
//            print("Error: Could not convert requestBody to string for debugging")
//        }
//        
//    } catch {
//        print("Error: Failed to encode JSON: \(error)")
//        throw error
//    }
//    
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    request.httpBody = requestBody
//    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//    print("Sending request to \(urlString)...")
//    
//    do {
//        let (data, response) = try await URLSession.shared.data(for: request)
//        
//        if let httpResponse = response as? HTTPURLResponse {
//            print("Response Status Code: \(httpResponse.statusCode)")
//            if let responseString = String(data: data, encoding: .utf8) {
//                print("Response JSON:\n\(responseString)")
//            } else {
//                print("Error: Could not convert response data to string for debugging")
//            }
//            
//            guard (200...299).contains(httpResponse.statusCode) else {
//                print("Server Error: Status code \(httpResponse.statusCode)")
//                throw URLError(.badServerResponse)
//            }
//        }
//        
//        let decoder = JSONDecoder()
//        let serverResponse = try decoder.decode(ServerResponse.self, from: data)
//        print("Successfully decoded response.")
//        
//        return serverResponse
//        
//    } catch {
//        print("Error: Network request or decoding failed: \(error)")
//        throw error
//    }
//}
