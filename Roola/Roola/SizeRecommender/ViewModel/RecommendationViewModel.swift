//
//  RecommendationViewModel.swift
//  Roola
//
//  Created by Lin Dan Christiano on 04/11/25.
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
class RecommendationViewModel: ObservableObject {
    
    // MARK: - Published Properties (State untuk UI)
    @Published var selectedImage: UIImage?
    @Published var recognizedText = ""
    @Published var extractedJSON = ""
    @Published var clothingType: String = ""
    @Published var serverResponse: ServerResponse?
    @Published var apiError: String?
    
    @Published var isProcessing = false
    @Published var isCallingAPI = false
    @Published var currentStep = ""
    
    @Published var currentError: OCRError?
    @Published var showErrorAlert = false
    
    // MARK: - User Data
    @Published var userMeasurements: UserMeasurements?
    
    // MARK: - Services
    private let ocrService: LocalOCRService
//    private let openAIService: OpenAIService
    private let geminiService: GeminiService
    
    private let ALL_FITS = ["tight", "slightly-tight", "regular", "slightly-loose", "loose"]
    
    // MINIMUM SCORE THRESHOLD - Rekomendasi harus punya score minimal 30%
    private let MIN_ACCEPTABLE_SCORE = 30.0

    init() {
        self.ocrService = LocalOCRService()
//        self.openAIService = OpenAIService()
        self.geminiService = GeminiService()
    }
    
    // load user data
    func loadUserMeasurements(user: User) {
        self.userMeasurements = UserMeasurements(
            bust: Double(user.bust),
            waist: Double(user.waist),
            hips: Double(user.hips),
            shoulderWidth: Double(user.shoulder_width),
            torso: Double(user.torso),
            armLength: Double(user.arms_length)
        )
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
                
                self.currentStep = "Sending to Gemini API..."
                
                let jsonResult = try await geminiService.extractSizeChart(from: ocrResult)
                
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
        // Pastikan data user sudah dimuat
        guard let userMeasurements = userMeasurements else {
            apiError = "User measurements not available. Please check your profile."
            isCallingAPI = false
            return
        }
        
        isCallingAPI = true
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
        
        // 2. Transform the decoded data
        let clothesData = transformOCRResponseToClothesData(
            ocrResponse: ocrResponse,
            clothingType: clothingType
        )
        
        // 3. Panggil kalkulasi FUZZY LOKAL
        calculateLocalRecommendations(
            userMeasurements: userMeasurements,
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
            
            var bustMin = detail.clothesBustMin
            var bustMax = detail.clothesBustMax
            
            // Jika bustMin < 65, asumsikan ini adalah 'lebar dada' (half-bust)
            // dan kalikan 2 untuk mendapatkan 'lingkar dada' (full bust).
            if bustMin < 65.0 {
                bustMin *= 2
                bustMax *= 2
            }
            
            let bust = [bustMin, bustMax]

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
    // MARK: - FUZZY LOGIC ENGINE
    // =================================================================
    
    /// Titik masuk utama untuk kalkulasi fuzzy lokal
    private func calculateLocalRecommendations(userMeasurements: UserMeasurements, clothesData: ClothesData) {
        
        // 1. Get Config & Validate
        guard let clothesType = clothesData.item.keys.first, !clothesType.isEmpty,
              let config = RECOMMENDER_CONFIG[clothesType] else {
            self.apiError = "No configuration found for clothing type '\(clothesData.item.keys.first ?? "unknown")'. Please make sure the clothing type is entered correctly (e.g., 'blouse')."
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
        var hasAnyValidRecommendation = false

        for fit in ALL_FITS {
            let (bestSize, scores, partFits, fitIssues) = get_size_recommendation(
                user_measurements: userMeasurementsDict,
                clothes_db: availableSizes,
                config: config,
                desired_fit: fit
            )
            
            // Logika "N/A" (skor < 30)
            if let bestSize = bestSize, let bestScore = scores[bestSize], bestScore >= MIN_ACCEPTABLE_SCORE {
                hasAnyValidRecommendation = true
                allRecommendations[fit] = FitRecommendation(
                    bestScore: bestScore,
                    bestSize: bestSize,
                    partFits: partFits,
                    fitIssues: fitIssues
                )
            } else {
                // Beri placeholder N/A
                allRecommendations[fit] = FitRecommendation.empty(with: fitIssues)
                print("⚠️ Could not generate valid recommendation for fit: \(fit) (best score: \(scores.values.max() ?? 0))")
            }
        }
        
        // 4. Check if ANY recommendation is valid
        if !hasAnyValidRecommendation {
            self.apiError = "No suitable size found for this garment.\n\nYour measurements are outside the available size range. The garment sizes may be too small or too large for your body measurements."
            self.serverResponse = nil
            self.isCallingAPI = false
            return
        }
        
        // 5. PERBAIKAN: "Fill in the blanks"
        // Jika slightly-tight N/A, gunakan hasil 'tight'
        if allRecommendations["slightly-tight"]?.bestSize == "N/A" {
            allRecommendations["slightly-tight"] = allRecommendations["tight"]
        }
        // Jika slightly-loose N/A, gunakan hasil 'regular'
        if allRecommendations["slightly-loose"]?.bestSize == "N/A" {
             allRecommendations["slightly-loose"] = allRecommendations["regular"]
        }
        
        // 6. Assemble Final Struct (ServerResponse)
        guard let loose = allRecommendations["loose"],
              let regular = allRecommendations["regular"],
              let slightlyLoose = allRecommendations["slightly-loose"],
              let slightlyTight = allRecommendations["slightly-tight"],
              let tight = allRecommendations["tight"]
        else {
            self.apiError = "Failed to calculate all required fit profiles."
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
    ) -> (best_size: String?, scores: [String: Double], part_fits: [String: String], fit_issues: [String: FitIssue]?) {
        
        print("\n🔍 [DEBUG] Starting recommendation for fit: \(desired_fit)")
        print("👤 User measurements: \(user_measurements)")
        
        var sizeScores: [String: Double] = [:]

        // Urutkan keys untuk konsistensi
        let sortedSizes = clothes_db.keys.sorted(by: compareSizes)
        
        for size in sortedSizes {
            guard let garmentRanges = clothes_db[size] else { continue }
            
            var partScores: [String: Double] = [:]
            
            // Urutkan parts juga
            let sortedParts = config.relevantParts.sorted { $0.partName < $1.partName }
            
            print("\n   📏 Calculating for size \(size):")
            
            for partConfig in sortedParts {
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
                
                let membership = interpretTrapezoidalMembership(x: effectiveEase, params: desiredFitParams)
                let score = roundToDecimalPlaces(membership * 100)
                partScores[part] = score
                
                // DEBUG: Print detailed calculation
                print("       [\(part.padding(toLength: 10, withPad: " ", startingAt: 0))]: ease=\(String(format: "%+5.1f", effectiveEase))cm → membership=\(String(format: "%.2f", membership)) → score=\(String(format: "%3.0f", score))%")
            }

            if partScores.isEmpty {
                continue
            }

            let partWeights = config.partWeights
            var overallScore: Double = 0
            var totalWeight: Double = 0
            
            // Urutkan parts saat menghitung score
            let sortedPartScores = partScores.sorted { $0.key < $1.key }
            
            for (part, score) in sortedPartScores {
                if let weight = partWeights[part] {
                    overallScore += score * weight
                    totalWeight += weight
                }
            }
            
            let finalScore = totalWeight > 0 ? (overallScore / totalWeight) : 0
            sizeScores[size] = round(finalScore * 100) / 100 // Round ke 2 decimal
        }

        print("\n📊 [DEBUG] Size scores for \(desired_fit):")
        for (size, score) in sizeScores.sorted(by: { compareSizes($0.key, $1.key) }) {
            print("   \(size.padding(toLength: 5, withPad: " ", startingAt: 0)): \(String(format: "%.2f", score))%")
        }

        // Check if all scores are below threshold
        if sizeScores.isEmpty || sizeScores.values.allSatisfy({ $0 < MIN_ACCEPTABLE_SCORE }) {
            print("⚠️ [DEBUG] No valid size found for \(desired_fit) (all scores < \(MIN_ACCEPTABLE_SCORE)%)")
            
            // Analyze WHY the fit failed
            let issues = _analyze_fit_issues(
                user_measurements: user_measurements,
                clothes_db: clothes_db,
                config: config,
                desired_fit: desired_fit
            )
            
            return (nil, sizeScores, [:], issues)
        }

        // PERBAIKAN: Logika Tie-Breaking yang lebih baik
        let bestSize = sizeScores
            .filter { $0.value >= MIN_ACCEPTABLE_SCORE } // Hanya ambil score >= 30%
            .max { a, b in
                // a = (key: "M", value: 90.0)
                // b = (key: "L", value: 90.0)
                if abs(a.value - b.value) < 0.01 { // Jika score sama
                    // Untuk 'loose' dan 'slightly-loose', pilih size LEBIH BESAR
                    if desired_fit.contains("loose") {
                        return compareSizes(a.key, b.key) // return true jika a < b, .max akan keep 'b' (size besar)
                    }
                    // Untuk 'tight', 'slightly-tight', dan 'regular', pilih size LEBIH KECIL
                    else {
                        return !compareSizes(a.key, b.key) // return true jika a > b, .max akan keep 'b' (size kecil)
                    }
                }
                return a.value < b.value // Score lebih besar menang
            }?.key
        
        var partFits: [String: String] = [:]
        if let bestSize = bestSize, let bestSizeGarmentRanges = clothes_db[bestSize] {
            partFits = _get_part_fit_details(
                user_measurements: user_measurements,
                best_size_garment_ranges: bestSizeGarmentRanges,
                config: config
            )
        }
        
        print("✅ [DEBUG] Best size: \(bestSize ?? "nil") (score: \(bestSize.flatMap { sizeScores[$0] }.map { String(format: "%.2f", $0) } ?? "N/A")%)")
        
        return (bestSize, sizeScores, partFits, nil)
    }
    
    private func _analyze_fit_issues(
        user_measurements: [String: Double],
        clothes_db: [String: [String: [Double]]],
        config: ClothingConfig,
        desired_fit: String
    ) -> [String: FitIssue] {
        
        var issues: [String: FitIssue] = [:]
        
        // Ambil size terbesar dan terkecil untuk analisis
        let sortedSizes = clothes_db.keys.sorted(by: compareSizes)
        guard let smallestSize = sortedSizes.first,
              let largestSize = sortedSizes.last,
              let smallestGarment = clothes_db[smallestSize],
              let largestGarment = clothes_db[largestSize] else {
            return issues
        }
        
        for partConfig in config.relevantParts {
            let part = partConfig.partName
            
            guard let userMeas = user_measurements[part],
                  let desiredFitParams = partConfig.fitFunctions[desired_fit],
                  desiredFitParams.count == 4 else {
                continue
            }
            
            // Check against SMALLEST size
            if let smallestRange = smallestGarment[part], smallestRange.count == 2 {
                let smallestMax = smallestRange[1]
                let easeSmallest = smallestMax - userMeas
                
                // Jika ease < minimum acceptable ease untuk fit ini
                if easeSmallest < desiredFitParams[0] {
                    issues[part] = FitIssue(
                        part: part,
                        issue: .tooTight,
                        easeValue: easeSmallest
                    )
                    continue
                }
            }
            
            // Check against LARGEST size
            if let largestRange = largestGarment[part], largestRange.count == 2 {
                let largestMin = largestRange[0]
                let easeLargest = largestMin - userMeas
                
                // Jika ease > maximum acceptable ease untuk fit ini
                if easeLargest > desiredFitParams[3] {
                    issues[part] = FitIssue(
                        part: part,
                        issue: .tooLoose,
                        easeValue: easeLargest
                    )
                }
            }
        }
        
        return issues
    }

    private func _calculate_effective_ease(
        user_meas: Double,
        g_min: Double,
        g_max: Double,
        part_config: RelevantPart,
        desired_fit: String
    ) -> Double {
        
        // Case 1: Fixed size
        if abs(g_min - g_max) < 0.01 {
            return g_min - user_meas
        }
        
        // Case 2: User di luar range (garment terlalu kecil)
        if user_meas > g_max {
            return g_max - user_meas  // Negative ease
        }
        
        // Case 3: User di luar range (garment terlalu besar)
        if user_meas < g_min {
            return g_min - user_meas  // Positive ease
        }
        
        // Case 4: User DI DALAM range
        // Gunakan midpoint sebagai garment effective size
        let midpoint = (g_min + g_max) / 2
        return midpoint - user_meas
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
            // PERBAIKAN: Gunakan logic yang sama dengan _calculate_effective_ease
            if abs(g_min - g_max) < 0.01 {
                actualEase = g_min - userMeas
            } else if userMeas < g_min {
                actualEase = g_min - userMeas
            } else if userMeas > g_max {
                actualEase = g_max - userMeas
            } else {
                let midpoint = (g_min + g_max) / 2
                actualEase = midpoint - userMeas
            }
            
            var bestFitName: String? = nil
            var maxMembership: Double = -1.0

            // Temukan fit yang paling pas untuk ease yang dihitung
            for (fitName, fitParams) in partConfig.fitFunctions {
                let membership = roundToDecimalPlaces(interpretTrapezoidalMembership(x: actualEase, params: fitParams))
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
        partWeights: [ "bust": 0.75, "torso": 0.25 ],
        relevantParts: [
            RelevantPart(
                partName: "bust",
                easeUniverse: [-10, 41, 1],
                fitFunctions: [
                    "tight": [-10, -8, -4, -2],
                    "slightly-tight": [-4, -2, 2, 4],
                    "regular": [2, 4, 8, 10],
                    "slightly-loose": [8, 10, 14, 16],
                    "loose": [16, 18, 41, 41]
                ]
            ),
            RelevantPart(
                partName: "torso",
                easeUniverse: [-10, 21, 1],
                fitFunctions: [
                    "tight": [-10, -4, -2, 0],
                    "slightly-tight": [-2, 0, 2, 4],
                    "regular": [2, 4, 6, 8],
                    "slightly-loose": [6, 8, 10, 12],
                    "loose": [10, 12, 14, 25]
                ]
            )
        ]
    ),
    "blouse": ClothingConfig(
        partWeights: [
            "bust": 0.5,
            "torso": 0.35,
            "shoulder_width": 0,
            "arm_length": 0.15
        ],
        relevantParts: [
            RelevantPart(
                partName: "bust",
                easeUniverse: [-10, 41, 1],
                fitFunctions: [
                    "tight": [-10, -8, -4, 0],
                    "slightly-tight": [-4, 0, 3, 5],
                    "regular": [3, 5, 8, 10],
                    "slightly-loose": [8, 10, 14, 16],
                    "loose": [14, 16, 41, 41]
                ]
            ),
            RelevantPart(
                partName: "torso",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-10, -8, -4, -2],
                    "slightly-tight": [-4, -2, 0, 1],
                    "regular": [0, 1, 5, 6],
                    "slightly-loose": [5, 6, 10, 12],
                    "loose": [10, 12, 21, 21]
                ]
            ),
            RelevantPart(
                partName: "arm_length",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-5, -5, -3, -2],
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
            "bust": 0.6,
            "torso": 0.25,
            "shoulder_width": 0,
            "arm_length": 0.15
        ],
        relevantParts: [
            RelevantPart(
                partName: "bust",
                easeUniverse: [-10, 41, 1],
                fitFunctions: [
                    "tight": [-4, -2, 2, 4],
                    "slightly-tight": [2, 4, 6, 8],
                    "regular": [6, 8, 12, 14],
                    "slightly-loose": [12, 14, 18, 20],
                    "loose": [18, 20, 41, 41]
                ]
            ),
            RelevantPart(
                partName: "torso",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-10, -8, -4, -2],
                    "slightly-tight": [-4, -2, 0, 1],
                    "regular": [0, 1, 5, 6],
                    "slightly-loose": [5, 6, 10, 12],
                    "loose": [10, 12, 21, 21]
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
            "bust": 0.7,
            "torso": 0.3
        ],
        relevantParts: [
            RelevantPart(
                partName: "bust",
                easeUniverse: [-10, 41, 1],
                fitFunctions: [
                    "tight": [-4, -2, 2, 4],
                    "slightly-tight": [2, 4, 6, 8],
                    "regular": [6, 8, 12, 14],
                    "slightly-loose": [12, 14, 18, 20],
                    "loose": [18, 20, 41, 41]
                ]
            ),
            RelevantPart(
                partName: "torso",
                easeUniverse: [-5, 21, 1],
                fitFunctions: [
                    "tight": [-10, -8, -5, -3],
                    "slightly-tight": [-4, -2, 0, 1],
                    "regular": [0, 1, 4, 5],
                    "slightly-loose": [4, 5, 8, 10],
                    "loose": [8, 10, 21, 21]
                ]
            )
        ]
    ),
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

fileprivate func roundToDecimalPlaces(_ value: Double, places: Int = 2) -> Double {
    let multiplier = pow(10.0, Double(places))
    return round(value * multiplier) / multiplier
}

// MARK: - Helper Structs & Extensions

struct FitRecommendation: Codable {
    var bestScore: Double
    var bestSize: String
    var partFits: [String: String]
    
    var fitIssues: [String: FitIssue]?
    
    static var empty: FitRecommendation {
        FitRecommendation(bestScore: 0, bestSize: "N/A", partFits: [:], fitIssues: nil)
    }
    
    // Fungsi baru untuk placeholder N/A tapi dengan issue
    static func empty(with issues: [String: FitIssue]?) -> FitRecommendation {
        FitRecommendation(bestScore: 0, bestSize: "N/A", partFits: [:], fitIssues: issues)
    }
}

struct FitIssue: Codable {
    let part: String
    let issue: IssueType
    let easeValue: Double
    
    enum IssueType: String, Codable {
        case tooTight = "too-tight"
        case tooLoose = "too-loose"
    }
}

fileprivate let SIZE_ORDER: [String: Int] = [
    "XXS": 1,
    "XS": 2,
    "S": 3,
    "M": 4,
    "L": 5,
    "XL": 6,
    "XXL": 7,
    "XXXL": 8,
    "ALL_SIZE": 4
]

// Fungsi helper untuk compare size (true jika a < b)
fileprivate func compareSizes(_ a: String, _ b: String) -> Bool {
    let orderA = SIZE_ORDER[a.uppercased()] ?? 0
    let orderB = SIZE_ORDER[b.uppercased()] ?? 0
    return orderA < orderB
}
