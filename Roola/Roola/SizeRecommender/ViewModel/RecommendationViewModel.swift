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
    @Published var serverResponse: ServerResponse? // Kita akan gunakan struct ini untuk hasil lokal
    @Published var apiError: String?
    
    @Published var isProcessing = false
    @Published var isCallingAPI = false // Tetap gunakan ini untuk loading indicator
    @Published var currentStep = ""
    
    @Published var currentError: OCRError?
    @Published var showErrorAlert = false
    
    // MARK: - User Data
    // TODO: Ganti data mock ini dengan data user dari SwiftData/User Model Anda
    @Published var userMeasurements = UserMeasurements(
        bust: 91.0,
        waist: 73.0,
        hips: 100.0,
        shoulderWidth: 37.0,
        torso: 58.0,
        armLength: 55.0
    )
    
    // MARK: - Services
    private let ocrService: LocalOCRService
    private let openAIService: OpenAIService
    // private let recommendationService: RecommendationService // Kita tidak pakai ini untuk fuzzy lokal
    
    init() {
        self.ocrService = LocalOCRService()
        self.openAIService = OpenAIService()
        // self.recommendationService = RecommendationService()
        
        // Di sini Anda bisa memuat self.userMeasurements dari SwiftData
        // loadUserData()
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
    
    /// 2. Mendapatkan rekomendasi (Sekarang menggunakan FUZZY LOKAL)
    func getRecommendation() {
        isCallingAPI = true // Ganti nama state ini nanti jika mau
        apiError = nil
        serverResponse = nil

        // 1. Decode the extracted JSON string
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
        
        // 2. Transform the decoded data into the ClothesData format
        let clothesData = transformOCRResponseToClothesData(
            ocrResponse: ocrResponse,
            clothingType: clothingType
        )
        
        // 3. Panggil kalkulasi FUZZY LOKAL (menggantikan panggilan API)
        calculateLocalRecommendations(
            userMeasurements: self.userMeasurements, // Menggunakan data user dari property
            clothesData: clothesData
        )
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
    
    
    // =================================================================
    // MARK: - FUZZY LOGIC ENGINE (Digabung dari SwiftUIViewModel.swift)
    // =================================================================
    
    private let ALL_FITS = ["tight", "slightly-tight", "regular", "slightly-loose", "loose"]

    /// Titik masuk utama untuk kalkulasi fuzzy lokal
    private func calculateLocalRecommendations(userMeasurements: UserMeasurements, clothesData: ClothesData) {
        
        // 1. Get Config & Validate
        guard let clothesType = clothesData.item.keys.first,
              let config = RECOMMENDER_CONFIG[clothesType] else {
            self.apiError = "No configuration found for clothing type '\(clothesData.item.keys.first ?? "unknown")'."
            self.isCallingAPI = false
            return
        }
        
        guard let sizeChartStructs = clothesData.item[clothesType], !sizeChartStructs.isEmpty else {
            self.apiError = "No size data found for '\(clothesType)'."
            self.isCallingAPI = false
            return
        }

        // 2. Convert Inputs
        let userMeasurementsDict = userMeasurementsToDictionary(userMeasurements)
        let availableSizes = transformSizeChart(sizeChartStructs)
        
        // 3. Run Recommendation for All Fits
        var allRecommendations: [String: FitRecommendation] = [:]

        for fit in ALL_FITS {
            let (bestSize, scores, partFits) = get_size_recommendation(
                user_measurements: userMeasurementsDict,
                clothes_db: availableSizes,
                config: config,
                desired_fit: fit
            )
            
            if let bestSize = bestSize, let bestScore = scores[bestSize] {
                let recommendation = FitRecommendation(
                    bestScore: bestScore,
                    bestSize: bestSize,
                    partFits: partFits
                )
                allRecommendations[fit] = recommendation
            } else {
                print("Could not generate recommendation for fit: \(fit)")
            }
        }
        
        // 4. Assemble Final Struct (ServerResponse)
        guard let loose = allRecommendations["loose"],
              let regular = allRecommendations["regular"],
              let slightlyLoose = allRecommendations["slightly-loose"],
              let slightlyTight = allRecommendations["slightly-tight"],
              let tight = allRecommendations["tight"]
        else {
            self.apiError = "Failed to calculate all required fit profiles. Some recommendations may be missing."
            // Set apa yang kita punya
            self.serverResponse = ServerResponse(
                recommendations: Recommendations(
                    loose: allRecommendations["loose"] ?? .empty,
                    regular: allRecommendations["regular"] ?? .empty,
                    slightlyLoose: allRecommendations["slightly-loose"] ?? .empty,
                    slightlyTight: allRecommendations["slightly-tight"] ?? .empty,
                    tight: allRecommendations["tight"] ?? .empty
                )
            )
            self.isCallingAPI = false
            return
        }
        
        self.serverResponse = ServerResponse(
            recommendations: Recommendations(
                loose: loose,
                regular: regular,
                slightlyLoose: slightlyLoose,
                slightlyTight: slightlyTight,
                tight: tight
            )
        )
        self.isCallingAPI = false
    }

    // MARK: - Ported Python Logic (main.py)
    
    private func get_size_recommendation(
        user_measurements: [String: Double],
        clothes_db: [String: [String: [Double]]],
        config: ClothingConfig,
        desired_fit: String
    ) -> (best_size: String?, scores: [String: Double], part_fits: [String: String]) {
        
        var sizeScores: [String: Double] = [:]

        for (size, garmentRanges) in clothes_db {
            var partScores: [String: Double] = [:]

            for partConfig in config.relevantParts {
                let part = partConfig.partName
                
                guard let userMeas = user_measurements[part],
                      let garmentRange = garmentRanges[part], garmentRange.count == 2 else {
                    continue
                }
                
                let gMin = garmentRange[0]
                let gMax = garmentRange[1]

                let effectiveEase = _calculate_effective_ease(
                    user_meas: userMeas,
                    g_min: gMin,
                    g_max: gMax,
                    part_config: partConfig,
                    desired_fit: desired_fit
                )
                
                guard let desiredFitParams = partConfig.fitFunctions[desired_fit] else {
                    continue
                }
                
                let score = interpretTrapezoidalMembership(x: effectiveEase, params: desiredFitParams) * 100
                partScores[part] = score
            }

            if partScores.isEmpty {
                continue
            }

            let partWeights = config.partWeights
            var overallScore: Double = 0
            var totalWeight: Double = 0
            
            for (part, score) in partScores {
                if let weight = partWeights[part] {
                    overallScore += score * weight
                    totalWeight += weight
                }
            }
            
            sizeScores[size] = totalWeight > 0 ? (overallScore / totalWeight) : 0
        }

        if sizeScores.isEmpty {
            return (nil, [:], [:])
        }

        let bestSize = sizeScores.max(by: { $0.value < $1.value })?.key
        
        var partFits: [String: String] = [:]
        if let bestSize = bestSize, let bestSizeGarmentRanges = clothes_db[bestSize] {
            partFits = _get_part_fit_details(
                user_measurements: user_measurements,
                best_size_garment_ranges: bestSizeGarmentRanges,
                config: config
            )
        }
        
        return (best_size: bestSize, scores: sizeScores, part_fits: partFits)
    }

    private func _calculate_effective_ease(
        user_meas: Double,
        g_min: Double,
        g_max: Double,
        part_config: RelevantPart,
        desired_fit: String
    ) -> Double {
        
        if g_min == g_max {
            return g_min - user_meas
        }
        else {
            if user_meas < g_min {
                return g_min - user_meas
            }
            else if user_meas > g_max {
                return g_max - user_meas
            }
            else {
                guard let fitParams = part_config.fitFunctions[desired_fit], fitParams.count == 4,
                      let tightParams = part_config.fitFunctions["tight"], tightParams.count == 4 else {
                    return ((g_min + g_max) / 2) - user_meas
                }
                
                let idealEase = (fitParams[1] + fitParams[2]) / 2
                let tightEase = (tightParams[1] + tightParams[2]) / 2
                
                let midpoint = (g_min + g_max) / 2
                let maxDeviation = (g_max - g_min) / 2
                let deviation = abs(user_meas - midpoint)
                let deviationRatio = maxDeviation > 0 ? (deviation / maxDeviation) : 0
                
                let effectiveEase = idealEase + deviationRatio * (tightEase - idealEase)
                return effectiveEase
            }
        }
    }

    private func _get_part_fit_details(
        user_measurements: [String: Double],
        best_size_garment_ranges: [String: [Double]],
        config: ClothingConfig
    ) -> [String: String] {
        
        var partDetails: [String: String] = [:]
        
        for partConfig in config.relevantParts {
            let part = partConfig.partName
            
            guard let userMeas = user_measurements[part],
                  let garmentRange = best_size_garment_ranges[part], garmentRange.count == 2 else {
                continue
            }
            
            let (g_min, g_max) = (garmentRange[0], garmentRange[1])
            
            let actualEase: Double
            if g_min == g_max {
                actualEase = g_min - userMeas
            } else {
                if userMeas < g_min {
                    actualEase = g_min - userMeas
                } else {
                    let midpoint = (g_min + g_max) / 2
                    actualEase = midpoint - userMeas
                }
            }
            
            var bestFitName: String? = nil
            var maxMembership: Double = -1.0

            for (fitName, fitParams) in partConfig.fitFunctions {
                let membership = interpretTrapezoidalMembership(x: actualEase, params: fitParams)
                if membership > maxMembership {
                    maxMembership = membership
                    bestFitName = fitName
                }
            }
            
            if let bestFitName = bestFitName {
                partDetails[part] = bestFitName
            }
        }
        return partDetails
    }
    
    // MARK: - Data Transformation Helpers
    
    private func userMeasurementsToDictionary(_ measurements: UserMeasurements) -> [String: Double] {
        return [
            "bust": measurements.bust,
            "waist": measurements.waist,
            "hips": measurements.hips,
            "shoulder_width": measurements.shoulderWidth,
            "torso": measurements.torso,
            "arm_length": measurements.armLength
        ].compactMapValues { $0 }
    }
    
    private func transformSizeChart(_ sizeChart: [String: SizeMeasurements]) -> [String: [String: [Double]]] {
        var transformedChart = [String: [String: [Double]]]()
        
        for (sizeName, measurements) in sizeChart {
            var partRanges = [String: [Double]]()
            
            partRanges["torso"] = measurements.torso
            partRanges["bust"] = measurements.bust
            
            if let armLength = measurements.armLength {
                partRanges["arm_length"] = armLength
            }
            if let waist = measurements.waist {
                partRanges["waist"] = waist
            }
            
            transformedChart[sizeName] = partRanges
        }
        
        return transformedChart
    }
}

// MARK: - Fuzzy Logic Configuration (from config.json)

fileprivate struct ClothingConfig {
    let partWeights: [String: Double]
    let relevantParts: [RelevantPart]
}

fileprivate struct RelevantPart {
    let partName: String
    let easeUniverse: [Double]
    let fitFunctions: [String: [Double]]
}

fileprivate let RECOMMENDER_CONFIG: [String: ClothingConfig] = [
    "t_shirt": ClothingConfig(
        partWeights: [ "bust": 0.6, "torso": 0.4 ],
        relevantParts: [
            RelevantPart(
                partName: "bust",
                easeUniverse: [-10, 41, 1],
                fitFunctions: [
                    "tight": [-10, -5, -2, 0],
                    "slightly-tight": [-2, 0, 2, 4],
                    "regular": [0, 2, 4, 8],
                    "slightly-loose": [6, 10, 16, 20],
                    "loose": [18, 20, 41, 41]
                ]
            ),
            RelevantPart(
                partName: "torso",
                easeUniverse: [-10, 21, 1],
                fitFunctions: [
                    "tight": [-10, -10, -5, -4],
                    "slightly-tight": [-5, -4, 0, 1],
                    "regular": [0, 1, 5, 6],
                    "slightly-loose": [5, 6, 10, 12],
                    "loose": [10, 13, 21, 21]
                ]
            )
        ]
    ),
    "blouse": ClothingConfig( // Config yang Anda gunakan di mock data
        partWeights: [
            "bust": 0.5,
            "torso": 0.3,
            "shoulder_width": 0,
            "arm_length": 0.2
        ],
        relevantParts: [
            RelevantPart(
                partName: "bust",
                easeUniverse: [-10, 41, 1],
                fitFunctions: [
                    "tight": [-10, -5, -2, 0],
                    "slightly-tight": [-2, 0, 2, 6],
                    "regular": [4, 6, 10, 12],
                    "slightly-loose": [10, 14, 16, 20],
                    "loose": [18, 20, 41, 41]
                ]
            ),
            RelevantPart(
                partName: "torso",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-10, -10, -5, -4],
                    "slightly-tight": [-5, -4, 0, 1],
                    "regular": [0, 1, 5, 6],
                    "slightly-loose": [5, 6, 10, 12],
                    "loose": [10, 13, 21, 21]
                ]
            ),
            RelevantPart(
                partName: "arm_length",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-5, -5, -5, -2],
                    "slightly-tight": [-2, -1, 0, 1],
                    "regular": [0, 1, 2, 3],
                    "slightly-loose": [2, 3, 4, 5],
                    "loose": [4, 5, 21, 21]
                ]
            )
        ]
    ),
    "long_sleeved_shirt": ClothingConfig(
        partWeights: [
            "bust": 0.5,
            "torso": 0.3,
            "shoulder_width": 0,
            "arm_length": 0.2
        ],
        relevantParts: [
            RelevantPart(
                partName: "bust",
                easeUniverse: [-10, 41, 1],
                fitFunctions: [
                    "tight": [-10, -5, -2, 0],
                    "slightly-tight": [-2, 0, 2, 4],
                    "regular": [0, 2, 4, 8],
                    "slightly-loose": [6, 10, 16, 20],
                    "loose": [18, 20, 41, 41]
                ]
            ),
            RelevantPart(
                partName: "torso",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-10, -10, -5, -4],
                    "slightly-tight": [-5, -4, 0, 1],
                    "regular": [0, 1, 5, 6],
                    "slightly-loose": [5, 6, 10, 12],
                    "loose": [10, 13, 21, 21]
                ]
            ),
            RelevantPart(
                partName: "arm_length",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-5, -5, -5, -2],
                    "slightly-tight": [-2, -1, 0, 1],
                    "regular": [0, 1, 2, 3],
                    "slightly-loose": [2, 3, 4, 5],
                    "loose": [4, 5, 21, 21]
                ]
            )
        ]
    ),
    "short_sleeved_shirt": ClothingConfig(
        partWeights: [
            "bust": 0.6,
            "torso": 0.4
        ],
        relevantParts: [
            RelevantPart(
                partName: "bust",
                easeUniverse: [-10, 41, 1],
                fitFunctions: [
                    "tight": [-10, -5, -2, 0],
                    "slightly-tight": [-2, 0, 2, 4],
                    "regular": [0, 2, 4, 8],
                    "slightly-loose": [6, 10, 16, 20],
                    "loose": [18, 20, 41, 41]
                ]
            ),
            RelevantPart(
                partName: "torso",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-10, -10, -5, -4],
                    "slightly-tight": [-5, -4, 0, 1],
                    "regular": [0, 1, 5, 6],
                    "slightly-loose": [5, 6, 10, 12],
                    "loose": [10, 13, 21, 21]
                ]
            )
        ]
    ),
    // Tambahkan config lain (short_sleeved_shirt, etc.) di sini
]


// MARK: - Fuzzy Logic Helpers (Ported from skfuzzy)

fileprivate func interpretTrapezoidalMembership(x: Double, params: [Double]) -> Double {
    guard params.count == 4 else { return 0.0 }
    let (a, b, c, d) = (params[0], params[1], params[2], params[3])

    if x <= a || x >= d { return 0.0 }
    if x >= b && x <= c { return 1.0 }
    if x > a && x < b { return (x - a) / (b - a) }
    if x > c && x < d { return (d - x) / (d - c) }
    return 0.0
}

// MARK: - Helper Extension

extension FitRecommendation {
    static var empty: FitRecommendation {
        FitRecommendation(bestScore: 0, bestSize: "N/A", partFits: [:])
    }
}
