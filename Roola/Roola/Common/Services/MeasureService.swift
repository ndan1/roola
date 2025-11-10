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
    private let endpointID = "5e9eu6mwoznmzz"
    private let baseURL = "https://api.runpod.ai/v2"
    private let MAX_WAIT: TimeInterval = 600
    private let POLL_INTERVAL: TimeInterval = 5

    init() {
        guard let key = ConfigManager.getMeasureKey() else {
            fatalError("RunPod API Key not found in Config.plist")
        }
        self.apiKey = key
    }

    // MARK: - Public Method
    func getMeasurement(from videoURL: URL) async throws -> [String: Any] {
        let videoBase64 = try encodeVideo(videoURL)
        let jobID = try await submitJob(videoBase64: videoBase64)
        let result = try await pollJob(jobID: jobID)
        return result
    }

    // MARK: - Helpers
    private func encodeVideo(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return data.base64EncodedString()
    }

    private func submitJob(videoBase64: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/\(endpointID)/run") else {
            throw MeasureServiceError.invalidURL
        }

        let payload: [String: Any] = [
            "input": [
                "video": videoBase64
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
                return json ?? [:]
            }

            try await Task.sleep(nanoseconds: UInt64(POLL_INTERVAL * 1_000_000_000))
        }
    }
}
