
//
//  EmptyStateView.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(PauseColors.dimGray)
                .padding(Spacing.lg)
                .background(
                    Circle()
                        .fill(PauseColors.tertiaryBackground)
                )
            
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.system(size: FontSize.lg, weight: .semibold))
                    .foregroundColor(PauseColors.primaryText)
                
                Text(message)
                    .font(.system(size: FontSize.base))
                    .foregroundColor(PauseColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .primaryButton()
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .card()
    }
}

#Preview {
    EmptyStateView(
        icon: "tag",
        title: "Keine Tags",
        message: "Füge deinen ersten NFC Tag hinzu, um zu beginnen.",
        actionTitle: "Tag hinzufügen",
        action: {}
    )
}
