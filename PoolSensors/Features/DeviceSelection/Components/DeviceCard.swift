//
//  DeviceCard.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct DeviceCard: View {
    let device: PoolDevice
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.isActive ? "sensor.fill" : "sensor")
                .foregroundColor(device.isActive ? .green : .gray)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                Text(device.deviceType)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let lastSeen = device.lastSeen {
                    Text("Dernière activité: \(lastSeen, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    DeviceCard(device: PoolDevice(
        name: "Capteur Piscine", 
        mqttTopic: "pool/sensor/1", 
        serverID: UUID(), 
        isActive: true, 
        lastSeen: Date()
    ))
}
