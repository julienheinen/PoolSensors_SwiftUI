//
//  PoolSensorData.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import Foundation

struct PoolSensorData: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let temperature: Double
    let ph: Double
    let chlorine: Double
    let orp: Double // Potentiel d'oxydo-réduction
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case temperature
        case ph
        case chlorine
        case orp
    }
    
    init(id: UUID = UUID(), timestamp: Date = Date(), temperature: Double, ph: Double, chlorine: Double, orp: Double) {
        self.id = id
        self.timestamp = timestamp
        self.temperature = temperature
        self.ph = ph
        self.chlorine = chlorine
        self.orp = orp
    }
    
    // Décodage personnalisé pour gérer le timestamp optionnel et différents formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // id est optionnel, générer un nouveau si absent
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        
        // timestamp avec support de multiples formats ISO8601
        if let timestampString = try? container.decode(String.self, forKey: .timestamp) {
            let iso8601Formatter = ISO8601DateFormatter()
            
            // Essayer d'abord avec les millisecondes
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: timestampString) {
                self.timestamp = date
            } else {
                // Essayer sans les millisecondes
                iso8601Formatter.formatOptions = [.withInternetDateTime]
                if let date = iso8601Formatter.date(from: timestampString) {
                    self.timestamp = date
                } else {
                    print("⚠️ Format de timestamp non reconnu: \(timestampString), utilisation de Date()")
                    self.timestamp = Date()
                }
            }
        } else if let timestampDouble = try? container.decode(Double.self, forKey: .timestamp) {
            // Support du timestamp Unix (secondes depuis epoch)
            self.timestamp = Date(timeIntervalSince1970: timestampDouble)
        } else if let timestampInt = try? container.decode(Int.self, forKey: .timestamp) {
            // Support du timestamp Unix en entier
            self.timestamp = Date(timeIntervalSince1970: TimeInterval(timestampInt))
        } else {
            // Utiliser l'heure actuelle si aucun timestamp n'est fourni
            self.timestamp = Date()
        }
        
        // Les valeurs des capteurs sont obligatoires
        self.temperature = try container.decode(Double.self, forKey: .temperature)
        self.ph = try container.decode(Double.self, forKey: .ph)
        self.chlorine = try container.decode(Double.self, forKey: .chlorine)
        self.orp = try container.decode(Double.self, forKey: .orp)
    }
    
    // Encodage personnalisé pour sauvegarder au format ISO8601
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        // Encoder le timestamp en ISO8601
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: timestamp), forKey: .timestamp)
        
        try container.encode(temperature, forKey: .temperature)
        try container.encode(ph, forKey: .ph)
        try container.encode(chlorine, forKey: .chlorine)
        try container.encode(orp, forKey: .orp)
    }
}

// Données de capteur agrégées
struct SensorReading: Identifiable {
    let id: UUID
    let name: String
    let value: String
    let unit: String
    let status: SensorStatus
    let icon: String
    
    init(id: UUID = UUID(), name: String, value: String, unit: String, status: SensorStatus, icon: String) {
        self.id = id
        self.name = name
        self.value = value
        self.unit = unit
        self.status = status
        self.icon = icon
    }
}

enum SensorStatus {
    case normal
    case warning
    case critical
    case offline
    
    var color: String {
        switch self {
        case .normal: return "green"
        case .warning: return "orange"
        case .critical: return "red"
        case .offline: return "gray"
        }
    }
}
