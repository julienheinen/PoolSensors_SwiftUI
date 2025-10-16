//
//  EditServerView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 16/10/2025.
//

import SwiftUI

struct EditServerView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    let server: MQTTServer
    
    @State private var serverName: String
    @State private var host: String
    @State private var port: String
    @State private var username: String
    @State private var password: String
    @State private var useTLS: Bool
    
    @State private var showDeleteAlert = false
    @State private var showSaveAlert = false
    
    init(server: MQTTServer) {
        self.server = server
        _serverName = State(initialValue: server.name)
        _host = State(initialValue: server.host)
        _port = State(initialValue: String(server.port))
        _username = State(initialValue: server.username ?? "")
        _password = State(initialValue: server.password ?? "")
        _useTLS = State(initialValue: server.useTLS)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations du serveur")) {
                    TextField("Nom du serveur", text: $serverName)
                    TextField("Adresse (ex: 192.168.1.100)", text: $host)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Authentification (optionnel)")) {
                    TextField("Nom d'utilisateur", text: $username)
                    SecureField("Mot de passe", text: $password)
                }
                
                Section(header: Text("Sécurité")) {
                    Toggle("Utiliser TLS/SSL", isOn: $useTLS)
                }
                
                Section(header: Text("État")) {
                    HStack {
                        Text("Statut")
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(server.isConnected ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(server.isConnected ? "Connecté" : "Déconnecté")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(action: { showDeleteAlert = true }) {
                        HStack {
                            Spacer()
                            Text("Supprimer le serveur")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Modifier le serveur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Supprimer le serveur", isPresented: $showDeleteAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    viewModel.removeServer(server)
                    dismiss()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer ce serveur ? Tous les périphériques associés seront également supprimés.")
            }
            .alert("Modifications enregistrées", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Les paramètres du serveur ont été mis à jour avec succès.")
            }
        }
    }
    
    private var isValid: Bool {
        !serverName.isEmpty && !host.isEmpty && !port.isEmpty && Int(port) != nil
    }
    
    private func saveChanges() {
        guard let portInt = Int(port) else { return }
        
        if let index = viewModel.servers.firstIndex(where: { $0.id == server.id }) {
            viewModel.servers[index].name = serverName
            viewModel.servers[index].host = host
            viewModel.servers[index].port = portInt
            viewModel.servers[index].username = username.isEmpty ? nil : username
            viewModel.servers[index].password = password.isEmpty ? nil : password
            viewModel.servers[index].useTLS = useTLS
            
            // Si c'est le serveur actuel, mettre à jour
            if viewModel.currentServer?.id == server.id {
                viewModel.currentServer = viewModel.servers[index]
                
                // Se reconnecter avec les nouveaux paramètres
                viewModel.connectToServer(viewModel.servers[index])
            }
            
            viewModel.saveData()
            showSaveAlert = true
        }
    }
}

#Preview {
    EditServerView(server: MQTTServer(
        name: "Serveur Local",
        host: "192.168.1.100",
        port: 1883
    ))
    .environmentObject(AppViewModel())
}
