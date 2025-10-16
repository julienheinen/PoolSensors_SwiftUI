//
//  PoolSensorsApp.swift
//  PoolSensors
//
//  Created by Julien Heinen on 14/10/2025.
//

import SwiftUI

@main
struct PoolSensorsApp: App {
    init() {
        // Demander l'autorisation pour les notifications au lancement
        NotificationService.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
