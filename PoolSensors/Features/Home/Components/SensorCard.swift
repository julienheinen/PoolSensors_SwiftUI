//
//  SensorCard.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct SensorCard: View {
    let reading: SensorReading
    
    var body: some View {
        VStack(spacing: 12) {
            // Icône
            Image(systemName: reading.icon)
                .font(.system(size: 32))
                .foregroundColor(statusColor)
            
            // Nom du capteur
            Text(reading.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Valeur
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(reading.value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(reading.unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Indicateur de statut
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var statusColor: Color {
        switch reading.status {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        case .offline: return .gray
        }
    }
    
    private var statusText: String {
        switch reading.status {
        case .normal: return "Normal"
        case .warning: return "Attention"
        case .critical: return "Critique"
        case .offline: return "Hors ligne"
        }
    }
}

#Preview {
    HStack {
        SensorCard(reading: SensorReading(
            name: "Température",
            value: "24.5",
            unit: "°C",
            status: .normal,
            icon: "thermometer"
        ))
        
        SensorCard(reading: SensorReading(
            name: "pH",
            value: "7.2",
            unit: "",
            status: .warning,
            icon: "drop.fill"
        ))
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
