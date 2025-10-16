//
//  HistoryView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showClearHistoryAlert = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.sensorData.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Aucun historique")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Les données reçues via MQTT apparaîtront ici")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        Section(header: HStack {
                            Text("Historique")
                            Spacer()
                            Text("\(viewModel.sensorData.count) mesure(s)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }) {
                            ForEach(viewModel.sensorData.reversed()) { data in
                                HistoryRowView(data: data)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Historique")
            .toolbar {
                if !viewModel.sensorData.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showClearHistoryAlert = true }) {
                            Label("Effacer", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Effacer l'historique", isPresented: $showClearHistoryAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Effacer", role: .destructive) {
                    clearHistory()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer les \(viewModel.sensorData.count) mesure(s) de l'historique ? Cette action est irréversible.")
            }
        }
    }
    
    private func clearHistory() {
        viewModel.sensorData.removeAll()
        viewModel.saveData()
        print("🗑️ Historique effacé")
    }
}

struct HistoryRowView: View {
    let data: PoolSensorData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Timestamp
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(data.timestamp, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(data.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(timeAgo(from: data.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Valeurs des capteurs
            HStack(spacing: 20) {
                MiniSensorValue(icon: "thermometer", value: String(format: "%.1f°C", data.temperature), color: temperatureColor(data.temperature))
                MiniSensorValue(icon: "drop.fill", value: String(format: "%.1f", data.ph), color: phColor(data.ph))
                MiniSensorValue(icon: "circle.hexagongrid.fill", value: String(format: "%.1f", data.chlorine), color: chlorineColor(data.chlorine))
                MiniSensorValue(icon: "waveform.path.ecg", value: String(format: "%.0f", data.orp), color: orpColor(data.orp))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "il y a \(seconds)s"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "il y a \(minutes)min"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "il y a \(hours)h"
        } else {
            let days = seconds / 86400
            return "il y a \(days)j"
        }
    }
    
    private func temperatureColor(_ temp: Double) -> Color {
        if temp < 20 || temp > 30 { return .orange }
        if temp < 15 || temp > 35 { return .red }
        return .green
    }
    
    private func phColor(_ ph: Double) -> Color {
        if ph < 6.8 || ph > 7.6 { return .orange }
        if ph < 6.5 || ph > 8.0 { return .red }
        return .green
    }
    
    private func chlorineColor(_ cl: Double) -> Color {
        if cl < 1.0 || cl > 3.0 { return .orange }
        if cl < 0.5 || cl > 5.0 { return .red }
        return .green
    }
    
    private func orpColor(_ orp: Double) -> Color {
        if orp < 600 || orp > 750 { return .orange }
        if orp < 500 || orp > 800 { return .red }
        return .green
    }
}

struct MiniSensorValue: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppViewModel())
}
