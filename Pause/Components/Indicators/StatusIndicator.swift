//
//  StatusIndicator.swift
//  Pause
//
//  Created on 15.01.2026
//  Reusable status indicator component
//

import SwiftUI

/// Style for status indicators
enum StatusStyle {
    case active
    case inactive
    case enabled
    case disabled
    case warning
    case error
    case success
    
    var color: Color {
        switch self {
        case .active, .success: return PauseColors.success
        case .inactive, .disabled: return PauseColors.dimGray
        case .enabled: return PauseColors.accent
        case .warning: return PauseColors.warning
        case .error: return PauseColors.error
        }
    }
    
    var defaultLabel: String {
        switch self {
        case .active: return "Aktiv"
        case .inactive: return "Inaktiv"
        case .enabled: return "Aktiviert"
        case .disabled: return "Deaktiviert"
        case .warning: return "Warnung"
        case .error: return "Fehler"
        case .success: return "Erfolgreich"
        }
    }
}

/// A reusable status indicator with a colored circle and label
///
/// Usage:
/// ```swift
/// StatusIndicator(style: .active)
/// StatusIndicator(style: .inactive, label: "Nicht aktiv")
/// StatusIndicator(style: .active, size: 10, fontSize: .md)
/// ```
struct StatusIndicator: View {
    let style: StatusStyle
    let label: String?
    let size: CGFloat
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    
    init(
        style: StatusStyle,
        label: String? = nil,
        size: CGFloat = 8,
        fontSize: CGFloat = FontSize.base,
        fontWeight: Font.Weight = .medium
    ) {
        self.style = style
        self.label = label
        self.size = size
        self.fontSize = fontSize
        self.fontWeight = fontWeight
    }
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(style.color)
                .frame(width: size, height: size)
            
            Text(label ?? style.defaultLabel)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(style.color)
        }
    }
}

/// A pulsing status indicator (for active states)
///
/// Usage:
/// ```swift
/// PulsingStatusIndicator(
///     style: .active,
///     label: "Gerade aktiv"
/// )
/// ```
struct PulsingStatusIndicator: View {
    let style: StatusStyle
    let label: String?
    let size: CGFloat
    let fontSize: CGFloat
    
    @State private var isPulsing = false
    
    init(
        style: StatusStyle,
        label: String? = nil,
        size: CGFloat = 10,
        fontSize: CGFloat = FontSize.lg
    ) {
        self.style = style
        self.label = label
        self.size = size
        self.fontSize = fontSize
    }
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(style.color)
                .frame(width: size, height: size)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.7 : 1.0)
                .animation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                    value: isPulsing
                )
            
            Text(label ?? style.defaultLabel)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundColor(style.color)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

/// A large status badge (for cards/headers)
///
/// Usage:
/// ```swift
/// StatusBadge(
///     style: .active,
///     label: "Aktiv und blockiert"
/// )
/// ```
struct StatusBadge: View {
    let style: StatusStyle
    let label: String
    let icon: String?
    
    init(
        style: StatusStyle,
        label: String? = nil,
        icon: String? = nil
    ) {
        self.style = style
        self.label = label ?? style.defaultLabel
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: FontSize.sm))
            }
            
            Text(label)
                .font(.system(size: FontSize.sm, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(style.color)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Previews

#Preview("StatusIndicator Basic") {
    VStack(alignment: .leading, spacing: Spacing.lg) {
        StatusIndicator(style: .active)
        StatusIndicator(style: .inactive)
        StatusIndicator(style: .enabled)
        StatusIndicator(style: .disabled)
        StatusIndicator(style: .warning)
        StatusIndicator(style: .error)
        StatusIndicator(style: .success)
    }
    .padding()
}

#Preview("StatusIndicator Custom") {
    VStack(alignment: .leading, spacing: Spacing.lg) {
        StatusIndicator(
            style: .active,
            label: "Gerade aktiv",
            size: 10,
            fontSize: FontSize.lg,
            fontWeight: .semibold
        )
        
        StatusIndicator(
            style: .inactive,
            label: "Nicht verfügbar",
            size: 6,
            fontSize: FontSize.sm
        )
    }
    .padding()
}

#Preview("PulsingStatusIndicator") {
    VStack(spacing: Spacing.xl) {
        PulsingStatusIndicator(
            style: .active,
            label: "Gerade aktiv"
        )
        
        PulsingStatusIndicator(
            style: .warning,
            label: "Warnung aktiv",
            size: 12,
            fontSize: FontSize.md
        )
    }
    .padding()
}

#Preview("StatusBadge") {
    VStack(spacing: Spacing.md) {
        StatusBadge(style: .active)
        StatusBadge(style: .active, label: "Aktiv und blockiert", icon: "checkmark.circle.fill")
        StatusBadge(style: .warning, label: "Warnung", icon: "exclamationmark.triangle.fill")
        StatusBadge(style: .inactive, label: "Deaktiviert", icon: "xmark.circle")
    }
    .padding()
}

#Preview("Combined in InfoRow") {
    VStack(spacing: Spacing.md) {
        InfoRowWithView(label: "Status") {
            StatusIndicator(style: .active)
        }
        
        InfoRowWithView(label: "Status") {
            StatusIndicator(style: .inactive)
        }
        
        InfoRowWithView(label: "Aktueller Status") {
            PulsingStatusIndicator(
                style: .active,
                label: "Gerade aktiv",
                size: 8,
                fontSize: FontSize.base
            )
        }
    }
    .padding()
}
