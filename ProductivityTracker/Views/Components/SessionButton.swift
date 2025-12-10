//
//  SessionButton.swift
//  ProductivityTracker
//
//  Created on 10 December 2025.
//

import SwiftUI

struct SessionButton: View {
    let isTracking: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isTracking ? "stop.fill" : "play.fill")
                    .font(.title3)
                
                Text(isTracking ? "Stop Session" : "Start Session")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(isTracking ? .red : .green)
    }
}
