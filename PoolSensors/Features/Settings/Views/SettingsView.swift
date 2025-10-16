//
//  SettingsView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @AppStorage("temperatureUnit") private var temperatureUnit: String = "celsius"
    @AppStorage("dataRetentionDays") private var dataRetentionDays: Double = 30
    
    @State private var showClearDataAlert = false
    @State private var showExportSheet = false
    @State private var exportedFileURL: URL?
    
    var body: some View {
        NavigationView {
            Form {
            // Préférences
            Section(header: Text("Préférences")) {
                Picker("Unité de température", selection: $temperatureUnit) {
                    Text("Celsius (°C)").tag("celsius")
                    Text("Fahrenheit (°F)").tag("fahrenheit")
                }
                .pickerStyle(.menu)
            }
            
            // Gestion des données
            Section(header: Text("Données")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Conservation des données")
                        .font(.subheadline)
                    
                    HStack {
                        Slider(value: $dataRetentionDays, in: 7...90, step: 1)
                        Text("\(Int(dataRetentionDays)) jours")
                            .frame(width: 70)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Les données plus anciennes seront automatiquement supprimées.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: exportData) {
                    Label("Exporter toutes les données", systemImage: "square.and.arrow.up")
                }
                
                Button(action: { showClearDataAlert = true }) {
                    Text("Effacer toutes les données")
                        .foregroundColor(.red)
                }
            }
            
            // Notifications
            Section(header: Text("Notifications")) {
                NavigationLink(destination: NotificationSettingsView()) {
                    Label("Configurer les alertes", systemImage: "bell.badge.fill")
                }
            }
            
            // À propos
            Section(header: Text("À propos")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link("Aide & Support", destination: URL(string: "https://example.com")!)
                Link("Politique de confidentialité", destination: URL(string: "https://example.com")!)
                
                Button(action: {}) {
                    Text("Envoyer un feedback")
                }
            }
            }
            .navigationTitle("Paramètres")
            .alert("Effacer toutes les données", isPresented: $showClearDataAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Effacer", role: .destructive) {
                viewModel.clearAllData()
            }
        } message: {
            Text("Cette action supprimera toutes les données de l'historique. Cette action est irréversible.")
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportedFileURL {
                ActivityViewController(activityItems: [url])
            }
        }
        }
    }
    
    // MARK: - Export Data
    private func exportData() {
        let csvContent = generateCSV()
        
        let fileName = "PoolSensors_Export_\(Date().formatted(date: .numeric, time: .omitted)).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: path, atomically: true, encoding: .utf8)
            exportedFileURL = path
            showExportSheet = true
            print("📤 Export réussi: \(fileName)")
        } catch {
            print("❌ Erreur d'export: \(error)")
        }
    }
    
    private func generateCSV() -> String {
        var csv = "Timestamp,Temperature,pH,Chlorine,ORP\n"
        
        for data in viewModel.sensorData {
            let timestamp = data.timestamp.formatted(date: .numeric, time: .shortened)
            csv += "\(timestamp),\(data.temperature),\(data.ph),\(data.chlorine),\(data.orp)\n"
        }
        
        return csv
    }
}

// UIActivityViewController wrapper pour partager le fichier
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(AppViewModel())
    }
}
