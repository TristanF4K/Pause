//
//  StatusCardView.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct StatusCardView: View {
    let isBlocking: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 36))
                    .foregroundStyle(statusColor)
            }
            
            // Status Text
            VStack(spacing: 4) {
                Text(statusTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8)
        )
    }
    
    private var statusIcon: String {
        isBlocking ? "lock.shield.fill" : "lock.open.fill"
    }
    
    private var statusColor: Color {
        isBlocking ? .orange : .green
    }
    
    private var statusTitle: String {
        isBlocking ? "Blockiert" : "Entsperrt"
    }
    
    private var statusMessage: String {
        isBlocking ? "Apps sind aktuell gesperrt" : "Tippe Tag zum Aktivieren"
    }
}

#Preview("Unlocked") {
    StatusCardView(isBlocking: false)
        .padding()
}

#Preview("Blocked") {
    StatusCardView(isBlocking: true)
        .padding()
}
