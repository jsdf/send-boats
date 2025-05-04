//
//  ConfigurationManager.swift
//  sendboats
//
//  Created on 3/23/25.
//

import Foundation

class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private let userDefaults: UserDefaults
    private let configKey = "apiConfiguration"
    private let appGroupIdentifier = "group.jsdf.sendboats" // Your App Group Identifier
    private var initialized = false

    private init() {
        // Initialize with the shared UserDefaults suite
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            // Log an error or handle the failure gracefully
            print("ERROR: Unable to initialize shared UserDefaults for App Group \(appGroupIdentifier)")
            // Fallback to standard UserDefaults, though this won't work for sharing
            fatalError("ERROR: Unable to initialize shared UserDefaults for App Group \(appGroupIdentifier). Ensure the App Group is configured correctly.")
            return
        }
        userDefaults = sharedDefaults
        initialized = true
    }
    
    func saveConfiguration(_ configuration: APIConfiguration) {
        // Assert during development that we are not saving an invalid configuration
        assert(initialized, "ConfigurationManager is not initialized properly.")
        
        do {
            let encoded = try JSONEncoder().encode(configuration)
            userDefaults.set(encoded, forKey: configKey)
            userDefaults.synchronize() // Ensure data is saved immediately
            
            // Debugging test: Load the configuration back and check if it is the same
            if let data = userDefaults.data(forKey: configKey) {
            let loadedConfiguration = try JSONDecoder().decode(APIConfiguration.self, from: data)
            if loadedConfiguration == configuration {
                print("DEBUG: Configuration saved and loaded successfully. They match.")
            } else {
                print("DEBUG: Configuration mismatch after saving and loading.")
            }
            } else {
            print("DEBUG: Failed to load configuration data after saving.")
            }
        } catch {
            print("ERROR: Failed to save configuration - \(error.localizedDescription)")
        }
    }
    
    func loadConfiguration() -> APIConfiguration {
        if let data = userDefaults.data(forKey: configKey) {
            do {
                let configuration = try JSONDecoder().decode(APIConfiguration.self, from: data)
                assert(initialized, "ConfigurationManager is not initialized properly.")
                
                return configuration
            } catch {
                print("ERROR: Failed to decode configuration - \(error.localizedDescription)")
            }
        } else {
            print("ERROR: No configuration data found for key \(configKey)")
        }
        // Return a default configuration if loading fails
        return APIConfiguration.defaultConfiguration
    }
}
