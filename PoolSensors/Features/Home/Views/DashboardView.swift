//
//  DashboardView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showServerSelector = false
    @State private var showDeviceSelector = false
    @State private var showDeviceSettings = false
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Bannière du serveur connecté (en haut)
                    ConnectedServerBanner(server: viewModel.currentServer) {
                        showServerSelector = true
                    }
                    
                    // En-tête avec info du capteur sélectionné (cliquable)
                    if let device = viewModel.selectedDevice {
                        DeviceHeaderCard(device: device) {
                            showDeviceSelector = true
                        }
                    } else if viewModel.currentServer != nil {
                        // Aucun périphérique sélectionné mais serveur actif
                        NoDeviceSelectedCard {
                            showDeviceSelector = true
                        }
                    }
                    
                    // Grille de capteurs
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(viewModel.currentReadings) { reading in
                            SensorCard(reading: reading)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Section graphiques
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Graphiques")
                            .font(.headline)
                            .padding(.horizontal)

                        HistoryChartsView(history: viewModel.sensorData)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .refreshable {
                await refreshData()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if viewModel.selectedDevice != nil {
                            showDeviceSettings = true
                        }
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(viewModel.selectedDevice != nil ? .blue : .gray)
                    }
                    .disabled(viewModel.selectedDevice == nil)
                }
            }
            .sheet(isPresented: $showServerSelector) {
                ServerSelectorView()
            }
            .sheet(isPresented: $showDeviceSelector) {
                DeviceSelectorView()
            }
            .sheet(isPresented: $showDeviceSettings) {
                if let device = viewModel.selectedDevice {
                    NavigationView {
                        DeviceSettingsView(device: device)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func refreshData() async {
        isRefreshing = true
        
        // Forcer la reconnexion
        viewModel.refreshConnection()
        
        // Attendre un peu pour laisser le temps de la reconnexion
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 secondes
        
        isRefreshing = false
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppViewModel())
}
