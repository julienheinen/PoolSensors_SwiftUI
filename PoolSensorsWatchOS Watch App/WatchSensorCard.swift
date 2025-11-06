//
//  WatchSensorCard.swift
//  PoolSensorsWatchOS Watch App
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

struct WatchSensorCard: View {
    let reading: SensorReading
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(reading.title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(reading.value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorForReading)
                
                Text(reading.unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
        )
    }
    
    private var colorForReading: Color {
        switch reading.color {
        case .blue:
            return .blue
        case .green:
            return .green
        case .cyan:
            return .cyan
        case .purple:
            return .purple
        }
    }
}
