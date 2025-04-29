//
//  VideoConverter.swift
//  sendboats
//
//  Created on 4/29/25.
//

import Foundation
import AVFoundation
import UIKit

enum VideoConverterError: Error {
    case invalidInput
    case exportFailed(String)
    case cancelled
    
    var localizedDescription: String {
        switch self {
        case .invalidInput:
            return "Invalid input file"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        case .cancelled:
            return "Conversion was cancelled"
        }
    }
}

class VideoConverter {
    
    /// Converts a video file to MP4 format
    /// - Parameters:
    ///   - inputURL: The URL of the input video file
    ///   - progressHandler: Optional closure to report conversion progress (0.0 to 1.0)
    /// - Returns: URL of the converted MP4 file
    static func convertToMP4(inputURL: URL, progressHandler: ((Double) -> Void)? = nil) async throws -> URL {
        // Create asset from input URL
        let asset = AVAsset(url: inputURL)
        
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoConverterError.invalidInput
        }
        
        // Create a temporary file URL for the output
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        
        // Configure export session
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Start export and monitor progress
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                // Set up progress monitoring
                if let progressHandler = progressHandler {
                    // Create a timer to periodically check progress
                    let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                        let progress = exportSession.progress
                        DispatchQueue.main.async {
                            progressHandler(Double(progress))
                        }
                        
                        // If export is complete or failed, invalidate timer
                        if exportSession.status == .completed || exportSession.status == .failed || exportSession.status == .cancelled {
                            timer.invalidate()
                        }
                    }
                    
                    // Make sure the timer fires on the current run loop
                    RunLoop.current.add(progressTimer, forMode: .common)
                }
                
                // Start export
                exportSession.exportAsynchronously {
                    switch exportSession.status {
                    case .completed:
                        continuation.resume(returning: outputURL)
                    case .failed:
                        let error = exportSession.error ?? VideoConverterError.exportFailed("Unknown error")
                        continuation.resume(throwing: VideoConverterError.exportFailed(error.localizedDescription))
                    case .cancelled:
                        continuation.resume(throwing: VideoConverterError.cancelled)
                    default:
                        continuation.resume(throwing: VideoConverterError.exportFailed("Unexpected status: \(exportSession.status)"))
                    }
                }
            }
        } onCancel: {
            // Cancel the export if the task is cancelled
            exportSession.cancelExport()
        }
    }
    
    /// Checks if a file is a MOV format that needs conversion
    /// - Parameter fileURL: The URL of the file to check
    /// - Returns: True if the file is a MOV that should be converted
    static func shouldConvertFile(_ fileURL: URL) -> Bool {
        // Check file extension
        let fileExtension = fileURL.pathExtension.lowercased()
        return fileExtension == "mov"
    }
}
