//
//  APIConfiguration.swift
//  sendboats
//
//  Created on 3/23/25.
//

import Foundation

struct APIConfiguration: Codable, Equatable  {
    var serverURL: String
    var username: String
    var password: String
    
    static let defaultConfiguration = APIConfiguration(
        serverURL: "https://send.boats",
        username: "",
        password: ""
    )
}
