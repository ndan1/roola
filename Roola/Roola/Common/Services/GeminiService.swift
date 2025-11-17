//
//  GeminiService.swift
//  Roola
//
//  Created by Lin Dan Christiano on 06/11/25.
//

import Foundation

// MARK: - Gemini Service

struct GeminiService {
    
    private let apiKey: String
    // Kita gunakan model Flash terbaru untuk kecepatan dan JSON mode
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent"
    
    init() {
        // PENTING: Pastikan Anda sudah menambahkan fungsi getGeminiAPIKey()
        // ke ConfigManager Anda, atau sesuaikan baris ini.
        guard let key = ConfigManager.getGeminiAPIKey() else {
            fatalError("Gemini API Key not found in Config.plist")
        }
        self.apiKey = key
    }
    
    /// Fungsi ini memiliki nama dan input/output yang sama dengan OpenAIService
    /// sehingga mudah diganti di ViewModel.
    func extractSizeChart(from ocrText: String) async throws -> String {
        
        // 1. URL dengan API Key
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        // 2. Prompt (disalin dari OpenAIService Anda)
        let prompt = """
        You are a data extraction assistant. I have OCR text from a clothing size chart image.
        
        Extract the size information and convert it to this exact JSON format:
        
        {
          "sizes": [
            {
              "size": "SIZE_NAME",
              "clothes_torso_min": number,
              "clothes_torso_max": number,
              "clothes_bust_min": number,
              "clothes_bust_max": number,
              "clothes_arm_min": number,
              "clothes_arm_max": number,
              "clothes_waist_min": number or null,
              "clothes_waist_max": number or null
            }
          ]
        }
        
        Rules:
        - Extract all available sizes (S, M, L, XL, XXL, S-M, L-XL, 2XL, etc.)
        - If the size 2XL, 3XL, etc, convert to XXL, XXXL
        - If the size is a range like "S-M", "SM", or "ML", seperate the JSON entries for S and M, except size such as "XL-XXXL" and "XS" which should remain as is
        - If there is no clear label, or there is only 1 size, use "all_size" as the namespace
        - For measurements that show ranges like "33-35", use 33 as min and 35 as max
        - For single measurements like "64", use the same value for both min and max, e.g., 64 for min and 64 for max, include if the size chart written "up to" just use both value for min and max
        - If a measurement is not available, use null
        - Don't insert INT as size label, it's just column header
        - If there are 2 measurement like Allsize, Oversize, Bigsize and M, L, XL, or other size, ignore Allsize and use M, L, XL sizes, but if there are no M, L, XL sizes, use Allsize and other as size label
        - Common measurement names: "LINGKAR DADA" = bust, "PINGGANG" = waist, "PANJANG BAJU" = torso, "PANJANG LENGAN" = arm_length
        - All measurements should be in centimeters (cm)
        - Return ONLY the JSON, no additional text 
        
        OCR Text:
        \(ocrText)
        """
        
        // 3. Buat Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 4. Buat Request Body sesuai format Gemini
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json", // Ini memaksa output JSON
                "temperature": 0.2 // Suhu rendah untuk output yang konsisten
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("Sending request to Gemini API...")
        
        // 5. Kirim Request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("API Error: \(errorText)")
                throw GeminiError.apiError(errorText)
            }
        }
        
        // 6. Parse Response (Struktur Gemini berbeda)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiError.invalidResponse
        }
        
        print("Raw API Response:")
        print(json)
        
        // Cek jika diblokir oleh safety settings
        if let promptFeedback = json["promptFeedback"] as? [String: Any],
           let blockReason = promptFeedback["blockReason"] as? String {
           print("Request blocked by Gemini: \(blockReason)")
           throw GeminiError.apiError("Request blocked by safety settings: \(blockReason)")
        }

        // Ekstrak konten dari respons Gemini
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let jsonString = firstPart["text"] as? String else {
            throw GeminiError.noContent
        }
        
        print("\n📋 Extracted JSON:")
        print(jsonString)
        
        return jsonString
    }
}

// MARK: - Gemini Error

enum GeminiError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noContent
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .noContent:
            return "No content in API response"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}
