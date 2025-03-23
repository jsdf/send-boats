//
//  UploadButtonView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI

struct UploadButtonView: View {
    @ObservedObject var viewModel: UploadViewModel
    
    var body: some View {
        Button(action: {
            Task {
                viewModel.setupAPIClient()
                await viewModel.uploadFile()
            }
        }) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                Text("Upload")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.username.isEmpty || viewModel.password.isEmpty ? Color.gray : Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(viewModel.uploadState == .generatingPreviews ||
                  viewModel.username.isEmpty ||
                  viewModel.password.isEmpty)
        .padding(.horizontal)
    }
}

#Preview {
    UploadButtonView(viewModel: UploadViewModel())
        .previewLayout(.sizeThatFits)
}
