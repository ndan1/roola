//
//  ConfigManager.swift
//  Roola
//
//  Created by Lin Dan Christiano on 25/10/25.
//

import Foundation

struct ConfigManager {
    static func getAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "secrets", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["OPENAI_API_KEY"] as? String else {
            print("Failed to load API key from Config.plist")
            return nil
        }
        return apiKey
    }
    static func getMeasureKey() -> String? {
        guard let path = Bundle.main.path(forResource: "secrets", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["MEASUREMENT_KEY"] as? String else {
            print("Failed to load API key from Config.plist")
            return nil
        }
        return apiKey
    }
    static func getGeminiAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "secrets", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["GEMINI_API_KEY"] as? String else {
            print("Failed to load Gemini API key from Config.plist")
            return nil
        }
        return apiKey
    }
}
