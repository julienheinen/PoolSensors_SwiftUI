//
//  PhoneConnectivityManager.swift
//  PoolSensors
//
//  Created by Julien Heinen on 16/10/2025.
//

import Foundation
import WatchConnectivity
import Combine

class PhoneConnectivityManager: NSObject, ObservableObject {
    static let shared = PhoneConnectivityManager()
    
    @Published var isWatchConnected = false
    @Published var isWatchReachable = false
    
    private var viewModel: AppViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    override private init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func configure(with viewModel: AppViewModel) {
        self.viewModel = viewModel
        
        // Observer les changements de serveurs, périphériques et données
        viewModel.$servers
            .sink { [weak self] _ in
                self?.sendDataToWatch()
            }
            .store(in: &cancellables)
        
        viewModel.$devices
            .sink { [weak self] _ in
                self?.sendDataToWatch()
            }
            .store(in: &cancellables)
        
        viewModel.$currentServer
            .sink { [weak self] _ in
                self?.sendDataToWatch()
            }
            .store(in: &cancellables)
        
        viewModel.$selectedDevice
            .sink { [weak self] _ in
                self?.sendDataToWatch()
            }
            .store(in: &cancellables)
        
        viewModel.mqttService.$receivedData
            .sink { [weak self] _ in
                self?.sendSensorDataToWatch()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Send Data to Watch
    
    func sendDataToWatch() {
        guard let viewModel = viewModel else { return }
        guard WCSession.default.activationState == .activated else { return }
        
        // Convertir les modèles iOS en format compatible watchOS
        let watchServers = viewModel.servers.map { server in
            [
                "id": server.id.uuidString,
                "name": server.name,
                "isConnected": server.isConnected
            ] as [String : Any]
        }
        
        let watchDevices = viewModel.devices.map { device in
            [
                "id": device.id.uuidString,
                "name": device.name,
                "serverID": device.serverID.uuidString,
                "isActive": device.isActive,
                "lastSeen": device.lastSeen?.timeIntervalSince1970 ?? 0
            ] as [String : Any]
        }
        
        var context: [String: Any] = [
            "servers": watchServers,
            "devices": watchDevices
        ]
        
        if let currentServer = viewModel.currentServer {
            context["currentServerID"] = currentServer.id.uuidString
        }
        
        if let selectedDevice = viewModel.selectedDevice {
            context["selectedDeviceID"] = selectedDevice.id.uuidString
        }
        
        do {
            try WCSession.default.updateApplicationContext(context)
            print("📱 Données envoyées à la Watch : \(viewModel.servers.count) serveurs, \(viewModel.devices.count) périphériques")
        } catch {
            print("❌ Erreur lors de l'envoi des données à la Watch : \(error.localizedDescription)")
        }
    }
    
    func sendSensorDataToWatch() {
        guard let viewModel = viewModel else { return }
        guard let sensorData = viewModel.mqttService.receivedData else { return }
        guard WCSession.default.activationState == .activated else { return }
        
        let data: [String: Any] = [
            "id": sensorData.id.uuidString,
            "temperature": sensorData.temperature as Any,
            "pH": sensorData.ph as Any,
            "chlorine": sensorData.chlorine as Any,
            "orp": sensorData.orp as Any,
            "timestamp": sensorData.timestamp.timeIntervalSince1970
        ]
        
        let message = ["sensorData": data]
        
        if WCSession.default.isReachable {
            // Envoi instantané si la Watch est accessible
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("❌ Erreur lors de l'envoi instantané : \(error.localizedDescription)")
            }
            print("📱 Données de capteurs envoyées instantanément à la Watch")
        } else {
            // Transfert en arrière-plan
            WCSession.default.transferUserInfo(message)
            print("📱 Données de capteurs transférées en arrière-plan à la Watch")
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = activationState == .activated
            
            if let error = error {
                print("❌ Erreur d'activation WCSession : \(error.localizedDescription)")
            } else {
                print("✅ WCSession activée sur iPhone")
                // Envoyer les données immédiatement après activation
                self.sendDataToWatch()
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
            print("⚠️ WCSession devenue inactive")
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
            print("⚠️ WCSession désactivée")
        }
        
        // Réactiver la session
        session.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
            print("📱 Watch reachable: \(session.isReachable)")
            
            // Si la Watch devient accessible, envoyer les dernières données
            if session.isReachable {
                self.sendDataToWatch()
                self.sendSensorDataToWatch()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // La Watch peut demander une actualisation
        if message["requestUpdate"] as? Bool == true {
            print("📱 Watch demande une actualisation des données")
            DispatchQueue.main.async {
                self.sendDataToWatch()
                self.sendSensorDataToWatch()
            }
        }
    }
}
