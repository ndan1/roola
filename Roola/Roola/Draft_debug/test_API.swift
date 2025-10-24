import Foundation
import SwiftUI // Import SwiftUI for the View and Previews

// --- SwiftUI Usage Example ---

struct TestView: View {
     // The state now holds the entire server response
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
                        
                        let clothesData = ClothesData(
                            blouse: [
                                "S": SizeMeasurements(torso: [64.0, 64.0], bust: [90.0, 90.0], armLength: [60.0, 60.0], waist: [66.0, 70.0]),
                                "M": SizeMeasurements(torso: [64.0, 64.0], bust: [90.0, 90.0], armLength: [60.0, 60.0], waist: [66.0, 70.0]),
                                "L": SizeMeasurements(torso: [67.0, 67.0], bust: [96.0, 96.0], armLength: [61.0, 61.0], waist: [70.0, 78.0]),
                                "XL": SizeMeasurements(torso: [67.0, 67.0], bust: [96.0, 96.0], armLength: [61.0, 61.0], waist: [70.0, 78.0]),
                                "XXL": SizeMeasurements(torso: [70.0, 70.0], bust: [102.0, 102.0], armLength: [62.0, 62.0], waist: [78.0, 88.0]),
                                "XXXL": SizeMeasurements(torso: [70.0, 70.0], bust: [108.0, 108.0], armLength: [63.0, 63.0], waist: [98.0, 106.0])
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

// --- 1. Define Codable Structures ---

// --- Request Structs ---
// These structures match the JSON you want to send. (These are unchanged)

struct RequestBody: Codable {
    let userMeasurements: UserMeasurements
    let clothesData: ClothesData

    // This maps the Swift property names (camelCase)
    // to the JSON property names (snake_case).
    enum CodingKeys: String, CodingKey {
        case userMeasurements = "user_measurements"
        case clothesData = "clothes_data"
    }
}

struct UserMeasurements: Codable {
    let bust: Double
    let waist: Double
    let hips: Double
    let shoulderWidth: Double
    let torso: Double
    let armLength: Double

    enum CodingKeys: String, CodingKey {
        case bust, waist, hips
        case shoulderWidth = "shoulder_width"
        case torso
        case armLength = "arm_length"
    }
}

struct ClothesData: Codable {
    // The key is the size (e.g., "S", "M"), and the value is the measurements
    let blouse: [String: SizeMeasurements]
}

struct SizeMeasurements: Codable {
    let torso: [Double]
    let bust: [Double]
    let armLength: [Double]
    let waist: [Double]

    enum CodingKeys: String, CodingKey {
        case torso, bust
        case armLength = "arm_length"
        case waist
    }
}

// --- Response Structs ---
// These are the NEW structs that match your server's JSON response.

// 1. The top-level object: { "recommendations": ... }
struct ServerResponse: Codable {
    let recommendations: Recommendations
}

// 2. The "recommendations" object, which contains all the fit types
struct Recommendations: Codable {
    let loose: FitRecommendation
    let regular: FitRecommendation
    let slightlyLoose: FitRecommendation
    let slightlyTight: FitRecommendation
    let tight: FitRecommendation
    
    // We need CodingKeys to map the JSON's "kebab-case"
    // to Swift's "camelCase"
    enum CodingKeys: String, CodingKey {
        case loose, regular
        case slightlyLoose = "slightly-loose"
        case slightlyTight = "slightly-tight"
        case tight
    }
}

// 3. The "FitRecommendation" object, which holds the details for one fit type
struct FitRecommendation: Codable {
//    let allSizeScores: [String: Double]
    let bestScore: Double
    let bestSize: String
    let partFits: [String: String]
    
    enum CodingKeys: String, CodingKey {
//        case allSizeScores = "all_size_scores"
        case bestScore = "best_score"
        case bestSize = "best_size"
        case partFits = "part_fits"
    }
}

// --- 2. Create the Network Function ---

// The function now accepts the data as parameters and returns the new ServerResponse
func fetchRecommendations(userMeasurements: UserMeasurements, clothesData: ClothesData) async throws -> ServerResponse {
    let urlString = "http://127.0.0.1:5001/recommend"
    
    guard let url = URL(string: urlString) else {
        print("Error: Invalid URL")
        // Create a custom error to throw
        throw URLError(.badURL)
    }
    
    // --- 4. Encode the Data into JSON ---
    let requestBody: Data
    do {
        // Create the RequestBody from the function parameters
        let requestData = RequestBody(userMeasurements: userMeasurements, clothesData: clothesData)
        
        // --- FIX FOR SHIFTING RESULTS ---
        // Create an encoder
        let encoder = JSONEncoder()
        // Tell the encoder to ALWAYS sort keys alphabetically.
        // This fixes inconsistencies from Swift's Dictionary encoding
        // if the server is fragile and relies on key order.
        encoder.outputFormatting = .sortedKeys
        // --- End Fix ---
        
        requestBody = try encoder.encode(requestData)
        
        // Optional: Print the JSON to confirm it's sorted
        // if let jsonString = String(data: requestBody, encoding: .utf8) {
        //    print("Request JSON (Sorted):\n\(jsonString)")
        // }
        
    } catch {
        print("Error: Failed to encode JSON: \(error)")
        throw error
    }
    
    // --- 5. Configure the URLRequest ---
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = requestBody
    // Set the content type header to tell the server we are sending JSON
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // --- 6. Send the Request ---
    print("Sending request to \(urlString)...")
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the HTTP response status
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status Code: \(httpResponse.statusCode)")
            // You could check for non-200 codes here and throw an error
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to print the error message from the server
                if let responseString = String(data: data, encoding: .utf8) {
                     print("Server Error: \(responseString)")
                }
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
        // Re-throw the error so the calling function (in your SwiftUI view) can catch it
        throw error
    }
}
