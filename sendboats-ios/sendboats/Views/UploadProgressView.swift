//
//  UploadProgressView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI

struct UploadProgressView: View {
    @ObservedObject var viewModel: UploadViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // Progress bar
            ProgressView(value: viewModel.uploadProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 8)
                .padding(.horizontal)
            
            // Percentage text
            Text("\(Int(viewModel.uploadProgress * 100))%")
                .font(.headline)
                .foregroundColor(.blue)
            
            // Status text
            Text("Uploading...")
                .foregroundColor(.secondary)
                .font(.subheadline)
                .padding(.top, 5)
            
            // File name (optional)
            if !viewModel.selectedFileName.isEmpty {
                Text(viewModel.selectedFileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.top, 5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    UploadProgressView(viewModel: UploadViewModel())
}
