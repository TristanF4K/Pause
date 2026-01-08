//
//  ContentView.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState.shared
    @State private var selectedTab = 0
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(PauseColors.secondaryBackground)
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(PauseColors.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(PauseColors.accent)
        ]
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(PauseColors.dimGray)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(PauseColors.dimGray)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack {
            PauseColors.background
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                TagListView()
                    .tabItem {
                        Label("Tags", systemImage: "tag.fill")
                    }
                    .tag(1)
                
                SettingsView()
                    .tabItem {
                        Label("Einstellungen", systemImage: "gearshape.fill")
                    }
                    .tag(2)
            }
            .accentColor(PauseColors.accent)
        }
        .onAppear {
            checkAuthorization()
        }
    }
    
    private func checkAuthorization() {
        Task {
            await appState.checkAuthorizationStatus()
        }
    }
}

#Preview {
    ContentView()
}
