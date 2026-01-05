//
//  TagCard.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct TagCard: View {
    let tag: NFCTag
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.title2)
                    .foregroundStyle(tag.isActive ? .orange : .blue)
                
                Spacer()
                
                if tag.isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            Text(tag.name)
                .font(.headline)
                .lineLimit(1)
            
            Text("\(tag.linkedAppTokens.count) Apps")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 160, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8)
        )
    }
}

#Preview {
    HStack {
        TagCard(tag: NFCTag(
            name: "Schreibtisch",
            tagIdentifier: "ABC123",
            linkedAppTokens: ["1", "2", "3"]
        ))
        
        TagCard(tag: NFCTag(
            name: "Schlafzimmer",
            tagIdentifier: "DEF456",
            linkedAppTokens: ["1", "2", "3", "4", "5"],
            isActive: true
        ))
    }
    .padding()
}
