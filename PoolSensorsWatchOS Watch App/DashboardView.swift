//
//  DashboardView.swift
//  PoolSensorsWatchOS Watch App
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: WatchViewModel
    @ObservedObject private var connectivity = WatchConnectivityManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Indicateur de synchronisation
                    if !connectivity.isPhoneConnected {
                        HStack(spacing: 4) {
                            Image(systemName: "iphone.slash")
                                .font(.caption2)
                            Text("iPhone déconnecté")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                        .padding(.vertical, 4)
                    } else if connectivity.isPhoneReachable {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                            Text("Synchronisé")
                                .font(.caption2)
                        }
                        .foregroundColor(.green)
                        .padding(.vertical, 4)
                    }
                    
                    // Serveur actuel
                    if let server = viewModel.currentServer {
                        NavigationLink(destination: ServerPickerView()) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Serveur")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text(server.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if server.isConnected {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 6, height: 6)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue.opacity(0.3))
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(destination: ServerPickerView()) {
                            VStack(spacing: 4) {
                                Image(systemName: "server.rack")
                                    .font(.title2)
                                Text("Sélectionner un serveur")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.2))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Périphérique sélectionné
                    if let device = viewModel.selectedDevice {
                        NavigationLink(destination: DevicePickerView()) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Périphérique")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text(device.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Circle()
                                        .fill(device.isActive ? Color.green : Color.red)
                                        .frame(width: 6, height: 6)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.green.opacity(0.3))
                            )
                        }
                        .buttonStyle(.plain)
                    } else if viewModel.currentServer != nil {
                        NavigationLink(destination: DevicePickerView()) {
                            VStack(spacing: 4) {
                                Image(systemName: "drop")
                                    .font(.title2)
                                Text("Sélectionner un périphérique")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.2))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Données des capteurs
                    if !viewModel.currentReadings.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(viewModel.currentReadings) { reading in
                                WatchSensorCard(reading: reading)
                            }
                        }
                        
                        // Dernière mise à jour
                        Text("Mis à jour \(viewModel.lastUpdateTime, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            
                            Text("Aucune donnée disponible")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("Sélectionnez un serveur et un périphérique")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(WatchViewModel())
}
