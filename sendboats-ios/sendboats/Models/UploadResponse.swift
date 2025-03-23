//
//  UploadResponse.swift
//  sendboats
//
//  Created on 3/23/25.
//

import Foundation

struct UploadResponse: Codable {
    let key: String
    let filename: String
    let filetype: String
    let hasPreview: Bool
    
    enum CodingKeys: String, CodingKey {
        case key
        case filename
        case filetype
        case hasPreview = "hasPreview"
    }
}
