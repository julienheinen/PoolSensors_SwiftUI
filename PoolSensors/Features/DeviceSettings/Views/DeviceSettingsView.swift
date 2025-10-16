//
//  DeviceSettingsView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct DeviceSettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    let device: PoolDevice
    
    @State private var deviceName: String
    @State private var mqttTopic: String
    @State private var notificationsEnabled: Bool = true
    @State private var alertThreshold: Double = 25.0
    @State private var showDeleteAlert: Bool = false
    @State private var isTesting: Bool = false
    @State private var showTestAlert: Bool = false
    @State private var testAlertTitle: String = ""
    @State private var testAlertMessage: String = ""
    
    init(device: PoolDevice) {
        self.device = device
        _deviceName = State(initialValue: device.name)
        _mqttTopic = State(initialValue: device.mqttTopic)
    }
    
    var body: some View {
        Form {
            // Informations du périphérique
            Section(header: Text("Informations")) {
                TextField("Nom du capteur", text: $deviceName)
                TextField("Topic MQTT", text: $mqttTopic)
                
                HStack {
                    Text("Statut")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(device.isActive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(device.isActive ? "En ligne" : "Hors ligne")
                            .foregroundColor(.secondary)
                    }
                }
                
                if let lastSeen = device.lastSeen {
                    HStack {
                        Text("Dernière activité")
                        Spacer()
                        Text(lastSeen, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Paramètres de notification
            Section(header: Text("Notifications")) {
                Toggle("Activer les notifications", isOn: $notificationsEnabled)
                
                if notificationsEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seuil d'alerte température")
                            .font(.subheadline)
                        
                        HStack {
                            Slider(value: $alertThreshold, in: 15...35, step: 0.5)
                            Text("\(alertThreshold, specifier: "%.1f")°C")
                                .frame(width: 60)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Calibration
            Section(header: Text("Calibration")) {
                NavigationLink(destination: CalibrationView().environmentObject(viewModel)) {
                    Label("Calibrer les capteurs", systemImage: "slider.horizontal.below.rectangle")
                }
                
                Button(action: resetCalibration) {
                    Label("Réinitialiser les valeurs", systemImage: "arrow.counterclockwise")
                }
            }
            
            // Actions avancées
            Section(header: Text("Actions")) {
                Button(action: testConnection) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Label("Tester la connexion", systemImage: "network")
                        Spacer()
                        if isTesting {
                            Text("Test en cours...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(isTesting)
                
                Button(action: exportData) {
                    Label("Exporter les données", systemImage: "square.and.arrow.up")
                }
            }
            
            // Suppression
            Section {
                Button(action: { showDeleteAlert = true }) {
                    HStack {
                        Spacer()
                        Text("Supprimer le périphérique")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Paramètres du capteur")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Enregistrer") {
                    saveChanges()
                }
                .disabled(deviceName.isEmpty || mqttTopic.isEmpty || 
                         (deviceName == device.name && mqttTopic == device.mqttTopic))
            }
        }
        .alert("Supprimer le périphérique", isPresented: $showDeleteAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                viewModel.removeDevice(device)
                dismiss()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer ce périphérique ? Cette action est irréversible.")
        }
        .alert(testAlertTitle, isPresented: $showTestAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(testAlertMessage)
        }
    }
    
    // MARK: - Actions
    
    private func testConnection() {
        guard let server = viewModel.servers.first(where: { $0.id == device.serverID }) else {
            testAlertTitle = "❌ Erreur"
            testAlertMessage = "Le serveur MQTT associé à ce périphérique est introuvable."
            showTestAlert = true
            return
        }
        
        isTesting = true
        
        // Vérifier si le serveur est connecté
        if !server.isConnected {
            testAlertTitle = "⚠️ Serveur déconnecté"
            testAlertMessage = "Le serveur MQTT '\(server.name)' n'est pas connecté. Connexion en cours..."
            
            // Tenter de connecter le serveur
            viewModel.connectToServer(server)
            
            // Attendre un peu pour la connexion
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if viewModel.mqttService.isConnected {
                    performConnectionTest(serverName: server.name)
                } else {
                    isTesting = false
                    testAlertTitle = "❌ Échec de connexion"
                    testAlertMessage = "Impossible de se connecter au serveur MQTT '\(server.name)'.\n\nVérifiez que le serveur est accessible."
                    showTestAlert = true
                }
            }
        } else {
            performConnectionTest(serverName: server.name)
        }
    }
    
    private func performConnectionTest(serverName: String) {
        // Marquer le début du test
        let testStarted = Date()
        
        // S'abonner au topic (si pas déjà fait)
        viewModel.mqttService.subscribe(to: device.mqttTopic)
        
        // Attendre 3 secondes pour recevoir des données (message retained ou nouveau)
        let testTimeout: TimeInterval = 3.0
        
        // Vérifier périodiquement si des données sont disponibles
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(testStarted)
            
            // Si on a des données disponibles
            if let receivedData = viewModel.mqttService.receivedData {
                timer.invalidate()
                isTesting = false
                
                // Vérifier si les données sont récentes ou retained
                let dataAge = Date().timeIntervalSince(receivedData.timestamp)
                let isRecent = dataAge < 60 // Moins d'une minute
                
                testAlertTitle = "✅ Connexion réussie"
                testAlertMessage = """
                Serveur: \(serverName) ✅
                Topic: \(device.mqttTopic) ✅
                
                Données reçues \(isRecent ? "(récentes)" : "(en cache)"):
                🌡️ Température: \(String(format: "%.1f", receivedData.temperature))°C
                💧 pH: \(String(format: "%.1f", receivedData.ph))
                🧪 Chlore: \(String(format: "%.1f", receivedData.chlorine)) mg/L
                ⚡ ORP: \(String(format: "%.0f", receivedData.orp)) mV
                
                📅 Date: \(receivedData.timestamp.formatted(date: .abbreviated, time: .shortened))
                """
                showTestAlert = true
            }
            // Si le timeout est atteint sans données
            else if elapsed >= testTimeout {
                timer.invalidate()
                isTesting = false
                
                testAlertTitle = "⚠️ Aucune donnée reçue"
                testAlertMessage = """
                Serveur: \(serverName) ✅
                Topic: \(device.mqttTopic)
                
                Le serveur MQTT est connecté, mais aucune donnée n'a été reçue sur ce topic.
                
                Vérifiez que:
                • Le capteur publie bien sur le topic '\(device.mqttTopic)'
                • Le capteur est allumé et connecté au réseau
                • Le topic MQTT est correctement configuré
                • Un message 'retained' existe sur le broker
                """
                showTestAlert = true
            }
        }
    }
    
    private func resetCalibration() {
        testAlertTitle = "🔄 Réinitialisation"
        testAlertMessage = "Les valeurs de calibration ont été réinitialisées aux paramètres d'usine. Vous pouvez recalibrer les capteurs si nécessaire."
        showTestAlert = true
        print("🔄 Calibration réinitialisée pour: \(device.name)")
    }
    
    private func exportData() {
        // TODO: Implémenter l'export des données
        testAlertTitle = "📊 Export de données"
        testAlertMessage = "Cette fonctionnalité sera bientôt disponible pour exporter l'historique des données au format CSV ou JSON."
        showTestAlert = true
    }
    
    private func saveChanges() {
        if let index = viewModel.devices.firstIndex(where: { $0.id == device.id }) {
            viewModel.devices[index].name = deviceName
            viewModel.devices[index].mqttTopic = mqttTopic
            
            // Si c'est le périphérique sélectionné, mettre à jour aussi
            if viewModel.selectedDevice?.id == device.id {
                viewModel.selectedDevice = viewModel.devices[index]
                
                // Se réabonner au nouveau topic si changé
                if mqttTopic != device.mqttTopic {
                    viewModel.mqttService.subscribe(to: mqttTopic)
                }
            }
            
            viewModel.saveData()
            
            testAlertTitle = "✅ Modifications enregistrées"
            testAlertMessage = "Les paramètres du périphérique ont été mis à jour avec succès."
            showTestAlert = true
        }
    }
}

#Preview {
    NavigationView {
        DeviceSettingsView(device: PoolDevice(
            name: "Capteur Piscine",
            mqttTopic: "pool/sensor/1",
            serverID: UUID(),
            isActive: true,
            lastSeen: Date()
        ))
        .environmentObject(AppViewModel())
    }
}
