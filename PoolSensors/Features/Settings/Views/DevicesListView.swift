//
//  DevicesListView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct DevicesListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showAddDevice = false
    
    var body: some View {
        List {
            ForEach(viewModel.devices) { device in
                NavigationLink(destination: DeviceSettingsView(device: device)) {
                    DeviceRow(device: device)
                }
            }
            .onDelete(perform: deleteDevices)
        }
        .navigationTitle("Périphériques")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddDevice = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddDevice) {
            AddDeviceView()
        }
        .overlay {
            if viewModel.devices.isEmpty {
                ContentUnavailableView(
                    "Aucun périphérique",
                    systemImage: "sensor",
                    description: Text("Ajoutez un capteur pour commencer")
                )
            }
        }
    }
    
    private func deleteDevices(at offsets: IndexSet) {
        for index in offsets {
            let device = viewModel.devices[index]
            viewModel.removeDevice(device)
        }
    }
}

struct DeviceRow: View {
    let device: PoolDevice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(device.name)
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(device.isActive ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
            
            Text(device.deviceType)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Topic: \(device.mqttTopic)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        DevicesListView()
            .environmentObject(AppViewModel())
    }
}
