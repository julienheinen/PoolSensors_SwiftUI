//
//  ConnectedServerBanner.swift
//  PoolSensors
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

/// Bannière affichant le serveur MQTT actuellement connecté
struct ConnectedServerBanner: View {
    let server: MQTTServer?
    let onTap: () -> Void
    
    var body: some View {
        if let server = server {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Icône de statut
                    ZStack {
                        Circle()
                            .fill(server.isConnected ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: server.isConnected ? "antenna.radiowaves.left.and.right" : "wifi.slash")
                            .font(.system(size: 16))
                            .foregroundColor(server.isConnected ? .green : .orange)
                    }
                    
                    // Informations du serveur
                    VStack(alignment: .leading, spacing: 2) {
                        Text(server.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            Text(server.isConnected ? "Connecté" : "Déconnecté")
                                .font(.caption2)
                                .foregroundColor(server.isConnected ? .green : .orange)
                            
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(server.host)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Indicateur de changement
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal)
        } else {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Aucun serveur MQTT sélectionné")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ConnectedServerBanner(
            server: MQTTServer(name: "HiveMQ", host: "broker.hivemq.com", port: 1883, isConnected: true),
            onTap: {}
        )
        
        ConnectedServerBanner(
            server: MQTTServer(name: "Test Server", host: "test.mosquitto.org", port: 1883, isConnected: false),
            onTap: {}
        )
        
        ConnectedServerBanner(
            server: nil,
            onTap: {}
        )
    }
    .padding()
}
