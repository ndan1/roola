//
//  OCRService.swift
//  Roola
//
//  Created by Lin Dan Christiano on 23/10/25.
//
import Foundation
import Vision
import UIKit

struct LocalOCRService {
    
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
            
            recognizeRequest.recognitionLanguages = ["id", "en"]
            
            recognizeRequest.usesLanguageCorrection = true
            
            recognizeRequest.recognitionLevel = .accurate
            
            do {
                try handler.perform([recognizeRequest])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func validateOCRText(_ text: String) async throws {
        let lowercasedText = text.lowercased()
        
        let bottomWearPatterns = [
            "panjang celana", "lingkar paha", "panjang bawahan", "inseam",
            "lingkar pinggang celana", "panjang kaki", "leg length",
            "thigh circumference", "pants length", "celana panjang", "celana pendek"
        ]
        
        for pattern in bottomWearPatterns {
            if lowercasedText.contains(pattern) {
                print("❌ Detected bottom wear keyword: \(pattern)")
                throw OCRError.notUpperwear
            }
        }
        
        let sizeChartIndicators = [
            "size", "ukuran", "chest", "bust", "dada", "length", "panjang",
            "shoulder", "bahu", "torso", "sleeve", "lengan", "waist", "pinggang", "cm", "inch"
        ]
        
        var hasIndicator = false
        for indicator in sizeChartIndicators {
            if lowercasedText.contains(indicator) {
                hasIndicator = true
                break
            }
        }
        
        if !hasIndicator {
            print("❌ No size chart indicators detected.")
            throw OCRError.noSizeChartDetected
        }
        
        let allSizePatterns = ["all size", "one size", "free size", "satu ukuran", "allsize", "onesize"]
        let specificSizeLabels = ["xxs", "xs", "s", "m", "l", "xl", "xxl", "2xl", "3xl", "xxxl"]
        
        var hasAllSize = false
        var detectedSizes = Set<String>()
        
        for pattern in allSizePatterns {
            if lowercasedText.contains(pattern) {
                hasAllSize = true
                break
            }
        }
            
        for label in specificSizeLabels {
            let pattern = "\\b\(label)\\b"
            
            if lowercasedText.range(of: pattern, options: .regularExpression) != nil {
                detectedSizes.insert(label)
            }
        }
        
        print("🔍 Validation Check:")
        print("   - Has All Size: \(hasAllSize)")
        print("   - Detected Sizes: \(detectedSizes) (Count: \(detectedSizes.count))")
        
        if hasAllSize {
            print("✅ Size chart validation passed (Contains 'All Size')")
            return
        }
        
        if detectedSizes.count >= 2 {
            print("✅ Size chart validation passed (Found \(detectedSizes.count) sizes)")
            return
        }
        
        if detectedSizes.isEmpty && !hasAllSize {
                print("❌ No size label detected.")
                throw OCRError.noSizeChartDetected
        } else {
            print("❌ Incomplete size chart. Found: \(detectedSizes.count) sizes, No 'All Size'.")
            throw OCRError.incompleteSizeChart
        }
    }
}
