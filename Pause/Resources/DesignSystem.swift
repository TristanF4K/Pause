//
//  DesignSystem.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

enum PauseColors {
    static let timberwolf = Color(hex: "CECDC7")
    static let jet = Color(hex: "1C1C19")
    static let dimGray = Color(hex: "575855")
    
    static let background = jet
    static let secondaryBackground = Color(hex: "262623")
    static let tertiaryBackground = dimGray.opacity(0.15)
    
    static let primaryText = timberwolf
    static let secondaryText = timberwolf.opacity(0.7)
    static let tertiaryText = timberwolf.opacity(0.5)
    
    static let accent = timberwolf
    static let accentHover = timberwolf.opacity(0.8)
    
    static let success = Color(hex: "4CAF50")
    static let warning = Color(hex: "FF9800")
    static let error = Color(hex: "F44336")
    
    static let cardBackground = secondaryBackground
    static let cardBorder = dimGray.opacity(0.3)
    
    static let buttonPrimary = timberwolf
    static let buttonSecondary = dimGray
    static let buttonText = jet
    static let buttonSecondaryText = timberwolf
    
    static let tagActive = success.opacity(0.2)
    static let tagInactive = dimGray.opacity(0.2)
}

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 9999
}

enum FontSize {
    static let xs: CGFloat = 11
    static let sm: CGFloat = 13
    static let base: CGFloat = 15
    static let md: CGFloat = 17
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}

struct CardModifier: ViewModifier {
    var isInteractive: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(PauseColors.cardBackground)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(PauseColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .scaleEffect(isInteractive ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isInteractive)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: FontSize.md, weight: .semibold))
            .foregroundColor(PauseColors.buttonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(configuration.isPressed ? PauseColors.accentHover : PauseColors.buttonPrimary)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: FontSize.md, weight: .medium))
            .foregroundColor(PauseColors.buttonSecondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(PauseColors.buttonSecondary, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(configuration.isPressed ? PauseColors.buttonSecondary.opacity(0.1) : Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: FontSize.base, weight: .medium))
            .foregroundColor(configuration.isPressed ? PauseColors.accentHover : PauseColors.accent)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func card(isInteractive: Bool = false) -> some View {
        self.modifier(CardModifier(isInteractive: isInteractive))
    }
    
    func primaryButton() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButton() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    func ghostButton() -> some View {
        self.buttonStyle(GhostButtonStyle())
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - SectionHeader moved to Components/Layout/SectionHeader.swift
// This was causing duplicate declaration errors.
// The new SectionHeader has more features (icons, actions, etc.)