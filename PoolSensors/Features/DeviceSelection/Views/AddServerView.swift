//
//  AddServerView.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import SwiftUI
import Combine

enum ConnectionTestResult {
    case success
    case failed(String)
    case testing
}

struct AddServerView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = "1883"
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var useTLS: Bool = false
    
    // États pour la validation et test de connexion
    @State private var isTestingConnection: Bool = false
    @State private var showConnectionAlert: Bool = false
    @State private var connectionTestResult: ConnectionTestResult = .testing
    @State private var validationErrors: [String] = []
    @State private var showValidationAlert: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("Informations du serveur")) {
                        TextField("Nom", text: $name)
                            .autocapitalization(.words)
                        TextField("Hôte (ex: broker.hivemq.com)", text: $host)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        TextField("Port", text: $port)
                            .keyboardType(.numberPad)
                    }
                
                Section(header: Text("Authentification (optionnel)")) {
                    TextField("Nom d'utilisateur", text: $username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    SecureField("Mot de passe", text: $password)
                }
                
                Section(header: Text("Sécurité")) {
                    Toggle("Utiliser TLS/SSL", isOn: $useTLS)
                }
                
                    Section(header: Text("Exemples de serveurs publics")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("HiveMQ: broker.hivemq.com:1883")
                                .font(.caption)
                            Text("Eclipse: mqtt.eclipseprojects.io:1883")
                                .font(.caption)
                            Text("Mosquitto: test.mosquitto.org:1883")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Section {
                        Button(action: testAndAddServer) {
                            HStack {
                                if isTestingConnection {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                }
                                Text(isTestingConnection ? "Test en cours..." : "Tester et ajouter")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                        }
                        .disabled(name.isEmpty || host.isEmpty || isTestingConnection)
                    }
                }
                .navigationTitle("Nouveau serveur MQTT")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuler") {
                            dismiss()
                        }
                    }
                }
                .alert("Erreurs de validation", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
            .alert("Test de connexion", isPresented: $showConnectionAlert) {
                switch connectionTestResult {
                case .failed:
                    Button("Revenir aux modifications", role: .cancel) {
                        // Ne rien faire, reste sur la page
                    }
                    Button("Réessayer") {
                        testConnection()
                    }
                    Button("Continuer quand même") {
                        addServerWithoutTest()
                    }
                case .success:
                    Button("OK") {
                        addServerWithoutTest()
                    }
                default:
                    Button("OK", role: .cancel) {}
                }
                } message: {
                switch connectionTestResult {
                case .success:
                    Text("✅ Connexion réussie ! Le serveur MQTT est accessible.")
                case .failed(let error):
                    Text("❌ Impossible de se connecter au serveur MQTT.\n\nErreur: \(error)\n\nVoulez-vous continuer quand même ?")
                case .testing:
                    Text("Test de connexion en cours...")
                }
                }
                
                // Overlay de test de connexion
                if isTestingConnection {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ConnectionTestView(
                        isVisible: isTestingConnection,
                        status: "Test de connexion au serveur MQTT"
                    )
                }
            }
        }
    }
    
    // MARK: - Validation
    
    private func validateInputs() -> Bool {
        validationErrors.removeAll()
        
        // Validation du nom
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors.append("Le nom du serveur est requis")
        }
        
        // Validation de l'hôte
        let trimmedHost = host.trimmingCharacters(in: .whitespaces)
        if trimmedHost.isEmpty {
            validationErrors.append("L'adresse du serveur est requise")
        } else {
            // Vérifier le format de l'hôte (pas de protocole)
            if trimmedHost.hasPrefix("http://") || trimmedHost.hasPrefix("https://") || trimmedHost.hasPrefix("mqtt://") {
                validationErrors.append("N'incluez pas le protocole (http://, mqtt://) dans l'adresse")
            }
            
            // Vérifier les caractères invalides
            let validHostCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_"))
            if trimmedHost.rangeOfCharacter(from: validHostCharacters.inverted) != nil {
                validationErrors.append("L'adresse contient des caractères invalides")
            }
        }
        
        // Validation du port
        if let portInt = Int(port) {
            if portInt < 1 || portInt > 65535 {
                validationErrors.append("Le port doit être entre 1 et 65535")
            }
        } else {
            validationErrors.append("Le port doit être un nombre valide")
        }
        
        if !validationErrors.isEmpty {
            showValidationAlert = true
            return false
        }
        
        return true
    }
    
    // MARK: - Connection Testing
    
    private func testAndAddServer() {
        guard validateInputs() else { return }
        testConnection()
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = .testing
        
        let portInt = Int(port) ?? 1883
        let testServer = MQTTServer(
            name: name,
            host: host.trimmingCharacters(in: .whitespaces),
            port: portInt,
            username: username.isEmpty ? nil : username,
            password: password.isEmpty ? nil : password,
            useTLS: useTLS
        )
        
        // Créer un service MQTT temporaire pour tester
        let testService = MQTTService()
        
        // Observer les changements de connexion
        var cancellable: AnyCancellable?
        cancellable = testService.$isConnected
            .sink { isConnected in
                if isConnected {
                    // Connexion réussie
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        testService.disconnect()
                        self.isTestingConnection = false
                        self.connectionTestResult = .success
                        self.showConnectionAlert = true
                        cancellable?.cancel()
                    }
                }
            }
        
        // Observer les erreurs
        var errorCancellable: AnyCancellable?
        errorCancellable = testService.$connectionError
            .sink { error in
                if let error = error {
                    DispatchQueue.main.async {
                        testService.disconnect()
                        self.isTestingConnection = false
                        self.connectionTestResult = .failed(error)
                        self.showConnectionAlert = true
                        errorCancellable?.cancel()
                    }
                }
            }
        
        // Timeout après 10 secondes
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isTestingConnection {
                testService.disconnect()
                self.isTestingConnection = false
                self.connectionTestResult = .failed("Délai d'attente dépassé (timeout)")
                self.showConnectionAlert = true
                cancellable?.cancel()
                errorCancellable?.cancel()
            }
        }
        
        // Lancer le test de connexion
        testService.connect(to: testServer)
    }
    
    // MARK: - Adding Server
    
    private func addServerWithoutTest() {
        let portInt = Int(port) ?? 1883
        let server = MQTTServer(
            name: name,
            host: host.trimmingCharacters(in: .whitespaces),
            port: portInt,
            username: username.isEmpty ? nil : username,
            password: password.isEmpty ? nil : password,
            useTLS: useTLS
        )
        viewModel.addServer(server)
        dismiss()
    }
}

#Preview {
    AddServerView()
        .environmentObject(AppViewModel())
}
