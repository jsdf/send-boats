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
            let originalImage = UIImage(cgImage: cgImage)
            
            // Process the image to ensure it has the correct aspect ratio for social sharing
            return processImageForSocialSharing(originalImage)
        } catch {
            print("Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Processes an image to ensure it has the correct aspect ratio for social sharing
    /// - Parameter image: The original image
    /// - Returns: A processed image with the correct aspect ratio
    private static func processImageForSocialSharing(_ image: UIImage) -> UIImage {
        // Target aspect ratio for social sharing (1.91:1 is optimal for most platforms)
        let targetAspectRatio: CGFloat = 1.91
        
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        let originalAspectRatio = originalWidth / originalHeight
        
        // If the image is already close to the target aspect ratio, return it
        if abs(originalAspectRatio - targetAspectRatio) < 0.1 {
            return image
        }
        
        // For vertical videos (portrait orientation)
        if originalAspectRatio < 1.0 {
            // Create a new context with the target aspect ratio
            let targetWidth = originalWidth
            let targetHeight = originalWidth / targetAspectRatio
            
            // Center crop the image
            let yOffset = (originalHeight - targetHeight) / 2
            
            UIGraphicsBeginImageContextWithOptions(CGSize(width: targetWidth, height: targetHeight), false, 0)
            image.draw(at: CGPoint(x: 0, y: -yOffset))
            let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return croppedImage ?? image
        } 
        // For horizontal videos that are not wide enough
        else if originalAspectRatio < targetAspectRatio {
            // Create a new context with the target aspect ratio
            let targetHeight = originalHeight
            let targetWidth = originalHeight * targetAspectRatio
            
            // Create a new image with letterboxing (black bars on sides)
            UIGraphicsBeginImageContextWithOptions(CGSize(width: targetWidth, height: targetHeight), true, 0)
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(UIColor.black.cgColor)
            context?.fill(CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
            
            // Center the original image
            let xOffset = (targetWidth - originalWidth) / 2
            image.draw(at: CGPoint(x: xOffset, y: 0))
            
            let letterboxedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return letterboxedImage ?? image
        }
        // For horizontal videos that are too wide
        else {
            // Create a new context with the target aspect ratio
            let targetHeight = originalHeight
            let targetWidth = originalHeight * targetAspectRatio
            
            // Center crop the image
            let xOffset = (originalWidth - targetWidth) / 2
            
            UIGraphicsBeginImageContextWithOptions(CGSize(width: targetWidth, height: targetHeight), false, 0)
            image.draw(at: CGPoint(x: -xOffset, y: 0))
            let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return croppedImage ?? image
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
