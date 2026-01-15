//
//  SectionHeader.swift
//  Pause
//
//  Created on 15.01.2026
//  Reusable section header component
//

import SwiftUI

/// A reusable section header with optional subtitle
///
/// Usage:
/// ```swift
/// SectionHeader(title: "Tags")
/// SectionHeader(title: "Zeitprofile", subtitle: "3 aktiv")
/// SectionHeader(title: "Einstellungen", icon: "gearshape.fill")
/// ```
struct SectionHeader: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    
    init(
        icon: String? = nil,
        iconColor: Color = PauseColors.accent,
        title: String,
        subtitle: String? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: FontSize.base))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.system(size: FontSize.base, weight: .semibold))
                .foregroundColor(PauseColors.tertiaryText)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: FontSize.sm))
                    .foregroundColor(PauseColors.dimGray)
            }
            
            Spacer()
        }
    }
}

/// A section header with an action button
///
/// Usage:
/// ```swift
/// SectionHeaderWithAction(
///     title: "Tags",
///     actionTitle: "Hinzufügen",
///     actionIcon: "plus"
/// ) {
///     // Action
/// }
/// ```
struct SectionHeaderWithAction: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let actionIcon: String?
    let action: () -> Void
    
    init(
        icon: String? = nil,
        iconColor: Color = PauseColors.accent,
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        actionIcon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.actionIcon = actionIcon
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: FontSize.base))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.system(size: FontSize.base, weight: .semibold))
                .foregroundColor(PauseColors.tertiaryText)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: FontSize.sm))
                    .foregroundColor(PauseColors.dimGray)
            }
            
            Spacer()
            
            Button(action: action) {
                HStack(spacing: Spacing.xxs) {
                    if let actionIcon = actionIcon {
                        Image(systemName: actionIcon)
                            .font(.system(size: FontSize.sm))
                    }
                    if let actionTitle = actionTitle {
                        Text(actionTitle)
                            .font(.system(size: FontSize.sm, weight: .semibold))
                    }
                }
                .foregroundColor(PauseColors.accent)
            }
        }
    }
}

// MARK: - Previews

#Preview("SectionHeader Basic") {
    VStack(spacing: Spacing.xl) {
        SectionHeader(title: "Tags")
        SectionHeader(title: "Zeitprofile", subtitle: "3 aktiv")
        SectionHeader(icon: "tag.fill", title: "Meine Tags")
        SectionHeader(
            icon: "clock.fill",
            iconColor: PauseColors.warning,
            title: "Zeitprofile",
            subtitle: "2 von 5 aktiv"
        )
    }
    .padding()
}

#Preview("SectionHeaderWithAction") {
    VStack(spacing: Spacing.xl) {
        SectionHeaderWithAction(
            title: "Tags",
            actionTitle: "Hinzufügen",
            actionIcon: "plus"
        ) {
            print("Add tapped")
        }
        
        SectionHeaderWithAction(
            icon: "clock.fill",
            title: "Zeitprofile",
            subtitle: "3 aktiv",
            actionIcon: "plus"
        ) {
            print("Add tapped")
        }
        
        SectionHeaderWithAction(
            icon: "gearshape.fill",
            iconColor: PauseColors.dimGray,
            title: "Einstellungen",
            actionTitle: "Bearbeiten"
        ) {
            print("Edit tapped")
        }
    }
    .padding()
}

#Preview("In Context") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            SectionHeader(title: "Blockierte Apps")
                .padding(.horizontal, Spacing.md)
            
            VStack(spacing: Spacing.md) {
                ForEach(0..<3) { _ in
                    Text("App Item")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .card()
                }
            }
            .padding(.horizontal, Spacing.md)
            
            SectionHeaderWithAction(
                title: "Zeitprofile",
                subtitle: "2 aktiv",
                actionTitle: "Neu",
                actionIcon: "plus"
            ) {
                print("Add profile")
            }
            .padding(.horizontal, Spacing.md)
            
            VStack(spacing: Spacing.md) {
                ForEach(0..<2) { _ in
                    Text("Profile Item")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .card()
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.lg)
    }
}
