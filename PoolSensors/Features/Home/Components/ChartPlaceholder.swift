//
//  ChartPlaceholder.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct ChartPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.5))
            
            Text("Graphiques à venir")
                .font(.headline)
            
            Text("Les graphiques d'historique des données seront disponibles ici")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
        .padding(.horizontal)
    }
}

#Preview {
    ChartPlaceholder()
}
