//
//  ErrorView.swift
//  sendboats
//
//  Created on 3/23/25.
//

import SwiftUI

struct ErrorView: View {
    let errorMessage: String
    
    var body: some View {
        Text("Error: \(errorMessage)")
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
            .padding()
    }
}

#Preview {
    ErrorView(errorMessage: "Something went wrong. Please try again.")
}
