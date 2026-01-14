//
//  SettingsView.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct SettingsView: View {
    // MARK: - Environment Dependencies
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationStack {
            ZStack {
                PauseColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Berechtigungen Section
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Berechtigungen")
                                .font(.system(size: FontSize.base, weight: .semibold))
                                .foregroundColor(PauseColors.tertiaryText)
                                .padding(.horizontal, Spacing.md)
                            
                            VStack(spacing: 0) {
                                HStack(spacing: Spacing.md) {
                                    Image(systemName: "hourglass")
                                        .font(.system(size: FontSize.lg))
                                        .foregroundColor(PauseColors.accent)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                                        Text("Screen Time Zugriff")
                                            .font(.system(size: FontSize.base, weight: .medium))
                                            .foregroundColor(PauseColors.primaryText)
                                        
                                        if !appState.isAuthorized {
                                            Text("Pause. benötigt Zugriff auf Screen Time, um Apps zu blockieren.")
                                                .font(.system(size: FontSize.sm))
                                                .foregroundColor(PauseColors.secondaryText)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if appState.isAuthorized {
                                        HStack(spacing: Spacing.xxs) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: FontSize.base))
                                                .foregroundColor(PauseColors.success)
                                            Text("Erlaubt")
                                                .font(.system(size: FontSize.sm))
                                                .foregroundColor(PauseColors.secondaryText)
                                        }
                                    } else {
                                        Text("Nicht erlaubt")
                                            .font(.system(size: FontSize.sm, weight: .medium))
                                            .foregroundColor(PauseColors.warning)
                                    }
                                }
                                .padding(Spacing.md)
                            }
                            .card()
                        }
                        
                        // App-Info Section
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("App-Info")
                                .font(.system(size: FontSize.base, weight: .semibold))
                                .foregroundColor(PauseColors.tertiaryText)
                                .padding(.horizontal, Spacing.md)
                            
                            VStack(spacing: 0) {
                                // Version
                                HStack(spacing: Spacing.md) {
                                    Image(systemName: "app.badge")
                                        .font(.system(size: FontSize.lg))
                                        .foregroundColor(PauseColors.accent)
                                        .frame(width: 32)
                                    
                                    Text("Version")
                                        .font(.system(size: FontSize.base))
                                        .foregroundColor(PauseColors.primaryText)
                                    
                                    Spacer()
                                    
                                    Text("1.0.0")
                                        .font(.system(size: FontSize.base))
                                        .foregroundColor(PauseColors.secondaryText)
                                }
                                .padding(Spacing.md)
                                
                                Divider()
                                    .background(PauseColors.cardBorder)
                                    .padding(.horizontal, Spacing.md)
                                
                                // Registrierte Tags
                                HStack(spacing: Spacing.md) {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: FontSize.lg))
                                        .foregroundColor(PauseColors.accent)
                                        .frame(width: 32)
                                    
                                    Text("Registrierte Tags")
                                        .font(.system(size: FontSize.base))
                                        .foregroundColor(PauseColors.primaryText)
                                    
                                    Spacer()
                                    
                                    Text("\(appState.registeredTags.count)")
                                        .font(.system(size: FontSize.base, weight: .semibold))
                                        .foregroundColor(PauseColors.accent)
                                }
                                .padding(Spacing.md)
                                
                                Divider()
                                    .background(PauseColors.cardBorder)
                                    .padding(.horizontal, Spacing.md)
                                
                                // Zeitprofile
                                HStack(spacing: Spacing.md) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: FontSize.lg))
                                        .foregroundColor(PauseColors.accent)
                                        .frame(width: 32)
                                    
                                    Text("Zeitprofile")
                                        .font(.system(size: FontSize.base))
                                        .foregroundColor(PauseColors.primaryText)
                                    
                                    Spacer()
                                    
                                    Text("\(appState.timeProfiles.count)")
                                        .font(.system(size: FontSize.base, weight: .semibold))
                                        .foregroundColor(PauseColors.accent)
                                }
                                .padding(Spacing.md)
                            }
                            .card()
                        }
                        
                        // Hilfe & Support Section
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Hilfe & Support")
                                .font(.system(size: FontSize.base, weight: .semibold))
                                .foregroundColor(PauseColors.tertiaryText)
                                .padding(.horizontal, Spacing.md)
                            
                            VStack(spacing: 0) {
                                // Screen Time Hilfe
                                Link(destination: URL(string: "https://support.apple.com/de-de/guide/iphone/iph3c5b1b51a/ios")!) {
                                    HStack(spacing: Spacing.md) {
                                        Image(systemName: "questionmark.circle")
                                            .font(.system(size: FontSize.lg))
                                            .foregroundColor(PauseColors.accent)
                                            .frame(width: 32)
                                        
                                        Text("Screen Time Hilfe")
                                            .font(.system(size: FontSize.base))
                                            .foregroundColor(PauseColors.primaryText)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: FontSize.sm, weight: .semibold))
                                            .foregroundColor(PauseColors.tertiaryText)
                                    }
                                    .padding(Spacing.md)
                                }
                                
                                Divider()
                                    .background(PauseColors.cardBorder)
                                    .padding(.horizontal, Spacing.md)
                                
                                // NFC Hilfe
                                Link(destination: URL(string: "https://support.apple.com/de-de/HT211852")!) {
                                    HStack(spacing: Spacing.md) {
                                        Image(systemName: "wave.3.right")
                                            .font(.system(size: FontSize.lg))
                                            .foregroundColor(PauseColors.accent)
                                            .frame(width: 32)
                                        
                                        Text("Über NFC auf dem iPhone")
                                            .font(.system(size: FontSize.base))
                                            .foregroundColor(PauseColors.primaryText)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: FontSize.sm, weight: .semibold))
                                            .foregroundColor(PauseColors.tertiaryText)
                                    }
                                    .padding(Spacing.md)
                                }
                            }
                            .card()
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("Einstellungen")
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    SettingsView()
}
