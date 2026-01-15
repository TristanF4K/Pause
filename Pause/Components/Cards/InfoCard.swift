//
//  InfoCard.swift
//  Pause
//
//  Created on 15.01.2026
//  Reusable card component with icon, title, and custom content
//

import SwiftUI

/// A reusable card component with an icon, title, and custom content
///
/// Usage:
/// ```swift
/// InfoCard(title: "Tag-Info", icon: "info.circle.fill") {
///     VStack(alignment: .leading, spacing: 12) {
///         InfoRow(label: "Name", value: tag.name)
///         InfoRow(label: "ID", value: tag.id)
///     }
/// }
/// ```
struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content
    
    init(
        title: String,
        icon: String,
        iconColor: Color = PauseColors.accent,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: FontSize.lg))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(PauseColors.primaryText)
                Spacer()
            }
            .padding(Spacing.lg)
            
            Divider()
                .background(PauseColors.cardBorder)
            
            // Content
            content()
                .padding(Spacing.lg)
        }
        .card()
    }
}

// MARK: - Preview

#Preview("Basic InfoCard") {
    InfoCard(title: "Tag-Info", icon: "info.circle.fill") {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InfoRow(label: "Name", value: "Arbeitszeit")
            InfoRow(label: "ID", value: "ABC123")
            InfoRow(label: "Status", value: "Aktiv")
        }
    }
    .padding()
}

#Preview("InfoCard with Custom Icon Color") {
    InfoCard(title: "Warnung", icon: "exclamationmark.triangle.fill", iconColor: PauseColors.warning) {
        Text("Dies ist eine Warnung")
            .font(.system(size: FontSize.base))
            .foregroundColor(PauseColors.secondaryText)
    }
    .padding()
}
