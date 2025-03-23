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
            if case .generatingPreviews = viewModel.uploadState {
                VStack(spacing: 5) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Generating video previews...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if !viewModel.videoThumbnails.isEmpty {
                Text("Select a preview image:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<viewModel.videoThumbnails.count, id: \.self) { index in
                            VStack {
                                Image(uiImage: viewModel.videoThumbnails[index].image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 160, height: 90)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(index == viewModel.selectedThumbnailIndex ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        viewModel.selectedThumbnailIndex = index
                                    }
                                
                                Text(VideoThumbnailGenerator.formatTimestamp(viewModel.videoThumbnails[index].timestamp))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 10)
    }
}

// Preview would require mock data
#Preview {
    Text("VideoPreviewView requires video thumbnails to display properly")
        .padding()
}
