//
//  WatchConnectivityManager.swift
//  PoolSensorsWatchOS Watch App
//
//  Created by Julien Heinen on 16/10/2025.
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isPhoneConnected = false
    @Published var isPhoneReachable = false
    
    private var viewModel: WatchViewModel?
    
    override private init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func configure(with viewModel: WatchViewModel) {
        self.viewModel = viewModel
        
        // Demander une mise à jour immédiate des données
        requestUpdateFromPhone()
    }
    
    // MARK: - Request Update from Phone
    
    func requestUpdateFromPhone() {
        guard WCSession.default.activationState == .activated else { return }
        guard WCSession.default.isReachable else {
            print("⌚️ iPhone non accessible pour mise à jour")
            return
        }
        
        let message = ["requestUpdate": true]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("❌ Erreur lors de la demande de mise à jour : \(error.localizedDescription)")
        }
        
        print("⌚️ Demande de mise à jour envoyée à l'iPhone")
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPhoneConnected = activationState == .activated
            
            if let error = error {
                print("❌ Erreur d'activation WCSession sur Watch : \(error.localizedDescription)")
            } else {
                print("✅ WCSession activée sur Apple Watch")
                // Demander les données immédiatement après activation
                self.requestUpdateFromPhone()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
            print("⌚️ iPhone reachable: \(session.isReachable)")
            
            // Si l'iPhone devient accessible, demander une mise à jour
            if session.isReachable {
                self.requestUpdateFromPhone()
            }
        }
    }
    
    // MARK: - Receive Application Context (Configuration Data)
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("⌚️ Contexte d'application reçu de l'iPhone")
        
        DispatchQueue.main.async {
            self.updateViewModel(with: applicationContext)
        }
    }
    
    // MARK: - Receive Messages (Sensor Data)
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("⌚️ Message instantané reçu de l'iPhone")
        
        DispatchQueue.main.async {
            if let sensorDataDict = message["sensorData"] as? [String: Any] {
                self.updateSensorData(with: sensorDataDict)
            }
        }
    }
    
    // MARK: - Receive User Info (Background Transfer)
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("⌚️ UserInfo reçu de l'iPhone (arrière-plan)")
        
        DispatchQueue.main.async {
            if let sensorDataDict = userInfo["sensorData"] as? [String: Any] {
                self.updateSensorData(with: sensorDataDict)
            }
        }
    }
    
    // MARK: - Update ViewModel
    
    private func updateViewModel(with context: [String: Any]) {
        guard let viewModel = viewModel else { return }
        
        // Serveurs
        if let serversArray = context["servers"] as? [[String: Any]] {
            let servers = serversArray.compactMap { dict -> WatchMQTTServer? in
                guard let idString = dict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let name = dict["name"] as? String,
                      let isConnected = dict["isConnected"] as? Bool else {
                    return nil
                }
                return WatchMQTTServer(id: id, name: name, isConnected: isConnected)
            }
            
            if !servers.isEmpty {
                viewModel.servers = servers
                print("⌚️ \(servers.count) serveurs synchronisés")
            }
        }
        
        // Périphériques
        if let devicesArray = context["devices"] as? [[String: Any]] {
            let devices = devicesArray.compactMap { dict -> WatchPoolDevice? in
                guard let idString = dict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let name = dict["name"] as? String,
                      let serverIDString = dict["serverID"] as? String,
                      let serverID = UUID(uuidString: serverIDString),
                      let isActive = dict["isActive"] as? Bool else {
                    return nil
                }
                
                var lastSeen: Date? = nil
                if let timestamp = dict["lastSeen"] as? TimeInterval, timestamp > 0 {
                    lastSeen = Date(timeIntervalSince1970: timestamp)
                }
                
                return WatchPoolDevice(id: id, name: name, serverID: serverID, isActive: isActive, lastSeen: lastSeen)
            }
            
            if !devices.isEmpty {
                viewModel.devices = devices
                print("⌚️ \(devices.count) périphériques synchronisés")
            }
        }
        
        // Serveur actuel
        if let currentServerIDString = context["currentServerID"] as? String,
           let currentServerID = UUID(uuidString: currentServerIDString) {
            if let server = viewModel.servers.first(where: { $0.id == currentServerID }) {
                viewModel.currentServer = server
                print("⌚️ Serveur actuel synchronisé : \(server.name)")
            }
        }
        
        // Périphérique sélectionné
        if let selectedDeviceIDString = context["selectedDeviceID"] as? String,
           let selectedDeviceID = UUID(uuidString: selectedDeviceIDString) {
            if let device = viewModel.devices.first(where: { $0.id == selectedDeviceID }) {
                viewModel.selectedDevice = device
                print("⌚️ Périphérique sélectionné synchronisé : \(device.name)")
            }
        }
        
        viewModel.saveData()
    }
    
    private func updateSensorData(with dict: [String: Any]) {
        guard let viewModel = viewModel else { return }
        
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let timestamp = dict["timestamp"] as? TimeInterval else {
            return
        }
        
        let temperature = dict["temperature"] as? Double
        let pH = dict["pH"] as? Double
        let chlorine = dict["chlorine"] as? Double
        let orp = dict["orp"] as? Double
        
        let sensorData = WatchSensorData(
            id: id,
            temperature: temperature,
            pH: pH,
            chlorine: chlorine,
            orp: orp,
            timestamp: Date(timeIntervalSince1970: timestamp)
        )
        
        viewModel.sensorData = sensorData
        viewModel.lastUpdateTime = Date()
        viewModel.saveData()
        
        print("⌚️ Données de capteurs synchronisées - Temp: \(temperature ?? 0)°C, pH: \(pH ?? 0)")
    }
}
