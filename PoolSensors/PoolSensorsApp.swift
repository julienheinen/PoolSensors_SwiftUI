//
//  PoolSensorsApp.swift
//  PoolSensors
//
//  Created by Julien Heinen on 14/10/2025.
//

import SwiftUI

@main
struct PoolSensorsApp: App {
    @StateObject private var viewModel = AppViewModel()
    
    init() {
        // Demander l'autorisation pour les notifications au lancement
        NotificationService.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    // Configurer WatchConnectivity avec le ViewModel
                    PhoneConnectivityManager.shared.configure(with: viewModel)
                }
        }
    }
}
