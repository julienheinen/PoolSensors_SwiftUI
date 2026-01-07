//
//  ContentView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 14/10/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        TabView {
            // Dashboard - Page principale
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            // Discussion / Assistant
            AssistantView()
                .tabItem {
                    Label("Assistant", systemImage: "bubble.left.and.bubble.right.fill")
                }
            
            // Sélection de périphérique
            DeviceSelectionView()
                .tabItem {
                    Label("Périphériques", systemImage: "sensor.fill")
                }
            
            // Paramètres
            SettingsView()
                .tabItem {
                    Label("Paramètres", systemImage: "gear")
                }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
}
