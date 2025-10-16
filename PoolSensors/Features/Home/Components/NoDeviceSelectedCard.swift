//
//  NoDeviceSelectedCard.swift
//  PoolSensors
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

struct NoDeviceSelectedCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icône
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "sensor.tag.radiowaves.forward")
                        .font(.system(size: 28))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aucun périphérique sélectionné")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Appuyez pour sélectionner un capteur")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                            .shadow(color: Color.orange.opacity(0.1), radius: 8)
                    )
            )
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NoDeviceSelectedCard {
        print("Tapped")
    }
    .previewLayout(.sizeThatFits)
    .padding()
}
