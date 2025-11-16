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
    private let geminiService: GeminiService
    
    private let ALL_FITS = ["tight", "slightly-tight", "regular", "slightly-loose", "loose"]
    
    // MINIMUM SCORE THRESHOLD - Rekomendasi harus punya score minimal 30%
    private let MIN_ACCEPTABLE_SCORE = 20.0

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
        showErrorAlert = false
    }
    
    /// 1. Menjalankan OCR dan ekstraksi AI
    func processImage() {
        guard let image = selectedImage else { return }
        
        // Reset states (but don't start loading yet)
        currentStep = ""
        serverResponse = nil
        apiError = nil
        
        Task {
            do {
                // Step A: OCR (without showing loading yet)
                let ocrResult = try await ocrService.performOCR(on: image)
                
                self.recognizedText = ocrResult
                
                print("\n📝 OCR Result:")
                print(ocrResult)
                
                // Validate OCR text first (this may throw OCRError)
                try await ocrService.validateOCRText(ocrResult)
                
                // If validation passes, NOW show loading
                self.isProcessing = true
                self.currentStep = "Validating size chart..."
                
                // Ensure loading stops when function finishes
                defer {
                    self.isProcessing = false
                }
                
                // Step B: Gemini API
                self.currentStep = "Analyzing with AI..."
                
                let jsonResult = try await geminiService.extractSizeChart(from: ocrResult)
                
                self.extractedJSON = jsonResult
                self.currentStep = "Finalizing..."

                print("\n✅ Final JSON Result:")
                print(jsonResult)
                
                // Note: isProcessing becomes false automatically via 'defer' here
                
            } catch let error as OCRError {
                await MainActor.run {
                    handleError(error)
                }
            } catch {
                handleError(OCRError.recognitionFailed)
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
        
        calculateLocalRecommendations(
            userMeasurements: userMeasurements,
            clothesData: clothesData
        )
    }
    
    // MARK: - Private Helper Functions
    
    private func handleError(_ error: OCRError) {
        print("\n🚨 [handleError] Called with error: \(error)")
        recognizedText = "Error: \(error.localizedDescription)"
        currentStep = ""
        isProcessing = false
        currentError = error
        showErrorAlert = true
        print("🚨 [handleError] showErrorAlert set to: \(showErrorAlert)")
        print("🚨 [handleError] currentError set to: \(String(describing: currentError))")
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

        let userMeasurementsDict = userMeasurementsToDictionary(userMeasurements)
        let availableSizes = transformSizeChart(sizeChartStructs)
        
        var allRecommendations: [String: FitRecommendation] = [:]
        var previousSize: String? = nil

        for fit in ALL_FITS {
            let (bestSize, scores, partFits, fitIssues) = get_size_recommendation(
                user_measurements: userMeasurementsDict,
                clothes_db: availableSizes,
                config: config,
                desired_fit: fit,
                minimumSize: previousSize
            )
            
            if let bestSize = bestSize {
                let bestScore = scores[bestSize] ?? 0
                let recommendation = FitRecommendation(
                    bestScore: bestScore,
                    bestSize: bestSize,
                    partFits: partFits,
                    fitIssues: fitIssues
                )
                allRecommendations[fit] = recommendation
                previousSize = bestSize
                
                if bestScore < MIN_ACCEPTABLE_SCORE {
                    print("⚠️ [INFO] Low confidence recommendation for fit '\(fit)': size \(bestSize) (score: \(String(format: "%.1f", bestScore))%)")
                    if let issues = fitIssues, !issues.isEmpty {
                        print("   Issues: \(issues.map { "\($0.key)=\($0.value.issue.rawValue)" }.joined(separator: ", "))")
                    }
                }
            } else {
                allRecommendations[fit] = FitRecommendation.empty
                print("❌ [ERROR] Could not generate recommendation for fit: \(fit)")
            }
        }
        
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
        desired_fit: String,
        minimumSize: String? = nil
    ) -> (best_size: String?, scores: [String: Double], part_fits: [String: String], fit_issues: [String: FitIssue]?) {
        
        print("\n🔍 [DEBUG] Starting recommendation for fit: \(desired_fit)")
        print("👤 User measurements: \(user_measurements)")
        
        var sizeScores: [String: Double] = [:]

        let sortedSizes = clothes_db.keys.sorted(by: compareSizes)
        
        for size in sortedSizes {
            guard let garmentRanges = clothes_db[size] else { continue }
            
            var partScores: [String: Double] = [:]
            
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
        
        let bestSize: String?
        let hasGoodScore = sizeScores.values.contains(where: { $0 >= MIN_ACCEPTABLE_SCORE })
        
        if hasGoodScore {
            // ✅ Ada size dengan score bagus (>= 30%), terapkan constraint ordering
            var eligibleSizes = sizeScores
            if let minSize = minimumSize {
                eligibleSizes = sizeScores.filter { size, _ in
                    compareSizes(minSize, size) || minSize == size // size >= minSize
                }
                
                if eligibleSizes.isEmpty {
                    print("⚠️ [DEBUG] No sizes meet minimum constraint ('\(minSize)'). Using minimum size.")
                    eligibleSizes = [minSize: sizeScores[minSize] ?? 0]
                } else if eligibleSizes.count < sizeScores.count {
                    print("🔒 [DEBUG] Constraint applied: size must be >= '\(minSize)' (filtered \(sizeScores.count - eligibleSizes.count) smaller sizes)")
                }
            }
            
            bestSize = eligibleSizes
                .filter { $0.value >= MIN_ACCEPTABLE_SCORE }
                .max { a, b in
                    if abs(a.value - b.value) < 0.01 {
                        // Jika score sama, pilih yang terdekat dari previousSize
                        if let minSize = minimumSize {
                            let distA = abs((SIZE_ORDER[a.key.uppercased()] ?? 0) - (SIZE_ORDER[minSize.uppercased()] ?? 0))
                            let distB = abs((SIZE_ORDER[b.key.uppercased()] ?? 0) - (SIZE_ORDER[minSize.uppercased()] ?? 0))
                            if distA != distB {
                                return distA > distB // Prefer closer to previousSize
                            }
                        }
                        // Fallback: gunakan preference
                        if desired_fit.contains("loose") {
                            return compareSizes(a.key, b.key)
                        } else {
                            return !compareSizes(a.key, b.key)
                        }
                    }
                    return a.value < b.value
                }?.key
        } else {
            // ✅ SEMUA size score buruk (< 30%)
            // ABAIKAN constraint ordering, SELALU pilih size dengan score TERTINGGI (closest fit)
            print("⚠️ [DEBUG] No good fit found (all scores < \(MIN_ACCEPTABLE_SCORE)%). Selecting closest fit (highest score)...")
            print("   ℹ️ Constraint ordering is IGNORED for low confidence fits")
            
            if !sizeScores.isEmpty {
                // Find max score
                let maxScore = sizeScores.values.max() ?? 0
                
                // Get all sizes with max score (in case of ties)
                let tieSizes = sizeScores.filter { abs($0.value - maxScore) < 0.01 }
                
                if tieSizes.count == 1 {
                    // No tie, simple case
                    bestSize = tieSizes.first?.key
                } else {
                    // Multiple sizes with same score, apply tie-breaker
                    bestSize = tieSizes.max { a, b in
                        // Tie-breaker berdasarkan preference
                        if desired_fit.contains("loose") {
                            return compareSizes(a.key, b.key) // Prefer larger
                        } else if desired_fit.contains("tight") {
                            return !compareSizes(a.key, b.key) // Prefer smaller
                        } else {
                            // Regular: prefer middle size or smaller when all equal
                            let sortedTieSizes = tieSizes.keys.sorted(by: compareSizes)
                            let firstSize = sortedTieSizes.first ?? a.key
                            
                            // Prefer smaller size (closer to user's measurements)
                            if a.key == firstSize {
                                return false // a wins
                            }
                            if b.key == firstSize {
                                return true // b wins
                            }
                            return compareSizes(a.key, b.key) // fallback
                        }
                    }?.key
                }
                
                if let bestSize = bestSize {
                    print("   → Fallback: Size '\(bestSize)' with highest score (\(String(format: "%.1f", sizeScores[bestSize] ?? 0))%)")
                    if let minSize = minimumSize, compareSizes(bestSize, minSize) {
                        print("   ⚠️ Note: Selected size '\(bestSize)' is smaller than previous fit's size '\(minSize)' (all scores < 30%, prioritizing closest fit)")
                    }
                }
            } else {
                bestSize = nil
                print("   → Fallback: No sizes available")
            }
        }
        
        // Analyze fit issues untuk size yang dipilih
        var fitIssues: [String: FitIssue]? = nil
        var partFits: [String: String] = [:]
        
        if let bestSize = bestSize, let bestSizeGarmentRanges = clothes_db[bestSize] {
            // Get part fits (normal classification)
            partFits = _get_part_fit_details(
                user_measurements: user_measurements,
                best_size_garment_ranges: bestSizeGarmentRanges,
                config: config
            )
            
            // Analyze issues (for visualization)
            fitIssues = _analyze_fit_issues_for_size(
                user_measurements: user_measurements,
                garment_ranges: bestSizeGarmentRanges,
                config: config,
                desired_fit: desired_fit
            )
            
            // Debug print issues
            if let issues = fitIssues, !issues.isEmpty {
                print("⚠️ [DEBUG] Fit issues detected:")
                for (part, issue) in issues {
                    print("   [\(part)]: \(issue.issue.rawValue) (ease: \(String(format: "%+.1f", issue.easeValue))cm)")
                }
            }
        }
        
        print("✅ [DEBUG] Best size: \(bestSize ?? "nil") (score: \(bestSize.flatMap { sizeScores[$0] }.map { String(format: "%.2f", $0) } ?? "N/A")%)")
        
        return (bestSize, sizeScores, partFits, fitIssues)
    }
    
    /// Analyze fit issues untuk SIZE SPESIFIK yang sudah dipilih
    private func _analyze_fit_issues_for_size(
        user_measurements: [String: Double],
        garment_ranges: [String: [Double]],
        config: ClothingConfig,
        desired_fit: String
    ) -> [String: FitIssue]? {
        
        var issues: [String: FitIssue] = [:]
        
        for partConfig in config.relevantParts {
            let part = partConfig.partName
            
            guard let userMeas = user_measurements[part],
                  let garmentRange = garment_ranges[part], garmentRange.count == 2,
                  let desiredFitParams = partConfig.fitFunctions[desired_fit],
                  desiredFitParams.count == 4 else {
                continue
            }
            
            let gMin = garmentRange[0]
            let gMax = garmentRange[1]
            
            // Calculate actual ease for this size
            let actualEase = _calculate_effective_ease(
                user_meas: userMeas,
                g_min: gMin,
                g_max: gMax,
                part_config: partConfig,
                desired_fit: desired_fit
            )
            
            // Check apakah ease di luar acceptable range untuk desired fit
            let minAcceptableEase = desiredFitParams[0]
            let maxAcceptableEase = desiredFitParams[3]
            
            if actualEase < minAcceptableEase {
                // Garment terlalu kecil untuk desired fit (too tight)
                issues[part] = FitIssue(
                    part: part,
                    issue: .tooTight,
                    easeValue: actualEase
                )
            } else if actualEase > maxAcceptableEase {
                // Garment terlalu besar untuk desired fit (too loose)
                issues[part] = FitIssue(
                    part: part,
                    issue: .tooLoose,
                    easeValue: actualEase
                )
            }
            // Jika actualEase dalam range [minAcceptableEase, maxAcceptableEase], tidak ada issue
        }
        
        return issues.isEmpty ? nil : issues
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
//            "hips": measurements.hips,
//            "shoulder_width": measurements.shoulderWidth,
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
            "bust": 0.7,
            "torso": 0.20,
            "shoulder_width": 0,
            "arm_length": 0.10
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
            "bust": 0.75,
            "torso": 0.25
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

struct FitRecommendation: Codable, Equatable {
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

struct FitIssue: Codable, Equatable {
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
