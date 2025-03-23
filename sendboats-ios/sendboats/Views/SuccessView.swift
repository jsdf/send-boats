//
//  SuccessView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI

struct SuccessView: View {
    @ObservedObject var viewModel: UploadViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Upload Successful!")
                .foregroundColor(.green)
                .fontWeight(.bold)
                .font(.headline)
            
            // View URL
            if let viewURL = viewModel.viewURL {
                URLDisplayView(
                    title: "View URL:",
                    url: viewURL,
                    onCopy: { viewModel.copyURLToClipboard(viewURL) }
                )
            }
            
            // Full View URL
            if let fullViewURL = viewModel.fullViewURL {
                URLDisplayView(
                    title: "Full View URL:",
                    url: fullViewURL,
                    onCopy: { viewModel.copyURLToClipboard(fullViewURL) }
                )
            }
            
            // New upload button
            Button(action: {
                viewModel.reset()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("New Upload")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

#Preview {
    // This preview requires mock URLs
    let viewModel = UploadViewModel()
    // Mock the URLs for preview
    return SuccessView(viewModel: viewModel)
        .onAppear {
            viewModel.fullViewURL = URL(string: "https://example.com/full/12345")
            viewModel.viewURL = URL(string: "https://example.com/view/12345")
        }
}
