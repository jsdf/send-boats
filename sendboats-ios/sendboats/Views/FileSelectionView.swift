//
//  FileSelectionView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI

struct FileSelectionView: View {
    @ObservedObject var viewModel: UploadViewModel
    @Binding var showingDocumentPicker: Bool
    @Binding var showingPhotoPicker: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // File selection buttons
            HStack(spacing: 10) {
                Button(action: {
                    showingDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.fill")
                        Text("Files")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showingPhotoPicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text("Photos")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            // Selected file display
            if !viewModel.selectedFileName.isEmpty {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    Text(viewModel.selectedFileName)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.reset()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

// Preview requires a mock ViewModel
#Preview {
    FileSelectionView(
        viewModel: UploadViewModel(),
        showingDocumentPicker: .constant(false),
        showingPhotoPicker: .constant(false)
    )
}
