//
//  DevicePickerView.swift
//  PoolSensorsWatchOS Watch App
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

struct DevicePickerView: View {
    @EnvironmentObject var viewModel: WatchViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            if viewModel.filteredDevices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Aucun périphérique")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.filteredDevices) { device in
                    Button(action: {
                        viewModel.selectDevice(device)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(.headline)
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(device.isActive ? Color.green : Color.red)
                                        .frame(width: 6, height: 6)
                                    Text(device.isActive ? "En ligne" : "Hors ligne")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if viewModel.selectedDevice?.id == device.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Périphériques")
        .navigationBarTitleDisplayMode(.inline)
    }
}
