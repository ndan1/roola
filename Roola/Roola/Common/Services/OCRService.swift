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
        
        let sizeLabels = ["xs", "s", "m", "l", "xl", "xxl"]
        
        var hasIndicator = false
        var hasSizeLabel = false
        
        for indicator in sizeChartIndicators {
            if lowercasedText.contains(indicator) {
                hasIndicator = true
                break
            }
        }
        
        for label in sizeLabels {
            let pattern = "\\b\(label)\\b"
            if lowercasedText.range(of: pattern, options: .regularExpression) != nil {
                hasSizeLabel = true
                break
            }
        }
        
        if !hasIndicator || !hasSizeLabel {
            print("❌ No size chart detected. hasIndicator: \(hasIndicator), hasSizeLabel: \(hasSizeLabel)")
            throw OCRError.noSizeChartDetected
        }
        
        print("✅ Size chart validation passed")
    }
}
