//
//  NotificationSettings.swift
//  PoolSensors
//
//  Created by Julien Heinen on 16/10/2025.
//

import Foundation

struct NotificationThresholds: Codable {
    // Seuils de température
    var temperatureMin: Double = 15.0
    var temperatureMax: Double = 30.0
    
    // Seuils de pH
    var phMin: Double = 7.0
    var phMax: Double = 7.6
    
    // Seuils de chlore
    var chlorineMin: Double = 1.0
    var chlorineMax: Double = 3.0
    
    // Seuils d'ORP
    var orpMin: Double = 650.0
    var orpMax: Double = 800.0
    
    // Activer/désactiver les notifications par type
    var enableTemperatureAlerts: Bool = true
    var enablePhAlerts: Bool = true
    var enableChlorineAlerts: Bool = true
    var enableOrpAlerts: Bool = true
    var enableConnectionAlerts: Bool = true
    
    // Cooldown pour éviter les spams (en secondes)
    var alertCooldownDuration: TimeInterval = 300 // 5 minutes
    
    // Sauvegarde/chargement
    private static let key = "notification_thresholds"
    
    static func load() -> NotificationThresholds {
        guard let data = UserDefaults.standard.data(forKey: key),
              let thresholds = try? JSONDecoder().decode(NotificationThresholds.self, from: data) else {
            return NotificationThresholds()
        }
        return thresholds
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
            print("💾 Seuils de notification sauvegardés")
        }
    }
}

// Gestionnaire de cooldown pour éviter les notifications en double
class NotificationCooldownManager {
    static let shared = NotificationCooldownManager()
    
    private var lastAlertTimes: [String: Date] = [:]
    
    func canSendAlert(for category: String, cooldown: TimeInterval) -> Bool {
        if let lastTime = lastAlertTimes[category] {
            let elapsed = Date().timeIntervalSince(lastTime)
            return elapsed >= cooldown
        }
        return true
    }
    
    func recordAlert(for category: String) {
        lastAlertTimes[category] = Date()
    }
    
    func reset() {
        lastAlertTimes.removeAll()
    }
}
