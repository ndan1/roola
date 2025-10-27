//
//  APIResultResponse.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 24/10/25.
//

struct RequestBody: Codable {
    let userMeasurements: UserMeasurements
    let clothesData: ClothesData

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
    let item: [String: [String: SizeMeasurements]]

    // Custom initializer for creating ClothesData with a dictionary
    init(item: [String: [String: SizeMeasurements]]) {
        self.item = item
    }

    // Custom encoding to encode the dictionary directly under clothes_data
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(item)
    }

    // Custom decoding to decode the dictionary directly
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        item = try container.decode([String: [String: SizeMeasurements]].self)
    }
}

struct SizeMeasurements: Codable {
    let torso: [Double]
    let bust: [Double]
    let armLength: [Double]?
    let waist: [Double]?

    enum CodingKeys: String, CodingKey {
        case torso, bust
        case armLength = "arm_length"
        case waist
    }
}
