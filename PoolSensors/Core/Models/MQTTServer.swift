//
//  MQTTServer.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import Foundation

struct MQTTServer: Identifiable, Codable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String?
    var password: String?
    var useTLS: Bool
    var isConnected: Bool
    
    init(id: UUID = UUID(), name: String, host: String, port: Int = 1883, username: String? = nil, password: String? = nil, useTLS: Bool = false, isConnected: Bool = false) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.useTLS = useTLS
        self.isConnected = isConnected
    }
}
