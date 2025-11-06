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
        case .notUpperwear, .noSizeChartDetected:
            return "Uh Oh!"
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
            return "Size chart uploaded wasn't an upperwear!"
        case .noSizeChartDetected:
            return "There wasn't any size chart in the screenshot"
        }
    }
    
    var errorDescription: String? {
        return message
    }
}
