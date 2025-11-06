//
//  SharedModels.swift
//  PoolSensorsWatchOS Watch App
//
//  Created by Julien Heinen on 16/10/2025.
//

import Foundation

// Modèles simplifiés pour watchOS (synchronisés depuis iOS)

struct WatchMQTTServer: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isConnected: Bool
    
    init(id: UUID = UUID(), name: String, isConnected: Bool = false) {
        self.id = id
        self.name = name
        self.isConnected = isConnected
    }
}

struct WatchPoolDevice: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var serverID: UUID
    var isActive: Bool
    var lastSeen: Date?
    
    init(id: UUID = UUID(), name: String, serverID: UUID, isActive: Bool = false, lastSeen: Date? = nil) {
        self.id = id
        self.name = name
        self.serverID = serverID
        self.isActive = isActive
        self.lastSeen = lastSeen
    }
}

struct WatchSensorData: Identifiable, Codable {
    let id: UUID
    var temperature: Double?
    var pH: Double?
    var chlorine: Double?
    var orp: Double?
    var timestamp: Date
    
    init(id: UUID = UUID(), temperature: Double? = nil, pH: Double? = nil, chlorine: Double? = nil, orp: Double? = nil, timestamp: Date = Date()) {
        self.id = id
        self.temperature = temperature
        self.pH = pH
        self.chlorine = chlorine
        self.orp = orp
        self.timestamp = timestamp
    }
}

struct SensorReading: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let unit: String
    let color: SensorColor
    
    enum SensorColor {
        case blue, green, cyan, purple
    }
}
