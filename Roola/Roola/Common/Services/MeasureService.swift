//
//  MeasureService.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 08/11/25.
//

import Foundation

enum MeasureServiceError: Error {
    case invalidURL
    case invalidResponse
    case timeout
    case serverError(String)
}

struct MeasureService {
    private let apiKey: String
    // Updated Endpoint ID from python script
    private let endpointID = "j5p5csagwls8pl"
    private let baseURL = "https://api.runpod.ai/v2"
    private let MAX_WAIT: TimeInterval = 300 // Matches Python's 300s
    private let POLL_INTERVAL: TimeInterval = 2 // Reduced to 2s for images

    init() {
        guard let key = ConfigManager.getMeasureKey() else {
            fatalError("RunPod API Key not found in Config.plist")
        }
        self.apiKey = key
    }

    // MARK: - Public Method
    
    /// Submits an image for body measurement.
    /// - Parameters:
    ///   - imageData: The raw Data of the image (JPEG/PNG).
    ///   - height: The user's height in CM.
    func getMeasurement(imageData: Data, height: Double) async throws -> [String: Any] {
        // 1. Encode Image to Base64
        let imageBase64 = imageData.base64EncodedString()
        
        // 2. Submit Job
        let jobID = try await submitJob(imageBase64: imageBase64, height: height)
        
        // 3. Poll for results
        let result = try await pollJob(jobID: jobID)
        return result
    }

    // MARK: - Helpers

    private func submitJob(imageBase64: String, height: Double) async throws -> String {
        guard let url = URL(string: "\(baseURL)/\(endpointID)/run") else {
            throw MeasureServiceError.invalidURL
        }

        // Updated Payload structure to match Python script
        let payload: [String: Any] = [
            "input": [
                "image": imageBase64,
                "height": height
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MeasureServiceError.serverError(text)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let jobID = json?["id"] as? String else {
            throw MeasureServiceError.invalidResponse
        }

        return jobID
    }

    private func pollJob(jobID: String) async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)/\(endpointID)/status/\(jobID)") else {
            throw MeasureServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let start = Date()

        while true {
            if Date().timeIntervalSince(start) > MAX_WAIT {
                throw MeasureServiceError.timeout
            }

            let (data, response) = try await URLSession.shared.data(for: request)
            
            // If status check fails (non-200), wait and retry
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                try await Task.sleep(nanoseconds: UInt64(POLL_INTERVAL * 1_000_000_000))
                continue
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let status = json?["status"] as? String else {
                throw MeasureServiceError.invalidResponse
            }

            print("→ \(status)... (\(Int(Date().timeIntervalSince(start)))s elapsed)")

            if ["COMPLETED", "FAILED", "CANCELLED"].contains(status) {
                // If completed, the python script looks at result["output"]
                // We return the whole JSON here so the caller can handle "output" or "error"
                return json ?? [:]
            }

            try await Task.sleep(nanoseconds: UInt64(POLL_INTERVAL * 1_000_000_000))
        }
    }
}
