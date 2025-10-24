//
//  OCRService.swift
//  Roola
//
//  Created by Lin Dan Christiano on 23/10/25.
//

import Vision
import UIKit

struct SizeData {
    let sizeName: String
    let bust: Int?
    let length: Int?
    let waist: Int?
    let hips: Int?
    let inseam: Int?
    
    var isValid: Bool {
        return bust != nil || length != nil || waist != nil
    }
}

class OCRService {
    
    // MARK: - Main OCR Function
    func extractSizeData(from image: UIImage) async throws -> [SizeData] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        // Step 1: Extract all text from image
        let recognizedText = try await recognizeText(from: cgImage)
        
        print("📸 OCR Raw Text:")
        print(recognizedText)
        
        // Step 2: Parse text to extract size data
        let sizeData = parseSizeData(from: recognizedText)
        
        print("\n✅ Extracted \(sizeData.count) sizes:")
        for size in sizeData {
            print("  \(size.sizeName) - Bust: \(size.bust ?? 0), Length: \(size.length ?? 0)")
        }
        
        return sizeData
    }
    
    // MARK: - Text Recognition
    private func recognizeText(from cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.recognitionFailed)
                    return
                }
                
                // Combine all recognized text
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }
            
            // Configure request for better accuracy
            request.recognitionLanguages = ["en", "id"] // English and Indonesian
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Parse Size Data
    private func parseSizeData(from text: String) -> [SizeData] {
        var sizeDataArray: [SizeData] = []
        let lines = text.components(separatedBy: .newlines)
        
        // Common size labels
        let sizeLabels = ["S", "M", "L", "XL", "XXL", "2XL", "3XL"]
        
        for (index, line) in lines.enumerated() {
            // Check if line contains a size label
            for sizeLabel in sizeLabels {
                if line.uppercased().contains(sizeLabel) {
                    // Extract numbers from this line and nearby lines
                    let contextLines = extractContextLines(from: lines, currentIndex: index, range: 2)
                    let numbers = extractNumbers(from: contextLines)
                    
                    if numbers.count >= 2 {
                        let sizeData = SizeData(
                            sizeName: sizeLabel,
                            bust: numbers.indices.contains(0) ? numbers[0] : nil,
                            length: numbers.indices.contains(1) ? numbers[1] : nil,
                            waist: numbers.indices.contains(2) ? numbers[2] : nil,
                            hips: numbers.indices.contains(3) ? numbers[3] : nil,
                            inseam: numbers.indices.contains(4) ? numbers[4] : nil
                        )
                        
                        if sizeData.isValid {
                            sizeDataArray.append(sizeData)
                        }
                    }
                }
            }
        }
        
        // Fallback: Try pattern matching for formats like "S : 86 x 58 cm"
        if sizeDataArray.isEmpty {
            sizeDataArray = parseWithPatternMatching(from: text)
        }
        
        return sizeDataArray
    }
    
    // MARK: - Pattern Matching Parser
    private func parseWithPatternMatching(from text: String) -> [SizeData] {
        var sizeDataArray: [SizeData] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            // Pattern: "S : 86 x 58 cm" or "M: 92 x 60"
            let pattern = #"([S|M|L|XL|XXL|2XL|3XL]+)\s*[:：]\s*(\d+)\s*[x×]\s*(\d+)"#
            
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = line as NSString
                let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if match.numberOfRanges >= 4 {
                        let sizeName = nsString.substring(with: match.range(at: 1)).uppercased()
                        let firstNumber = Int(nsString.substring(with: match.range(at: 2)))
                        let secondNumber = Int(nsString.substring(with: match.range(at: 3)))
                        
                        let sizeData = SizeData(
                            sizeName: sizeName,
                            bust: firstNumber,
                            length: secondNumber,
                            waist: nil,
                            hips: nil,
                            inseam: nil
                        )
                        
                        if sizeData.isValid {
                            sizeDataArray.append(sizeData)
                        }
                    }
                }
            }
        }
        
        return sizeDataArray
    }
    
    // MARK: - Helper Methods
    private func extractContextLines(from lines: [String], currentIndex: Int, range: Int) -> String {
        let start = max(0, currentIndex - range)
        let end = min(lines.count - 1, currentIndex + range)
        return lines[start...end].joined(separator: " ")
    }
    
    private func extractNumbers(from text: String) -> [Int] {
        let pattern = #"\d+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        return matches.compactMap { match in
            let numberString = nsString.substring(with: match.range)
            return Int(numberString)
        }.filter { $0 > 20 && $0 < 200 } // Filter reasonable measurements (cm)
    }
}

// MARK: - Errors
enum OCRError: Error, LocalizedError {
    case invalidImage
    case recognitionFailed
    case noSizeDataFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .recognitionFailed:
            return "Failed to recognize text from image"
        case .noSizeDataFound:
            return "No size data found in the image"
        }
    }
}
