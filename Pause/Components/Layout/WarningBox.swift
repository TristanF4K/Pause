//
//  WarningBox.swift
//  Pause
//
//  Created on 15.01.2026
//  Reusable warning/info box component
//

import SwiftUI

/// Style for warning boxes
enum WarningBoxStyle {
    case warning
    case info
    case error
    case success
    
    var icon: String {
        switch self {
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .error: return "xmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .warning: return PauseColors.warning
        case .info: return PauseColors.accent
        case .error: return PauseColors.error
        case .success: return PauseColors.success
        }
    }
}

/// A reusable warning/info box component
///
/// Usage:
/// ```swift
/// WarningBox(
///     style: .warning,
///     title: "Tag ist aktiv",
///     message: "Du kannst Apps nicht ändern, während der Tag aktiv ist."
/// )
/// ```
struct WarningBox: View {
    let style: WarningBoxStyle
    let icon: String?
    let title: String
    let message: String?
    
    init(
        style: WarningBoxStyle = .warning,
        icon: String? = nil,
        title: String,
        message: String? = nil
    ) {
        self.style = style
        self.icon = icon
        self.title = title
        self.message = message
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon ?? style.icon)
                .font(.system(size: FontSize.base))
                .foregroundColor(style.color)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.system(size: FontSize.sm, weight: .medium))
                    .foregroundColor(style.color)
                
                if let message = message {
                    Text(message)
                        .font(.system(size: FontSize.xs))
                        .foregroundColor(PauseColors.secondaryText)
                }
            }
        }
    }
}

/// A warning box with custom content
///
/// Usage:
/// ```swift
/// WarningBoxWithContent(style: .info, icon: "clock.fill") {
///     VStack(alignment: .leading) {
///         Text("Custom Title")
///         Text("Custom message with more control")
///     }
/// }
/// ```
struct WarningBoxWithContent<Content: View>: View {
    let style: WarningBoxStyle
    let icon: String?
    @ViewBuilder let content: () -> Content
    
    init(
        style: WarningBoxStyle = .warning,
        icon: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.icon = icon
        self.content = content
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon ?? style.icon)
                .font(.system(size: FontSize.base))
                .foregroundColor(style.color)
            
            content()
        }
    }
}

// MARK: - Previews

#Preview("WarningBox Styles") {
    VStack(spacing: Spacing.lg) {
        WarningBox(
            style: .warning,
            title: "Tag ist aktiv",
            message: "Du kannst Apps nicht ändern, während der Tag aktiv ist."
        )
        
        WarningBox(
            style: .info,
            title: "Information",
            message: "Dies ist eine informative Nachricht."
        )
        
        WarningBox(
            style: .error,
            title: "Fehler",
            message: "Ein Fehler ist aufgetreten."
        )
        
        WarningBox(
            style: .success,
            title: "Erfolgreich",
            message: "Aktion wurde erfolgreich ausgeführt."
        )
    }
    .padding()
}

#Preview("WarningBox Custom Icon") {
    VStack(spacing: Spacing.lg) {
        WarningBox(
            style: .warning,
            icon: "tag.fill",
            title: "Tag blockiert Änderungen"
        )
        
        WarningBox(
            style: .info,
            icon: "clock.fill",
            title: "Zeitprofil ist aktiv",
            message: "Das Profil ist gerade aktiv und blockiert Apps."
        )
    }
    .padding()
}

#Preview("WarningBoxWithContent") {
    WarningBoxWithContent(style: .warning, icon: "tag.fill") {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("Custom Warning")
                .font(.system(size: FontSize.sm, weight: .medium))
                .foregroundColor(PauseColors.warning)
            
            Text("Dies ist eine benutzerdefinierte Warnung mit voller Kontrolle über den Inhalt.")
                .font(.system(size: FontSize.xs))
                .foregroundColor(PauseColors.secondaryText)
            
            Button("Details anzeigen") {}
                .font(.system(size: FontSize.xs, weight: .semibold))
                .foregroundColor(PauseColors.accent)
                .padding(.top, Spacing.xxs)
        }
    }
    .padding()
}
