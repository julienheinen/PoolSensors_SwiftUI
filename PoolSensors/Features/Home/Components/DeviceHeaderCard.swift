//
//  DeviceHeaderCard.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct DeviceHeaderCard: View {
    let device: PoolDevice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icône du périphérique
                ZStack {
                    Circle()
                        .fill(device.isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: device.isActive ? "sensor.fill" : "sensor")
                        .font(.system(size: 28))
                        .foregroundColor(device.isActive ? .green : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(device.deviceType)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(device.isActive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(device.isActive ? "En ligne" : "Hors ligne")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let lastSeen = device.lastSeen {
                            Text("• \(lastSeen, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Indicateur de changement
                Image(systemName: "chevron.up.chevron.down")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
            )
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DeviceHeaderCard(device: PoolDevice(
        name: "Capteur Piscine Principale",
        deviceType: "Pool Sensor Pro",
        mqttTopic: "pool/sensor/1",
        serverID: UUID(),
        isActive: true,
        lastSeen: Date()
    )) {
        print("Device tapped")
    }
    .previewLayout(.sizeThatFits)
    .padding()
}
