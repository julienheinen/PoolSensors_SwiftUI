//
//  ServerSelectorView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

/// Vue pour sélectionner rapidement un serveur MQTT dans le Dashboard
struct ServerSelectorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.servers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Aucun serveur MQTT")
                            .font(.headline)
                        Text("Ajoutez un serveur dans l'onglet Périphériques")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(viewModel.servers) { server in
                        Button(action: {
                            viewModel.connectToServer(server)
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: server.isConnected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(server.isConnected ? .green : .gray)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(server.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("\(server.host):\(server.port)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if server.useTLS {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                                
                                if server.isConnected {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Changer de serveur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ServerSelectorView()
        .environmentObject(AppViewModel())
}
