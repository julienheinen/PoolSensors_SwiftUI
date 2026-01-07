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
    @AppStorage("poolVolumeM3") private var poolVolumeM3: Double = 30
    @AppStorage("availableChlorinePercent") private var availableChlorinePercent: Double = 65
    @AppStorage("phPlusDoseGPer10m3Per0_1") private var phPlusDoseGPer10m3Per0_1: Double = 150
    @AppStorage("phMinusDoseGPer10m3Per0_1") private var phMinusDoseGPer10m3Per0_1: Double = 150
    @AppStorage("assistantRulesURL") private var assistantRulesURL: String = ""
    
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

            // Assistant
            Section(header: Text("Assistant")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Volume de la piscine")
                        .font(.subheadline)

                    HStack {
                        Slider(value: $poolVolumeM3, in: 1...200, step: 0.5)
                        Text("\(poolVolumeM3, specifier: "%.1f") m³")
                            .frame(width: 80)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Chlore actif (produit)")
                        .font(.subheadline)

                    HStack {
                        Slider(value: $availableChlorinePercent, in: 10...100, step: 1)
                        Text("\(Int(availableChlorinePercent))%")
                            .frame(width: 60)
                            .foregroundColor(.secondary)
                    }

                    Text("Ex: dichlore ~56%, hypochlorite calcium ~65%, trichlore ~90%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Dosage pH+ (standard)")
                        .font(.subheadline)

                    HStack {
                        Slider(value: $phPlusDoseGPer10m3Per0_1, in: 50...300, step: 10)
                        Text("\(Int(phPlusDoseGPer10m3Per0_1)) g")
                            .frame(width: 60)
                            .foregroundColor(.secondary)
                    }
                    Text("g pour 10 m³ et +0.1 pH (à adapter selon votre produit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Dosage pH- (standard)")
                        .font(.subheadline)

                    HStack {
                        Slider(value: $phMinusDoseGPer10m3Per0_1, in: 50...300, step: 10)
                        Text("\(Int(phMinusDoseGPer10m3Per0_1)) g")
                            .frame(width: 60)
                            .foregroundColor(.secondary)
                    }
                    Text("g pour 10 m³ et -0.1 pH (à adapter selon votre produit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Source des règles (optionnel)")
                        .font(.subheadline)
                    TextField("https://.../rules.json", text: $assistantRulesURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.URL)
                    Text("Si renseignée, l'app peut récupérer des règles depuis Internet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
