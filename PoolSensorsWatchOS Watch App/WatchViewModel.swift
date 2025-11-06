//
//  WatchViewModel.swift
//  PoolSensorsWatchOS Watch App
//
//  Created by Julien Heinen on 16/10/2025.
//

import Foundation
import Combine

class WatchViewModel: ObservableObject {
    // Données
    @Published var servers: [WatchMQTTServer] = []
    @Published var devices: [WatchPoolDevice] = []
    @Published var currentServer: WatchMQTTServer?
    @Published var selectedDevice: WatchPoolDevice?
    @Published var sensorData: WatchSensorData?
    @Published var lastUpdateTime: Date = Date()
    
    // État UI
    @Published var isLoading = false
    
    init() {
        loadMockData()
    }
    
    // MARK: - Computed Properties
    
    var currentReadings: [SensorReading] {
        guard let data = sensorData else {
            return []
        }
        
        var readings: [SensorReading] = []
        
        if let temp = data.temperature {
            readings.append(SensorReading(
                title: "Température",
                value: String(format: "%.1f", temp),
                unit: "°C",
                color: .blue
            ))
        }
        
        if let ph = data.pH {
            readings.append(SensorReading(
                title: "pH",
                value: String(format: "%.2f", ph),
                unit: "",
                color: .green
            ))
        }
        
        if let chlorine = data.chlorine {
            readings.append(SensorReading(
                title: "Chlore",
                value: String(format: "%.2f", chlorine),
                unit: "mg/L",
                color: .cyan
            ))
        }
        
        if let orp = data.orp {
            readings.append(SensorReading(
                title: "ORP",
                value: String(format: "%.0f", orp),
                unit: "mV",
                color: .purple
            ))
        }
        
        return readings
    }
    
    var filteredDevices: [WatchPoolDevice] {
        guard let server = currentServer else {
            return []
        }
        return devices.filter { $0.serverID == server.id }
    }
    
    // MARK: - Actions
    
    func selectServer(_ server: WatchMQTTServer) {
        currentServer = server
        
        // Mettre à jour l'état de connexion
        for i in 0..<servers.count {
            servers[i].isConnected = (servers[i].id == server.id)
        }
        
        // Désélectionner le périphérique si il n'appartient pas au nouveau serveur
        if let selectedDevice = selectedDevice,
           selectedDevice.serverID != server.id {
            self.selectedDevice = nil
        }
        
        saveData()
    }
    
    func selectDevice(_ device: WatchPoolDevice) {
        selectedDevice = device
        saveData()
    }
    
    func refreshData() {
        isLoading = true
        lastUpdateTime = Date()
        
        // Demander une mise à jour depuis l'iPhone via WatchConnectivity
        WatchConnectivityManager.shared.requestUpdateFromPhone()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
        }
    }
    
    // MARK: - Data Persistence
    
    private let serversKey = "watch_mqtt_servers"
    private let devicesKey = "watch_pool_devices"
    private let currentServerKey = "watch_current_server"
    private let selectedDeviceKey = "watch_selected_device"
    private let sensorDataKey = "watch_sensor_data"
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(encoded, forKey: serversKey)
        }
        
        if let encoded = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(encoded, forKey: devicesKey)
        }
        
        if let server = currentServer, let encoded = try? JSONEncoder().encode(server) {
            UserDefaults.standard.set(encoded, forKey: currentServerKey)
        }
        
        if let device = selectedDevice, let encoded = try? JSONEncoder().encode(device) {
            UserDefaults.standard.set(encoded, forKey: selectedDeviceKey)
        }
        
        if let data = sensorData, let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: sensorDataKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: serversKey),
           let decoded = try? JSONDecoder().decode([WatchMQTTServer].self, from: data) {
            servers = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: devicesKey),
           let decoded = try? JSONDecoder().decode([WatchPoolDevice].self, from: data) {
            devices = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: currentServerKey),
           let decoded = try? JSONDecoder().decode(WatchMQTTServer.self, from: data) {
            currentServer = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: selectedDeviceKey),
           let decoded = try? JSONDecoder().decode(WatchPoolDevice.self, from: data) {
            selectedDevice = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: sensorDataKey),
           let decoded = try? JSONDecoder().decode(WatchSensorData.self, from: data) {
            sensorData = decoded
        }
    }
    
    // MARK: - Mock Data
    
    private func loadMockData() {
        // Charger les données sauvegardées depuis WatchConnectivity ou démo
        loadData()
        
        // Note: Les données de démo ne sont plus créées automatiquement
        // Les données seront synchronisées depuis l'iPhone via WatchConnectivity
        // Si aucune donnée n'est disponible, l'interface affichera un message approprié
        
        print("⌚️ ViewModel initialisé - Serveurs: \(servers.count), Périphériques: \(devices.count)")
    }
}
