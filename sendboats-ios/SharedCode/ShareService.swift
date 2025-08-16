//
//  ShareService.swift
//  sendboats
//
//  Created on 12/16/24.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit

public class ShareService {
    
    /// Presents a share sheet for the given URL
    /// - Parameters:
    ///   - url: The URL to share
    ///   - sourceView: The source view for iPad popover presentation (optional)
    public static func shareURL(_ url: URL, from sourceView: UIView? = nil) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("ERROR: ShareService - Could not find root view controller")
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            if let sourceView = sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        // Find the topmost view controller to present from
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        topViewController.present(activityViewController, animated: true)
        print("DEBUG: ShareService - Presented share sheet for URL: \(url.absoluteString)")
    }
    
    /// Copies URL to clipboard (fallback functionality)
    /// - Parameter url: The URL to copy
    public static func copyURLToClipboard(_ url: URL?) {
        guard let url = url else { return }
        UIPasteboard.general.string = url.absoluteString
        print("DEBUG: ShareService - Copied URL to clipboard: \(url.absoluteString)")
    }
}

#else

// Non-iOS platforms (macOS, etc.)
public class ShareService {
    public static func shareURL(_ url: URL, from sourceView: Any? = nil) {
        print("DEBUG: ShareService - Share sheet not implemented for this platform, copying to clipboard instead")
        copyURLToClipboard(url)
    }
    
    public static func copyURLToClipboard(_ url: URL?) {
        guard let url = url else { return }
        print("DEBUG: ShareService - Clipboard copy not implemented for this platform.")
        print("DEBUG: ShareService - URL to copy: \(url.absoluteString)")
    }
}

#endif