//
//  DeviceSelectionView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct DeviceSelectionView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showAddDevice = false
    @State private var showAddServer = false
    @State private var selectedServer: MQTTServer?
    @State private var selectedDevice: PoolDevice?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // En-tête
                VStack(spacing: 8) {
                    Image(systemName: "sensor.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("PoolSensors")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Gérez vos capteurs de piscine")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Section Serveurs MQTT
                VStack(alignment: .leading, spacing: 12) {
                    Text("Serveurs MQTT")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.servers.isEmpty {
                        EmptyStateCard(
                            icon: "server.rack",
                            title: "Aucun serveur",
                            message: "Ajoutez un serveur MQTT pour recevoir les données"
                        )
                    } else {
                        VStack(spacing: 8) {
                            ForEach(viewModel.servers) { server in
                                Button(action: {
                                    print("🖱️ Tap sur serveur: \(server.name)")
                                    selectedServer = server
                                }) {
                                    ServerCard(server: server)
                                }
                                .buttonStyle(CardButtonStyle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.removeServer(server)
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        selectedServer = server
                                    } label: {
                                        Label("Modifier", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                    
                    Button(action: { showAddServer = true }) {
                        Label("Ajouter un serveur MQTT", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Section Périphériques
                VStack(alignment: .leading, spacing: 12) {
                    Text("Périphériques")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.devices.isEmpty {
                        EmptyStateCard(
                            icon: "sensor",
                            title: "Aucun périphérique",
                            message: "Ajoutez un capteur pour commencer"
                        )
                    } else {
                        VStack(spacing: 8) {
                            ForEach(viewModel.devices) { device in
                                Button(action: {
                                    print("🖱️ Tap sur périphérique: \(device.name)")
                                    selectedDevice = device
                                }) {
                                    DeviceCard(device: device)
                                }
                                .buttonStyle(CardButtonStyle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.removeDevice(device)
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        selectedDevice = device
                                    } label: {
                                        Label("Modifier", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                            }
                        }
                    }
                    
                    Button(action: { showAddDevice = true }) {
                        Label("Ajouter un périphérique", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddServer) {
                AddServerView()
            }
            .sheet(isPresented: $showAddDevice) {
                AddDeviceView()
            }
            .sheet(item: $selectedServer) { server in
                EditServerView(server: server)
            }
            .sheet(item: $selectedDevice) { device in
                NavigationView {
                    DeviceSettingsView(device: device)
                }
            }
        }
    }
}

// Style personnalisé pour les cartes cliquables
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    DeviceSelectionView()
        .environmentObject(AppViewModel())
}

