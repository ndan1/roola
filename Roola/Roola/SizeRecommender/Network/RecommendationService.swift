//
//  RecommendationService.swift
//  Roola
//
//  Created by Lin Dan Christiano on 04/11/25.
//


import Foundation

struct RecommendationService {
    
    // (Pastikan struct UserMeasurements, ClothesData, RequestBody, dan ServerResponse
    // sudah terdefinisi di file lain, seperti Clothes.swift, CalculationRequest.swift, dll.)
    
    func fetchRecommendations(userMeasurements: UserMeasurements, clothesData: ClothesData) async throws -> ServerResponse {
        let urlString = "http://127.0.0.1:5001/recommend"
        
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL")
            throw URLError(.badURL)
        }
        
        let requestBody: Data
        do {
            let requestData = RequestBody(userMeasurements: userMeasurements, clothesData: clothesData)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            requestBody = try encoder.encode(requestData)
            
            if let jsonString = String(data: requestBody, encoding: .utf8) {
                print("Request JSON:\n\(jsonString)")
            } else {
                print("Error: Could not convert requestBody to string for debugging")
            }
            
        } catch {
            print("Error: Failed to encode JSON: \(error)")
            throw error
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        print("Sending request to \(urlString)...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response Status Code: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response JSON:\n\(responseString)")
                } else {
                    print("Error: Could not convert response data to string for debugging")
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("Server Error: Status code \(httpResponse.statusCode)")
                    throw URLError(.badServerResponse)
                }
            }
            
            let decoder = JSONDecoder()
            let serverResponse = try decoder.decode(ServerResponse.self, from: data)
            print("Successfully decoded response.")
            
            return serverResponse
            
        } catch {
            print("Error: Network request or decoding failed: \(error)")
            throw error
        }
    }
}