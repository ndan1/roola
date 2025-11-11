//
//  OCRError.swift
//  Roola
//
//  Created by Lin Dan Christiano on 04/11/25.
//

import Foundation

enum OCRError: Error, LocalizedError {
    case invalidImage
    case recognitionFailed
    case noSizeDataFound
    case noTextFound
    case notUpperwear
    case noSizeChartDetected
    
    var title: String {
        switch self {
        case .invalidImage, .noTextFound, .recognitionFailed, .noSizeDataFound:
            return "Error"
        case .notUpperwear:
            return "Uh oh! Size chart uploaded wasn’t an upperwear"
        case .noSizeChartDetected:
            return "Uh oh! There wasn't any size chart in the screenshot"
        }
    }
    
    var message: String {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .recognitionFailed:
            return "Failed to recognize text from image"
        case .noSizeDataFound:
            return "No size data found in the image"
        case .noTextFound:
            return "No text found in image"
        case .notUpperwear:
            return "Roola only can get your upperwear sizes for now :("
        case .noSizeChartDetected:
            return "Try another one?"
        }
    }
    
    var errorDescription: String? {
        return message
    }
}
