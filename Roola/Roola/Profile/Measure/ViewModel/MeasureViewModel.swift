//
//  MeasureViewModel.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 08/11/25.
//

//
//  MeasureViewModel.swift
//  Roola
//
//  Created by ChatGPT on 08/11/25.
//

import Foundation
import Combine

final class MeasureViewModel: ObservableObject {
    
    // MARK: - Published UI state
    @Published var isLoading = false
    @Published var result: [String: Any]?
    @Published var errorMessage: String?
    
    // MARK: - Private
    private let measureService = MeasureService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public API
    
    /// Main entry point – accepts a **Base64** string (the controller already creates it)
    func sendMeasurement(videoBase64: String) async {
        await MainActor.run { self.reset() }
        
        // Create a temporary file so that `MeasureService` can read it as a URL
        guard let tempURL = tempFileURL(withBase64: videoBase64) else {
            await setError("Failed to create temporary video file")
            return
        }
        
        await upload(videoURL: tempURL)
        
        // Clean up the temp file (fire-and-forget)
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    /// Accepts a **local video URL** – used internally and also exposed for flexibility
    func upload(videoURL: URL) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let apiResult = try await measureService.getMeasurement(from: videoURL)
            await MainActor.run {
                self.isLoading = false
                self.result = apiResult
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Helpers
    
    private func reset() {
        isLoading = false
        result = nil
        errorMessage = nil
    }
    
    private func setError(_ message: String) async {
        await MainActor.run {
            self.isLoading = false
            self.errorMessage = message
        }
    }
    
    /// Writes the Base64 string to a temporary .mp4 file and returns its URL.
    private func tempFileURL(withBase64 base64: String) -> URL? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        let fileName = "measure-\(UUID().uuidString).mp4"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Failed to write temp video: \(error)")
            return nil
        }
    }
}
