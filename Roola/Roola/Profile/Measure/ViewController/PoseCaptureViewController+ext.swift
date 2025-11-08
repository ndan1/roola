//
//  PoseCaptureViewController.swift
//  Roola
//
//  Created by Lin Dan Christiano on 29/10/25.
//

import UIKit
import AVFoundation
import Foundation

extension PoseCaptureViewController {
    
    /// Get video file size in bytes (and human-readable format)
    func getVideoSize(at url: URL) -> (bytes: Int64, formatted: String)? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ Video file not found at \(url.path)")
            return nil
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let fileSize = attributes[.size] as? Int64 else { return nil }
            
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useMB, .useKB]
            formatter.countStyle = .file
            
            let formatted = formatter.string(fromByteCount: fileSize)
            
            print("📁 Video size: \(fileSize) bytes (\(formatted))")
            return (fileSize, formatted)
        } catch {
            print("❌ Error getting video size: \(error)")
            return nil
        }
    }
    
    /// Prepare Base64 encoder: Returns the encoded string (or nil on error)
    /// - Note: Call this *after* `stopRecording()` completes (video is finalized)
    /// - Warning: Loads entire file into memory – fine for <50MB videos
    func encodeVideoToBase64(at url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else {
            print("Failed to read video data from \(url)")
            return nil
        }
        
        // Only valid option: .lineLength64Characters
        let base64String = data.base64EncodedString(options: .lineLength64Characters)
        
        let encodedSize = base64String.count
        let formattedSize = ByteCountFormatter.string(fromByteCount: Int64(encodedSize), countStyle: .file)
        print("Base64 encoded: \(formattedSize) (\(encodedSize) characters)")
        
        return base64String
    }
    
    /// Convenience: Get size + encode to Base64 in one call
    func prepareVideoBase64(at url: URL) -> (sizeFormatted: String, base64: String?)? {
        guard let sizeInfo = getVideoSize(at: url) else { return nil }
        let base64 = encodeVideoToBase64(at: url)
        return (sizeInfo.formatted, base64)
    }
}
