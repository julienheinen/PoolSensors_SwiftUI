//
//  ConnectionTestView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

/// Vue pour afficher l'état du test de connexion MQTT
struct ConnectionTestView: View {
    let isVisible: Bool
    let status: String
    
    var body: some View {
        if isVisible {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text(status)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Veuillez patienter...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ConnectionTestView(isVisible: true, status: "Test de connexion en cours")
        
        ConnectionTestView(isVisible: false, status: "Test terminé")
    }
    .padding()
}
