//
//  RecommendationViewModel.swift
//  Roola
//
//  Created by Lin Dan Christiano on 04/11/25.
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor // Memastikan semua perubahan properti terjadi di Main Thread
class RecommendationViewModel: ObservableObject {
    
    // MARK: - Published Properties (State untuk UI)
    @Published var selectedImage: UIImage?
    @Published var recognizedText = ""
    @Published var extractedJSON = ""
    @Published var clothingType: String = "blouse"
    @Published var serverResponse: ServerResponse?
    @Published var apiError: String?
    
    @Published var isProcessing = false
    @Published var isCallingAPI = false
    @Published var currentStep = ""
    
    @Published var currentError: OCRError?
    @Published var showErrorAlert = false
    
    // MARK: - Services
    private let ocrService: LocalOCRService
    private let openAIService: OpenAIService
    private let recommendationService: RecommendationService
    
    init() {
        self.ocrService = LocalOCRService()
        self.openAIService = OpenAIService()
        self.recommendationService = RecommendationService()
        // (Pastikan OpenAIService() ada dan bisa di-init)
    }
    
    // MARK: - Public Functions (Dipanggil oleh View)
    
    /// Meng-handle pemilihan foto baru
    func handlePhotoSelection(_ newValue: PhotosPickerItem?) {
        Task {
            if let data = try? await newValue?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                self.selectedImage = uiImage
                // Reset everything on new image
                resetAllStates()
            }
        }
    }
    
    /// Mereset semua state
    func resetAllStates() {
        // selectedPhoto di-handle di View
        recognizedText = ""
        extractedJSON = ""
        currentStep = ""
        serverResponse = nil
        apiError = nil
        currentError = nil
    }
    
    /// 1. Menjalankan OCR dan ekstraksi AI
    func processImage() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        currentStep = "Running OCR..."
        serverResponse = nil
        apiError = nil
        
        Task {
            do {
                let ocrResult = try await ocrService.performOCR(on: image)
                
                self.recognizedText = ocrResult
                self.currentStep = "Validating size chart..."
                
                print("\n📝 OCR Result:")
                print(ocrResult)
                
                try await ocrService.validateOCRText(ocrResult)
                
                self.currentStep = "Sending to OpenAI API..."
                
                let jsonResult = try await openAIService.extractSizeChart(from: ocrResult)
                
                self.extractedJSON = jsonResult
                self.currentStep = ""
                self.isProcessing = false

                print("\n✅ Final JSON Result:")
                print(jsonResult)
                
            } catch let error as OCRError {
                handleError(error)
            } catch {
                handleError(OCRError.recognitionFailed) // Error umum
                print("❌ Error: \(error)")
            }
        }
    }
    
    /// 2. Mendapatkan rekomendasi dari API
    func getRecommendation() async {
        isCallingAPI = true
        apiError = nil
        serverResponse = nil

        guard let jsonData = extractedJSON.data(using: .utf8) else {
            apiError = "Failed to read JSON data."
            isCallingAPI = false
            return
        }
        
        let ocrResponse: OCRResponse
        do {
            let decoder = JSONDecoder()
            ocrResponse = try decoder.decode(OCRResponse.self, from: jsonData)
        } catch {
            apiError = "Failed to parse AI JSON. Check format. \nError: \(error.localizedDescription)"
            isCallingAPI = false
            return
        }
        
        let clothesData = transformOCRResponseToClothesData(
            ocrResponse: ocrResponse,
            clothingType: clothingType
        )
        
        // TODO: Ganti ini dengan data user yang dinamis
        let userMeasurements = UserMeasurements(
            bust: 91.0, waist: 73.0, hips: 100.0,
            shoulderWidth: 37.0, torso: 58.0, armLength: 55.0
        )
        
        do {
            let response = try await recommendationService.fetchRecommendations(
                userMeasurements: userMeasurements,
                clothesData: clothesData
            )
            self.serverResponse = response
        } catch {
            self.apiError = "API Error: \(error.localizedDescription)"
        }
        
        self.isCallingAPI = false
    }
    
    // MARK: - Private Helper Functions
    
    private func handleError(_ error: OCRError) {
        recognizedText = "Error: \(error.localizedDescription)"
        currentStep = ""
        isProcessing = false
        currentError = error
        showErrorAlert = true
    }
    
    private func transformOCRResponseToClothesData(ocrResponse: OCRResponse, clothingType: String) -> ClothesData {
        var sizeChart = [String: SizeMeasurements]()
        
        for detail in ocrResponse.sizes {
            let torso = [detail.clothesTorsoMin, detail.clothesTorsoMax]
            let bust = [detail.clothesBustMin, detail.clothesBustMax]
            
            let armLength: [Double]?
            if let min = detail.clothesArmMin, let max = detail.clothesArmMax {
                armLength = (min == 0 && max == 0) ? nil : [min, max]
            } else {
                armLength = nil
            }

            let waist: [Double]?
            if let min = detail.clothesWaistMin, let max = detail.clothesWaistMax {
                waist = (min == 0 && max == 0) ? nil : [min, max]
            } else {
                waist = nil
            }

            let measurements = SizeMeasurements(
                torso: torso,
                bust: bust,
                armLength: armLength,
                waist: waist
            )
            
            sizeChart[detail.size] = measurements
        }
        
        let itemDictionary = [clothingType: sizeChart]
        return ClothesData(item: itemDictionary)
    }
}
