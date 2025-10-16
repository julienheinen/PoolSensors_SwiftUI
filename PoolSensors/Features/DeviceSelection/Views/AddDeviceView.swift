//
//  AddDeviceView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct AddDeviceView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var deviceName: String = ""
    @State private var mqttTopic: String = ""
    @State private var deviceType: String = "Pool Sensor"
    @State private var selectedServerID: UUID?
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations du périphérique")) {
                    TextField("Nom du capteur", text: $deviceName)
                    TextField("Type d'appareil", text: $deviceType)
                }
                
                Section(header: Text("Serveur MQTT")) {
                    if viewModel.servers.isEmpty {
                        Text("Aucun serveur MQTT disponible")
                            .foregroundColor(.secondary)
                        
                        Text("Vous devez d'abord ajouter un serveur MQTT dans la section ci-dessus.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Picker("Serveur", selection: $selectedServerID) {
                            Text("Sélectionner un serveur").tag(UUID?.none)
                            ForEach(viewModel.servers) { server in
                                HStack {
                                    Circle()
                                        .fill(server.isConnected ? Color.green : Color.gray)
                                        .frame(width: 8, height: 8)
                                    Text(server.name)
                                }
                                .tag(UUID?.some(server.id))
                            }
                        }
                        
                        if let serverID = selectedServerID,
                           let server = viewModel.servers.first(where: { $0.id == serverID }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("📡 \(server.host):\(server.port)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if !server.isConnected {
                                    Text("⚠️ Le serveur sera connecté automatiquement")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Configuration MQTT")) {
                    TextField("Topic MQTT (ex: pool/sensor/1/data)", text: $mqttTopic)
                    
                    Text("Le topic MQTT doit correspondre à celui configuré sur votre capteur.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: addDevice) {
                        Text("Ajouter le périphérique")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.green)
                    }
                    .disabled(!canAddDevice)
                }
            }
            .navigationTitle("Nouveau périphérique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .alert("Erreur", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // Sélectionner automatiquement le serveur actuel s'il existe
                if selectedServerID == nil, let currentServer = viewModel.currentServer {
                    selectedServerID = currentServer.id
                } else if selectedServerID == nil, let firstServer = viewModel.servers.first {
                    selectedServerID = firstServer.id
                }
            }
        }
    }
    
    private var canAddDevice: Bool {
        !deviceName.isEmpty && !mqttTopic.isEmpty && selectedServerID != nil
    }
    
    private func addDevice() {
        guard let serverID = selectedServerID else {
            alertMessage = "Veuillez sélectionner un serveur MQTT"
            showAlert = true
            return
        }
        
        // Vérifier que le serveur existe toujours
        guard viewModel.servers.contains(where: { $0.id == serverID }) else {
            alertMessage = "Le serveur sélectionné n'existe plus"
            showAlert = true
            return
        }
        
        let device = PoolDevice(
            name: deviceName,
            deviceType: deviceType,
            mqttTopic: mqttTopic,
            serverID: serverID
        )
        
        viewModel.addDevice(device)
        viewModel.selectDevice(device)
        dismiss()
    }
}

#Preview {
    AddDeviceView()
        .environmentObject(AppViewModel())
}
