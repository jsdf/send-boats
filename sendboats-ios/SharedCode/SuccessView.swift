//
//  SuccessView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI

public struct SuccessView: View {
    @ObservedObject public var viewModel: UploadViewModel
    @State private var showCopiedMessage = false
    public var isShareExtensionContext: Bool = false

    public init(viewModel: UploadViewModel, isShareExtensionContext: Bool = false) {
        self.viewModel = viewModel
        self.isShareExtensionContext = isShareExtensionContext
    }

    public var body: some View {
        ScrollView { // Added ScrollView
            VStack(spacing: 20) {
                // Image view removed

                Text("Upload Successful!")
                .font(.title)
                .fontWeight(.bold)

            if let viewURL = viewModel.uploadResult?.viewURL {
                URLDisplayView(title: "View URL:", url: viewURL, onCopy: {
                    UIPasteboard.general.string = viewURL.absoluteString
                })
            }

            if let fullViewURL = viewModel.uploadResult?.fullViewURL {
                URLDisplayView(title: "Full URL:", url: fullViewURL, onCopy: {
                    UIPasteboard.general.string = fullViewURL.absoluteString
                })
            }

            if !isShareExtensionContext {
                Button("Upload Another File") {
                    viewModel.reset()
                }
                .padding()
                .buttonStyle(.borderedProminent)
            }
        }
        .padding() // Inner padding for VStack content
    } // End ScrollView
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
    .cornerRadius(15)
    .shadow(radius: 5)
    .padding() // Outer padding for the whole view container
}
}
