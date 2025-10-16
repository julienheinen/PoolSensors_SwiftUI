//
//  DeviceSelectorView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

struct DeviceSelectorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Périphériques filtrés selon le serveur actuel
    private var filteredDevices: [PoolDevice] {
        guard let currentServer = viewModel.currentServer else {
            return []
        }
        return viewModel.devices.filter { $0.serverID == currentServer.id }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if filteredDevices.isEmpty {
                    // Aucun périphérique pour ce serveur
                    VStack(spacing: 20) {
                        Image(systemName: "sensor.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Aucun périphérique")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if let server = viewModel.currentServer {
                            Text("Aucun périphérique configuré pour\n\(server.name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            dismiss()
                            // L'utilisateur devra aller dans l'onglet "Périphériques"
                        }) {
                            Label("Ajouter un périphérique", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                } else {
                    // Liste des périphériques
                    List {
                        Section {
                            ForEach(filteredDevices) { device in
                                Button(action: {
                                    viewModel.selectDevice(device)
                                    dismiss()
                                }) {
                                    SelectableDeviceRow(
                                        device: device,
                                        isSelected: viewModel.selectedDevice?.id == device.id
                                    )
                                }
                            }
                        } header: {
                            if let server = viewModel.currentServer {
                                HStack {
                                    Image(systemName: "server.rack")
                                    Text(server.name)
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sélectionner un périphérique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Ligne de périphérique dans la liste de sélection
struct SelectableDeviceRow: View {
    let device: PoolDevice
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône
            ZStack {
                Circle()
                    .fill(device.isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: device.isActive ? "sensor.fill" : "sensor")
                    .foregroundColor(device.isActive ? .green : .gray)
            }
            
            // Informations
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text(device.deviceType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 3, height: 3)
                    
                    HStack(spacing: 3) {
                        Circle()
                            .fill(device.isActive ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        
                        Text(device.isActive ? "En ligne" : "Hors ligne")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Indicateur de sélection
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DeviceSelectorView()
        .environmentObject({
            let vm = AppViewModel()
            
            // Serveur 1
            let server1 = MQTTServer(
                name: "Serveur 1",
                host: "test.mosquitto.org",
                port: 1883,
                username: nil,
                password: nil
            )
            
            // Serveur 2
            let server2 = MQTTServer(
                name: "Serveur 2",
                host: "broker.hivemq.com",
                port: 1883,
                username: nil,
                password: nil
            )
            
            vm.servers = [server1, server2]
            
            // Périphériques du serveur 1
            vm.devices = [
                PoolDevice(name: "Piscine 1", deviceType: "Pool Sensor", mqttTopic: "pool/1/data", serverID: server1.id, isActive: true),
                PoolDevice(name: "Piscine 2", deviceType: "Pool Sensor", mqttTopic: "pool/2/data", serverID: server1.id, isActive: false),
                PoolDevice(name: "Piscine 3", deviceType: "Pool Sensor", mqttTopic: "pool/3/data", serverID: server2.id, isActive: true)
            ]
            
            vm.currentServer = server1
            vm.selectedDevice = vm.devices[0]
            
            return vm
        }())
}
