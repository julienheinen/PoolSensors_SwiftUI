//
//  MQTTServersListView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI

struct MQTTServersListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showAddServer = false
    
    var body: some View {
        List {
            ForEach(viewModel.servers) { server in
                ServerRow(server: server)
            }
            .onDelete(perform: deleteServers)
        }
        .navigationTitle("Serveurs MQTT")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddServer = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddServer) {
            AddServerView()
        }
        .overlay {
            if viewModel.servers.isEmpty {
                ContentUnavailableView(
                    "Aucun serveur",
                    systemImage: "server.rack",
                    description: Text("Ajoutez un serveur MQTT pour commencer")
                )
            }
        }
    }
    
    private func deleteServers(at offsets: IndexSet) {
        for index in offsets {
            let server = viewModel.servers[index]
            viewModel.removeServer(server)
        }
    }
}

struct ServerRow: View {
    let server: MQTTServer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(server.name)
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(server.isConnected ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
            }
            
            Text("\(server.host):\(server.port)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if server.useTLS {
                Label("Sécurisé (TLS)", systemImage: "lock.fill")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        MQTTServersListView()
            .environmentObject(AppViewModel())
    }
}
