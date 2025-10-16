//
//  AppViewModel.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import Foundation
import Combine

class AppViewModel: ObservableObject {
    @Published var servers: [MQTTServer] = []
    @Published var devices: [PoolDevice] = []
    @Published var selectedDevice: PoolDevice?
    @Published var currentServer: MQTTServer?
    @Published var sensorData: [PoolSensorData] = []
    @Published var currentReadings: [SensorReading] = []
    
    let mqttService = MQTTService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadData()
        setupMQTTObservers()
        // generateMockData() - Désactivé pour utiliser uniquement les vraies données MQTT
    }
    
    // MARK: - MQTT Data Observers
    private func setupMQTTObservers() {
        // Observer les données reçues du service MQTT
        mqttService.$receivedData
            .compactMap { $0 }
            .sink { [weak self] sensorData in
                self?.updateReadings(from: sensorData)
                self?.updateDeviceStatus(isActive: true)
            }
            .store(in: &cancellables)
        
        // Observer l'état de connexion
        mqttService.$isConnected
            .sink { [weak self] isConnected in
                self?.updateServerConnectionStatus(isConnected: isConnected)
            }
            .store(in: &cancellables)
    }
    
    private func updateReadings(from sensorData: PoolSensorData) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔄 MISE À JOUR DES LECTURES (AppViewModel)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🌡️ Température: \(sensorData.temperature)°C")
        print("💧 pH: \(sensorData.ph)")
        print("🧪 Chlore: \(sensorData.chlorine) mg/L")
        print("⚡ ORP: \(sensorData.orp) mV")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Vérifier les seuils et envoyer des notifications si nécessaire
        NotificationService.shared.checkPoolValues(sensorData)
        
        DispatchQueue.main.async {
            // Mettre à jour les lectures actuelles
            self.currentReadings = [
                SensorReading(
                    name: "Température",
                    value: String(format: "%.1f", sensorData.temperature),
                    unit: "°C",
                    status: self.temperatureStatus(sensorData.temperature),
                    icon: "thermometer"
                ),
                SensorReading(
                    name: "pH",
                    value: String(format: "%.1f", sensorData.ph),
                    unit: "",
                    status: self.phStatus(sensorData.ph),
                    icon: "drop.fill"
                ),
                SensorReading(
                    name: "Chlore",
                    value: String(format: "%.1f", sensorData.chlorine),
                    unit: "mg/L",
                    status: self.chlorineStatus(sensorData.chlorine),
                    icon: "circle.hexagongrid.fill"
                ),
                SensorReading(
                    name: "ORP",
                    value: String(format: "%.0f", sensorData.orp),
                    unit: "mV",
                    status: self.orpStatus(sensorData.orp),
                    icon: "waveform.path.ecg"
                )
            ]
            
            print("✅ Interface mise à jour avec \(self.currentReadings.count) lectures")
            
            // Ajouter aux données historiques
            self.sensorData.append(sensorData)
            print("📊 \(self.sensorData.count) mesure(s) dans l'historique")
        }
    }
    
    private func updateDeviceStatus(isActive: Bool) {
        if let index = devices.firstIndex(where: { $0.id == selectedDevice?.id }) {
            let wasActive = devices[index].isActive
            devices[index].isActive = isActive
            devices[index].lastSeen = Date()
            selectedDevice = devices[index]
            
            // Notification si changement d'état
            if NotificationService.shared.thresholds.enableConnectionAlerts {
                if !wasActive && isActive {
                    // Connexion rétablie
                    NotificationService.shared.notifyConnectionRestored(deviceName: devices[index].name)
                } else if wasActive && !isActive {
                    // Connexion perdue
                    NotificationService.shared.notifyConnectionLost(deviceName: devices[index].name)
                }
            }
        }
    }
    
    private func updateServerConnectionStatus(isConnected: Bool) {
        if let serverID = currentServer?.id,
           let index = servers.firstIndex(where: { $0.id == serverID }) {
            servers[index].isConnected = isConnected
            currentServer = servers[index]
        }
    }
    
    // MARK: - Status Helpers
    private func temperatureStatus(_ temp: Double) -> SensorStatus {
        if temp < 20 || temp > 30 { return .warning }
        if temp < 15 || temp > 35 { return .critical }
        return .normal
    }
    
    private func phStatus(_ ph: Double) -> SensorStatus {
        if ph < 6.8 || ph > 7.6 { return .warning }
        if ph < 6.5 || ph > 8.0 { return .critical }
        return .normal
    }
    
    private func chlorineStatus(_ cl: Double) -> SensorStatus {
        if cl < 1.0 || cl > 3.0 { return .warning }
        if cl < 0.5 || cl > 5.0 { return .critical }
        return .normal
    }
    
    private func orpStatus(_ orp: Double) -> SensorStatus {
        if orp < 600 || orp > 750 { return .warning }
        if orp < 500 || orp > 800 { return .critical }
        return .normal
    }
    
    // MARK: - Device Management
    func addDevice(_ device: PoolDevice) {
        devices.append(device)
        saveData()
    }
    
    func selectDevice(_ device: PoolDevice) {
        selectedDevice = device
        
        // S'assurer que le serveur du périphérique est connecté
        if let server = servers.first(where: { $0.id == device.serverID }) {
            if !server.isConnected {
                connectToServer(server)
            }
            mqttService.subscribe(to: device.mqttTopic)
        } else {
            print("⚠️ Serveur associé au périphérique introuvable")
        }
        
        saveData()
    }
    
    func removeDevice(_ device: PoolDevice) {
        devices.removeAll { $0.id == device.id }
        if selectedDevice?.id == device.id {
            selectedDevice = nil
        }
        saveData()
    }
    
    // MARK: - MQTT Server Management
    func addServer(_ server: MQTTServer) {
        servers.append(server)
        saveData()
    }
    
    func connectToServer(_ server: MQTTServer) {
        // Mettre à jour l'état de connexion des serveurs
        for i in 0..<servers.count {
            servers[i].isConnected = (servers[i].id == server.id)
        }
        
        currentServer = servers.first(where: { $0.id == server.id })
        
        // Désélectionner le périphérique si il n'appartient pas au nouveau serveur
        if let selectedDevice = selectedDevice,
           selectedDevice.serverID != server.id {
            self.selectedDevice = nil
            print("⚠️ Périphérique désélectionné car il appartient à un autre serveur")
        }
        
        mqttService.connect(to: server)
        saveData()
    }
    
    func removeServer(_ server: MQTTServer) {
        servers.removeAll { $0.id == server.id }
        if currentServer?.id == server.id {
            currentServer = nil
            mqttService.disconnect()
        }
        saveData()
    }
    
    // MARK: - Data Persistence
    
    private let serversKey = "mqtt_servers"
    private let devicesKey = "pool_devices"
    private let selectedDeviceIDKey = "selected_device_id"
    private let currentServerIDKey = "current_server_id"
    
    func saveData() {
        let encoder = JSONEncoder()
        
        // Sauvegarder les serveurs MQTT
        if let serversData = try? encoder.encode(servers) {
            UserDefaults.standard.set(serversData, forKey: serversKey)
            print("💾 \(servers.count) serveur(s) MQTT sauvegardé(s)")
        }
        
        // Sauvegarder les périphériques
        if let devicesData = try? encoder.encode(devices) {
            UserDefaults.standard.set(devicesData, forKey: devicesKey)
            print("💾 \(devices.count) périphérique(s) sauvegardé(s)")
        }
        
        // Sauvegarder le périphérique sélectionné
        if let selectedDevice = selectedDevice {
            UserDefaults.standard.set(selectedDevice.id.uuidString, forKey: selectedDeviceIDKey)
            print("💾 Périphérique sélectionné: \(selectedDevice.name)")
        } else {
            UserDefaults.standard.removeObject(forKey: selectedDeviceIDKey)
        }
        
        // Sauvegarder le serveur actuel
        if let currentServer = currentServer {
            UserDefaults.standard.set(currentServer.id.uuidString, forKey: currentServerIDKey)
            print("💾 Serveur actuel: \(currentServer.name)")
        } else {
            UserDefaults.standard.removeObject(forKey: currentServerIDKey)
        }
        
        UserDefaults.standard.synchronize()
        print("✅ Données sauvegardées avec succès")
    }
    
    func loadData() {
        let decoder = JSONDecoder()
        
        // Charger les serveurs MQTT
        if let serversData = UserDefaults.standard.data(forKey: serversKey),
           let loadedServers = try? decoder.decode([MQTTServer].self, from: serversData) {
            servers = loadedServers
            print("📂 \(servers.count) serveur(s) MQTT chargé(s)")
        } else {
            print("📂 Aucun serveur MQTT sauvegardé")
        }
        
        // Charger les périphériques
        if let devicesData = UserDefaults.standard.data(forKey: devicesKey),
           let loadedDevices = try? decoder.decode([PoolDevice].self, from: devicesData) {
            devices = loadedDevices
            print("📂 \(devices.count) périphérique(s) chargé(s)")
        } else {
            print("📂 Aucun périphérique sauvegardé")
        }
        
        // Restaurer le serveur actuel
        if let currentServerIDString = UserDefaults.standard.string(forKey: currentServerIDKey),
           let currentServerID = UUID(uuidString: currentServerIDString),
           let server = servers.first(where: { $0.id == currentServerID }) {
            currentServer = server
            print("📂 Serveur actuel restauré: \(server.name)")
        }
        
        // Restaurer le périphérique sélectionné
        if let selectedDeviceIDString = UserDefaults.standard.string(forKey: selectedDeviceIDKey),
           let selectedDeviceID = UUID(uuidString: selectedDeviceIDString),
           let device = devices.first(where: { $0.id == selectedDeviceID }) {
            selectedDevice = device
            print("📂 Périphérique sélectionné restauré: \(device.name)")
            
            // Se connecter automatiquement au serveur du périphérique
            if let server = servers.first(where: { $0.id == device.serverID }) {
                connectToServer(server)
                mqttService.subscribe(to: device.mqttTopic)
            }
        }
    }
    
    /// Effacer toutes les données sauvegardées
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: serversKey)
        UserDefaults.standard.removeObject(forKey: devicesKey)
        UserDefaults.standard.removeObject(forKey: selectedDeviceIDKey)
        UserDefaults.standard.removeObject(forKey: currentServerIDKey)
        UserDefaults.standard.synchronize()
        
        servers = []
        devices = []
        selectedDevice = nil
        currentServer = nil
        
        print("🗑️ Toutes les données ont été effacées")
    }
    
    // MARK: - Mock Data (pour le développement)
    private func generateMockData() {
        currentReadings = [
            SensorReading(name: "Température", value: "24.5", unit: "°C", status: .normal, icon: "thermometer"),
            SensorReading(name: "pH", value: "7.2", unit: "", status: .normal, icon: "drop.fill"),
            SensorReading(name: "Chlore", value: "1.8", unit: "mg/L", status: .warning, icon: "circle.hexagongrid.fill"),
            SensorReading(name: "ORP", value: "685", unit: "mV", status: .normal, icon: "waveform.path.ecg")
        ]
    }
}
