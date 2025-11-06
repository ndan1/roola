//
//  OpenAIService.swift
//  Roola
//
//  Created by Lin Dan Christiano on 25/10/25.
//

import Foundation

struct OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        guard let key = ConfigManager.getAPIKey() else {
            fatalError("OpenAI API Key not found in Config.plist")
        }
        self.apiKey = key
    }
    
    func extractSizeChart(from ocrText: String) async throws -> String {
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
        - For single measurements like "64", use the same value for both min and max
        - If a measurement is not available, use null
        - Don't insert INT as size label, it's just column header
        - Common measurement names: "LINGKAR DADA" = bust, "PINGGANG" = waist, "PANJANG BAJU" = torso, "PANJANG LENGAN" = arm_length
        - All measurements should be in centimeters (cm)
        - Return ONLY the JSON, no additional text 
        
        OCR Text:
        \(ocrText)
        """
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "model": "gpt-5-mini",
            "response_format": [ "type": "json_object" ],
            "messages": [
                [
                    "role": "system",
                    "content": "You are a JSON data extraction expert. Always return valid JSON only."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("Sending request to OpenAI API...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("API Error: \(errorText)")
                throw OpenAIError.apiError(errorText)
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OpenAIError.invalidResponse
        }
        
        print("Raw API Response:")
        print(json)
        
        // Extract content from response
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.noContent
        }
        
        print("\n📋 Extracted JSON:")
        print(content)
        
        return content
    }
}

enum OpenAIError: LocalizedError {
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
