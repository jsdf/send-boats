//
//  ConfigurationManager.swift
//  sendboats
//
//  Created on 3/23/25.
//

import Foundation

class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "apiConfiguration"
    
    func saveConfiguration(_ configuration: APIConfiguration) {
        if let encoded = try? JSONEncoder().encode(configuration) {
            userDefaults.set(encoded, forKey: configKey)
        }
    }
    
    func loadConfiguration() -> APIConfiguration {
        if let data = userDefaults.data(forKey: configKey),
           let configuration = try? JSONDecoder().decode(APIConfiguration.self, from: data) {
            return configuration
        }
        return APIConfiguration.defaultConfiguration
    }
}
