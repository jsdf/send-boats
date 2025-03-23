//
//  ConfigurationWarningView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI

struct ConfigurationWarningView: View {
    let isConfigured: Bool
    
    var body: some View {
        if !isConfigured {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("API credentials not configured. Tap the gear icon to set up.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
        }
    }
}

#Preview {
    VStack {
        ConfigurationWarningView(isConfigured: false)
        ConfigurationWarningView(isConfigured: true)
    }
}
