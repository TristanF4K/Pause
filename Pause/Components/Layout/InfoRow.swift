//
//  InfoRow.swift
//  Pause
//
//  Created on 15.01.2026
//  Reusable row component for displaying label-value pairs
//

import SwiftUI

/// A reusable row component for displaying label-value pairs
///
/// Usage:
/// ```swift
/// InfoRow(label: "Name", value: "Arbeitszeit")
/// InfoRow(label: "Status", value: "Aktiv", valueColor: .green)
/// ```
struct InfoRow: View {
    let label: String
    let value: String
    let valueColor: Color
    let valueWeight: Font.Weight
    
    init(
        label: String,
        value: String,
        valueColor: Color = PauseColors.primaryText,
        valueWeight: Font.Weight = .medium
    ) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.valueWeight = valueWeight
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: FontSize.base))
                .foregroundColor(PauseColors.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: FontSize.base, weight: valueWeight))
                .foregroundColor(valueColor)
        }
    }
}

/// A reusable row component with a custom value view
///
/// Usage:
/// ```swift
/// InfoRowWithView(label: "Status") {
///     HStack(spacing: 4) {
///         Circle().fill(Color.green).frame(width: 8, height: 8)
///         Text("Aktiv")
///     }
/// }
/// ```
struct InfoRowWithView<ValueView: View>: View {
    let label: String
    @ViewBuilder let valueView: () -> ValueView
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: FontSize.base))
                .foregroundColor(PauseColors.secondaryText)
            Spacer()
            valueView()
        }
    }
}

// MARK: - Previews

#Preview("InfoRow Basic") {
    VStack(spacing: Spacing.md) {
        InfoRow(label: "Name", value: "Arbeitszeit")
        InfoRow(label: "ID", value: "ABC123")
        InfoRow(label: "Status", value: "Aktiv", valueColor: PauseColors.success)
    }
    .padding()
}

#Preview("InfoRowWithView") {
    VStack(spacing: Spacing.md) {
        InfoRowWithView(label: "Status") {
            HStack(spacing: 4) {
                Circle()
                    .fill(PauseColors.success)
                    .frame(width: 8, height: 8)
                Text("Aktiv")
                    .font(.system(size: FontSize.base, weight: .medium))
                    .foregroundColor(PauseColors.success)
            }
        }
        
        InfoRowWithView(label: "Apps") {
            Text("5 Apps, 2 Kategorien")
                .font(.system(size: FontSize.base))
                .foregroundColor(PauseColors.secondaryText)
        }
    }
    .padding()
}
