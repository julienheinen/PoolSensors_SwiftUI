//
//  PoolDevice.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import Foundation

struct PoolDevice: Identifiable, Codable {
    let id: UUID
    var name: String
    var deviceType: String
    var mqttTopic: String
    var serverID: UUID  // ID du serveur MQTT auquel appartient ce périphérique
    var isActive: Bool
    var lastSeen: Date?
    
    init(id: UUID = UUID(), name: String, deviceType: String = "Pool Sensor", mqttTopic: String, serverID: UUID, isActive: Bool = false, lastSeen: Date? = nil) {
        self.id = id
        self.name = name
        self.deviceType = deviceType
        self.mqttTopic = mqttTopic
        self.serverID = serverID
        self.isActive = isActive
        self.lastSeen = lastSeen
    }
}
