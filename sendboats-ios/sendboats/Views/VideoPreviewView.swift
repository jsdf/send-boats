//
//  VideoPreviewView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI
import UIKit

struct VideoPreviewView: View {
    @ObservedObject var viewModel: UploadViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            if viewModel.uploadState == .generatingPreview {
                Text("Generating video preview...")
            } else {
                Text("No video preview available")
            }
        }
        .padding(.bottom, 10)
    }
}

// Preview would require mock data
#Preview {
    // Create a mock ViewModel for the preview with a preview state
    let viewModel = UploadViewModel()
    // You would need to generate a mock UIImage for the thumbnail here
    // For simplicity, we'll just show the "No video preview available" text in the preview
    
    return Text("VideoPreviewView requires video thumbnails to display properly")
        .padding()
}
