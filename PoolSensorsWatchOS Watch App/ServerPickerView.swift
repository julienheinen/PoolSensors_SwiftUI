//
//  ServerPickerView.swift
//  PoolSensorsWatchOS Watch App
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

struct ServerPickerView: View {
    @EnvironmentObject var viewModel: WatchViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List(viewModel.servers) { server in
            Button(action: {
                viewModel.selectServer(server)
                dismiss()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(server.name)
                            .font(.headline)
                        
                        if server.isConnected {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Connecté")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if viewModel.currentServer?.id == server.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Serveurs")
        .navigationBarTitleDisplayMode(.inline)
    }
}
