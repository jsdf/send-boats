//
//  ServerSettingsView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI

struct ServerSettingsView: View {
    @ObservedObject var viewModel: UploadViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Configuration")) {
                    TextField("Server URL", text: $viewModel.serverURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                    
                    TextField("Username (required)", text: $viewModel.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password (required)", text: $viewModel.password)
                }
                
                Section(header: Text("Information"), footer: Text("Username and password are required to upload files.")) {
                    Text("Configure your API credentials to upload files to the server.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Save") {
                        viewModel.saveConfiguration()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Server Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ServerSettingsView(viewModel: UploadViewModel())
}
