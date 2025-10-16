//
//  ServerCard.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct ServerCard: View {
    let server: MQTTServer
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: server.isConnected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(server.isConnected ? .green : .gray)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                    .font(.headline)
                Text("\(server.host):\(server.port)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if server.useTLS {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    ServerCard(server: MQTTServer(name: "Mon serveur", host: "broker.hivemq.com", port: 1883, isConnected: true))
}
