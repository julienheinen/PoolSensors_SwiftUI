//
//  ContentView.swift
//  PoolSensorsWatchOS Watch App
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some View {
        DashboardView()
            .environmentObject(viewModel)
            .onAppear {
                // Configurer WatchConnectivity avec le ViewModel
                WatchConnectivityManager.shared.configure(with: viewModel)
            }
    }
}

#Preview {
    ContentView()
}
