//
//  NotificationService.swift
//  PoolSensors
//
//  Created by Julien Heinen on 16/10/2025.
//

import Foundation
import UserNotifications
import Combine

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var thresholds = NotificationThresholds.load()
    
    private let cooldownManager = NotificationCooldownManager.shared
    
    private init() {
        checkAuthorizationStatus()
        registerNotificationCategories()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    print("✅ Notifications autorisées")
                } else {
                    print("❌ Notifications refusées")
                }
                
                if let error = error {
                    print("❌ Erreur d'autorisation: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notifications de seuils
    
    func checkPoolValues(_ data: PoolSensorData) {
        // Vérifier la température
        if thresholds.enableTemperatureAlerts {
            if data.temperature < thresholds.temperatureMin {
                sendAlertWithCooldown(
                    title: "🌡️ Température Basse",
                    body: "La température de la piscine est de \(data.temperature)°C (seuil: \(thresholds.temperatureMin)°C)",
                    category: "temperature"
                )
            } else if data.temperature > thresholds.temperatureMax {
                sendAlertWithCooldown(
                    title: "🌡️ Température Élevée",
                    body: "La température de la piscine est de \(data.temperature)°C (seuil: \(thresholds.temperatureMax)°C)",
                    category: "temperature"
                )
            }
        }
        
        // Vérifier le pH
        if thresholds.enablePhAlerts {
            if data.ph < thresholds.phMin {
                sendAlertWithCooldown(
                    title: "⚠️ pH Acide",
                    body: "Le pH est de \(data.ph) - Ajoutez du pH+ (seuil: \(thresholds.phMin))",
                    category: "ph"
                )
            } else if data.ph > thresholds.phMax {
                sendAlertWithCooldown(
                    title: "⚠️ pH Basique",
                    body: "Le pH est de \(data.ph) - Ajoutez du pH- (seuil: \(thresholds.phMax))",
                    category: "ph"
                )
            }
        }
        
        // Vérifier le chlore
        if thresholds.enableChlorineAlerts {
            if data.chlorine < thresholds.chlorineMin {
                sendAlertWithCooldown(
                    title: "🧪 Chlore Insuffisant",
                    body: "Le chlore est de \(data.chlorine) mg/L - Ajoutez du chlore (seuil: \(thresholds.chlorineMin))",
                    category: "chlorine"
                )
            } else if data.chlorine > thresholds.chlorineMax {
                sendAlertWithCooldown(
                    title: "🧪 Chlore Excessif",
                    body: "Le chlore est de \(data.chlorine) mg/L - Trop élevé (seuil: \(thresholds.chlorineMax))",
                    category: "chlorine"
                )
            }
        }
        
        // Vérifier l'ORP
        if thresholds.enableOrpAlerts {
            if data.orp < thresholds.orpMin {
                sendAlertWithCooldown(
                    title: "⚡ ORP Faible",
                    body: "L'ORP est de \(data.orp) mV - Désinfection insuffisante (seuil: \(thresholds.orpMin))",
                    category: "orp"
                )
            } else if data.orp > thresholds.orpMax {
                sendAlertWithCooldown(
                    title: "⚡ ORP Élevé",
                    body: "L'ORP est de \(data.orp) mV - Trop élevé (seuil: \(thresholds.orpMax))",
                    category: "orp"
                )
            }
        }
    }
    
    // Envoi avec cooldown pour éviter le spam
    private func sendAlertWithCooldown(title: String, body: String, category: String) {
        guard cooldownManager.canSendAlert(for: category, cooldown: thresholds.alertCooldownDuration) else {
            print("⏳ Alerte ignorée (cooldown actif): \(category)")
            return
        }
        
        sendNotification(title: title, body: body, category: category)
        cooldownManager.recordAlert(for: category)
    }
    
    // MARK: - Envoi de notifications
    
    func sendNotification(title: String, body: String, category: String, delay: TimeInterval = 0) {
        guard isAuthorized else {
            print("⚠️ Notifications non autorisées, notification ignorée")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category
        
        // Ajouter un identifiant unique par catégorie pour éviter les doublons
        let identifier = "pool_alert_\(category)"
        
        // Retirer la notification précédente de la même catégorie
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        
        let trigger: UNNotificationTrigger?
        if delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = nil // Notification immédiate
        }
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Erreur d'envoi de notification: \(error.localizedDescription)")
            } else {
                print("📤 Notification envoyée: \(title)")
            }
        }
    }
    
    // MARK: - Notification de connexion
    
    func notifyConnectionLost(deviceName: String) {
        sendNotification(
            title: "🔌 Connexion Perdue",
            body: "Le capteur \(deviceName) ne répond plus",
            category: "connection"
        )
    }
    
    func notifyConnectionRestored(deviceName: String) {
        sendNotification(
            title: "✅ Connexion Rétablie",
            body: "Le capteur \(deviceName) est de nouveau en ligne",
            category: "connection"
        )
    }
    
    // MARK: - Gestion des catégories d'actions
    
    func registerNotificationCategories() {
        // Actions pour les notifications de pH
        let phAction = UNNotificationAction(
            identifier: "VIEW_PH",
            title: "Voir les détails",
            options: .foreground
        )
        let phCategory = UNNotificationCategory(
            identifier: "ph",
            actions: [phAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Actions pour les notifications de chlore
        let chlorineAction = UNNotificationAction(
            identifier: "VIEW_CHLORINE",
            title: "Voir les détails",
            options: .foreground
        )
        let chlorineCategory = UNNotificationCategory(
            identifier: "chlorine",
            actions: [chlorineAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Enregistrer toutes les catégories
        UNUserNotificationCenter.current().setNotificationCategories([
            phCategory,
            chlorineCategory
        ])
    }
    
    // MARK: - Suppression des notifications
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("🗑️ Toutes les notifications supprimées")
    }
    
    func clearNotificationsByCategory(_ category: String) {
        let identifier = "pool_alert_\(category)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}
