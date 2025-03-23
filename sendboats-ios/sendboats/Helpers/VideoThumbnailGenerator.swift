//
//  VideoThumbnailGenerator.swift
//  sendboats
//
//  Created on 3/23/25.
//

import AVFoundation
import UIKit

struct VideoThumbnail {
    let image: UIImage
    let timestamp: Double
}

class VideoThumbnailGenerator {
    
    /// Generates multiple thumbnails from a video file at evenly distributed timestamps
    /// - Parameters:
    ///   - videoURL: The URL of the video file
    ///   - count: Number of thumbnails to generate (default: 3)
    /// - Returns: Array of VideoThumbnail objects containing the image and timestamp
    static func generateThumbnails(from videoURL: URL, count: Int = 3) async throws -> [VideoThumbnail] {
        let asset = AVAsset(url: videoURL)
        
        // Get video duration
        let durationSeconds = try await asset.load(.duration).seconds
        
        // Generate thumbnails at evenly distributed timestamps
        var thumbnails: [VideoThumbnail] = []
        
        for i in 0..<count {
            // Calculate timestamp (skip the very beginning and end)
            let percentage = Double(i + 1) / Double(count + 1)
            let timestamp = durationSeconds * percentage
            
            // Generate thumbnail at this timestamp
            if let image = try await generateThumbnail(from: asset, at: timestamp) {
                thumbnails.append(VideoThumbnail(image: image, timestamp: timestamp))
            }
        }
        
        return thumbnails
    }
    
    /// Generates a single thumbnail from a video asset at the specified timestamp
    /// - Parameters:
    ///   - asset: The video asset
    ///   - timestamp: The timestamp in seconds
    /// - Returns: UIImage thumbnail or nil if generation failed
    private static func generateThumbnail(from asset: AVAsset, at timestamp: Double) async throws -> UIImage? {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        
        // Set maximum size to maintain aspect ratio but limit dimensions
        imageGenerator.maximumSize = CGSize(width: 1280, height: 720)
        
        let time = CMTime(seconds: timestamp, preferredTimescale: 600)
        
        do {
            let cgImage = try await imageGenerator.image(at: time).image
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Converts a UIImage to JPEG data with the specified quality
    /// - Parameters:
    ///   - image: The UIImage to convert
    ///   - quality: JPEG compression quality (0.0 to 1.0, default: 0.7)
    /// - Returns: JPEG data or nil if conversion failed
    static func imageToJPEGData(_ image: UIImage, quality: CGFloat = 0.7) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    /// Formats a timestamp in seconds to a MM:SS string
    /// - Parameter seconds: The timestamp in seconds
    /// - Returns: Formatted time string (MM:SS)
    static func formatTimestamp(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
