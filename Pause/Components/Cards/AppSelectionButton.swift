//
//  AppSelectionButton.swift
//  Pause
//
//  Created on 15.01.2026
//  Reusable button component for app/category selection
//

import SwiftUI

/// Information about the current selection
struct SelectionInfo {
    let appCount: Int
    let categoryCount: Int
    
    var isEmpty: Bool {
        appCount == 0 && categoryCount == 0
    }
    
    var description: String {
        if isEmpty {
            return "Keine Apps ausgewählt"
        }
        return "\(appCount) \(appCount == 1 ? "App" : "Apps"), \(categoryCount) \(categoryCount == 1 ? "Kategorie" : "Kategorien")"
    }
}

/// A reusable button for app/category selection
///
/// Usage:
/// ```swift
/// AppSelectionButton(
///     title: "Apps auswählen",
///     selectionInfo: SelectionInfo(appCount: 5, categoryCount: 2),
///     isDisabled: tag.isActive
/// ) {
///     showingAppPicker = true
/// }
/// ```
struct AppSelectionButton: View {
    let title: String
    let selectionInfo: SelectionInfo
    let isDisabled: Bool
    let action: () -> Void
    
    init(
        title: String = "Apps auswählen",
        selectionInfo: SelectionInfo,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.selectionInfo = selectionInfo
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(.system(size: FontSize.base, weight: .medium))
                        .foregroundColor(PauseColors.primaryText)
                    
                    Text(selectionInfo.description)
                        .font(.system(size: FontSize.sm))
                        .foregroundColor(selectionInfo.isEmpty ? PauseColors.warning : PauseColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: FontSize.base))
                    .foregroundColor(PauseColors.dimGray)
            }
            .padding(Spacing.lg)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

/// A card-based app selection component with icon and selection info
///
/// Usage:
/// ```swift
/// AppSelectionCard(
///     icon: "app.badge.checkmark",
///     title: "Blockierte Apps",
///     selectionInfo: SelectionInfo(appCount: 5, categoryCount: 2),
///     isDisabled: false
/// ) {
///     showingAppPicker = true
/// }
/// ```
struct AppSelectionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let selectionInfo: SelectionInfo
    let isDisabled: Bool
    let footerText: String?
    let warningTitle: String?
    let warningMessage: String?
    let action: () -> Void
    
    init(
        icon: String = "app.badge.checkmark",
        iconColor: Color = PauseColors.accent,
        title: String,
        selectionInfo: SelectionInfo,
        isDisabled: Bool = false,
        footerText: String? = nil,
        warningTitle: String? = nil,
        warningMessage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.selectionInfo = selectionInfo
        self.isDisabled = isDisabled
        self.footerText = footerText
        self.warningTitle = warningTitle
        self.warningMessage = warningMessage
        self.action = action
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
            
            // Selection Button
            AppSelectionButton(
                selectionInfo: selectionInfo,
                isDisabled: isDisabled,
                action: action
            )
            
            // Warning when disabled
            if isDisabled, let warningTitle = warningTitle {
                Divider()
                    .background(PauseColors.cardBorder)
                
                WarningBox(
                    style: .warning,
                    title: warningTitle,
                    message: warningMessage
                )
                .padding(Spacing.lg)
            }
            
            // Footer
            if !isDisabled, let footerText = footerText {
                Text(footerText)
                    .font(.system(size: FontSize.sm))
                    .foregroundColor(PauseColors.tertiaryText)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
            }
        }
        .card()
    }
}

// MARK: - Previews

#Preview("AppSelectionButton") {
    VStack(spacing: Spacing.lg) {
        AppSelectionButton(
            selectionInfo: SelectionInfo(appCount: 5, categoryCount: 2),
            isDisabled: false
        ) {
            print("Tapped")
        }
        
        AppSelectionButton(
            selectionInfo: SelectionInfo(appCount: 0, categoryCount: 0),
            isDisabled: false
        ) {
            print("Tapped")
        }
        
        AppSelectionButton(
            title: "Apps bearbeiten",
            selectionInfo: SelectionInfo(appCount: 10, categoryCount: 3),
            isDisabled: true
        ) {
            print("Tapped")
        }
    }
    .padding()
}

#Preview("AppSelectionCard") {
    VStack(spacing: Spacing.lg) {
        // Active state
        AppSelectionCard(
            title: "Blockierte Apps",
            selectionInfo: SelectionInfo(appCount: 5, categoryCount: 2),
            isDisabled: false,
            footerText: "Wähle die Apps aus, die blockiert werden sollen."
        ) {
            print("Tapped")
        }
        
        // Disabled with warning
        AppSelectionCard(
            title: "Blockierte Apps",
            selectionInfo: SelectionInfo(appCount: 3, categoryCount: 1),
            isDisabled: true,
            warningTitle: "Tag ist aktiv",
            warningMessage: "Du kannst Apps nicht ändern, während der Tag aktiv ist und Apps blockiert."
        ) {
            print("Tapped")
        }
        
        // No selection
        AppSelectionCard(
            icon: "square.grid.2x2.fill",
            title: "Apps konfigurieren",
            selectionInfo: SelectionInfo(appCount: 0, categoryCount: 0),
            isDisabled: false,
            footerText: "Noch keine Apps ausgewählt."
        ) {
            print("Tapped")
        }
    }
    .padding()
}
