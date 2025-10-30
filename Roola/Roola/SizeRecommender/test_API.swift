import Foundation
import SwiftUI

struct TestView: View {
    @State private var serverResponse: ServerResponse?
    @State private var errorMessage: String?
    @State private var isLoading = false

    // We add an init so we can set the state for previews
    init(serverResponse: ServerResponse? = nil, errorMessage: String? = nil, isLoading: Bool = false) {
        _serverResponse = State(initialValue: serverResponse)
        _errorMessage = State(initialValue: errorMessage)
        _isLoading = State(initialValue: isLoading)
    }

    var body: some View {
        VStack(spacing: 20) {
            Button("Get Recommendation") {
                Task {
                    isLoading = true
                    errorMessage = nil
                    serverResponse = nil
                    do {
                        // --- Create the Data Here ---
                        // This data now comes from the view, not the network function.
                        let userMeasurements = UserMeasurements(
                            bust: 91.0,
                            waist: 73.0,
                            hips: 100.0,
                            shoulderWidth: 37.0,
                            torso: 58.0,
                            armLength: 55.0
                        )
                        
                        let clothingType = "blouse"
                        let clothesData = ClothesData(
                            item: [
                                clothingType: [
                                    "S": SizeMeasurements(torso: [62.0, 62.0], bust: [86.0, 86.0], armLength: [0.0, 0.0], waist: [72.0, 72.0]),
                                    "M": SizeMeasurements(torso: [63.0, 63.0], bust: [92.0, 92.0], armLength: [0.0, 0.0], waist: [78.0, 78.0]),
                                    "L": SizeMeasurements(torso: [64.0, 64.0], bust: [100.0, 100.0], armLength: [0.0, 0.0], waist: [86.0, 86.0])
                                ]
                            ]
                        )
                        
                        // Pass the data into the function
                        serverResponse = try await fetchRecommendations(
                            userMeasurements: userMeasurements,
                            clothesData: clothesData
                        )
                    } catch {
                        errorMessage = "Failed to get recommendation: \(error.localizedDescription)"
                    }
                    isLoading = false
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            if isLoading {
                ProgressView()
            } else if let serverResponse {
                // Updated UI to show the new data structure
                // We'll display the "regular" fit as the primary recommendation
                let regularRec = serverResponse.recommendations.regular
                Text("Recommended (Regular): \(regularRec.bestSize)")
                    .font(.headline)
                Text("Score: \(String(format: "%.1f", regularRec.bestScore))")
                    .font(.subheadline)
                
                // And we can show the "loose" fit as an alternative
                let looseRec = serverResponse.recommendations.loose
                Text("Recommended (Loose): \(looseRec.bestSize)")
                    .font(.headline)
                    .padding(.top)
                Text("Score: \(String(format: "%.1f", looseRec.bestScore))")
                    .font(.subheadline)
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// --- 2. Create the Network Function ---

// The function now accepts the data as parameters and returns the new ServerResponse
func fetchRecommendations(userMeasurements: UserMeasurements, clothesData: ClothesData) async throws -> ServerResponse {
    let urlString = "http://127.0.0.1:5001/recommend"
    
    guard let url = URL(string: urlString) else {
        print("Error: Invalid URL")
        throw URLError(.badURL)
    }
    
    // --- 4. Encode the Data into JSON ---
    let requestBody: Data
    do {
        // Create the RequestBody from the function parameters
        let requestData = RequestBody(userMeasurements: userMeasurements, clothesData: clothesData)
        
        // Create an encoder
        let encoder = JSONEncoder()
        // Sort keys alphabetically to ensure consistent JSON output
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted] // Added .prettyPrinted for readable JSON output
        
        requestBody = try encoder.encode(requestData)
        
        // Debug print for the request JSON
        if let jsonString = String(data: requestBody, encoding: .utf8) {
            print("Request JSON:\n\(jsonString)")
        } else {
            print("Error: Could not convert requestBody to string for debugging")
        }
        
    } catch {
        print("Error: Failed to encode JSON: \(error)")
        throw error
    }
    
    // --- 5. Configure the URLRequest ---
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = requestBody
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // --- 6. Send the Request ---
    print("Sending request to \(urlString)...")
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the HTTP response status
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status Code: \(httpResponse.statusCode)")
            // Debug print for the raw response data
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
        
        // Try to decode the response data into our NEW struct
        let decoder = JSONDecoder()
        let serverResponse = try decoder.decode(ServerResponse.self, from: data)
        print("Successfully decoded response.")
        
        // Return the decoded object
        return serverResponse
        
    } catch {
        print("Error: Network request or decoding failed: \(error)")
        throw error
    }
}
