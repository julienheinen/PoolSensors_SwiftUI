//
//  MQTTService.swift
//  PoolSensors
//
//  Created by Julien Heinen on 15/10/2025.
//

import Foundation
import Combine
import CocoaMQTT

/// Service de gestion MQTT pour recevoir les données des capteurs de piscine
class MQTTService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isConnected: Bool = false
    @Published var lastMessage: String = ""
    @Published var connectionError: String?
    @Published var receivedData: PoolSensorData?
    
    // MARK: - Private Properties
    private var mqtt: CocoaMQTT?
    private var currentServer: MQTTServer?
    private var subscribedTopics: Set<String> = []
    private var pendingSubscriptions: Set<String> = []
    
    // MARK: - Connection Management
    
    /// Connexion au serveur MQTT
    func connect(to server: MQTTServer) {
        // Déconnexion de la session précédente si elle existe
        disconnect()
        
        self.currentServer = server
        
        // Créer un ID client unique
        let clientID = "PoolSensors-\(UUID().uuidString)"
        
        // Initialiser CocoaMQTT (TCP standard)
        mqtt = CocoaMQTT(clientID: clientID, host: server.host, port: UInt16(server.port))
        
        guard let mqtt = mqtt else {
            connectionError = "Impossible de créer le client MQTT"
            print("❌ Erreur: Impossible de créer le client MQTT")
            return
        }
        
        // Configuration du client
        mqtt.username = server.username ?? ""
        mqtt.password = server.password ?? ""
        mqtt.keepAlive = 60
        mqtt.delegate = self
        mqtt.enableSSL = server.useTLS
        // Note: allowUntrustCertificate n'existe pas dans cette version
        
        // Tentative de connexion
        let success = mqtt.connect()
        
        if success {
            print("🔄 Connexion en cours à: \(server.host):\(server.port)")
        } else {
            connectionError = "Échec de la connexion au serveur MQTT"
            print("❌ Connexion échouée: \(server.host):\(server.port)")
        }
    }
    
    /// Déconnexion du serveur MQTT
    func disconnect() {
        mqtt?.disconnect()
        mqtt = nil
        subscribedTopics.removeAll()
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.currentServer = nil
        }
        
        print("🔌 Déconnecté du serveur MQTT")
    }
    
    // MARK: - Topic Management
    
    /// S'abonner à un topic MQTT
    func subscribe(to topic: String) {
        guard let mqtt = mqtt else {
            print("⚠️ Pas de client MQTT. Topic en attente: \(topic)")
            pendingSubscriptions.insert(topic)
            return
        }
        
        if isConnected {
            mqtt.subscribe(topic, qos: .qos1)
            subscribedTopics.insert(topic)
            print("📡 Abonnement au topic: \(topic)")
        } else {
            print("⏳ Connexion en cours. Topic en attente: \(topic)")
            pendingSubscriptions.insert(topic)
        }
    }
    
    /// Se désabonner d'un topic MQTT
    func unsubscribe(from topic: String) {
        guard let mqtt = mqtt, isConnected else { return }
        
        mqtt.unsubscribe(topic)
        subscribedTopics.remove(topic)
        print("🔕 Désabonnement du topic: \(topic)")
    }
    
    /// Publier un message sur un topic
    func publish(message: String, to topic: String) {
        guard let mqtt = mqtt, isConnected else {
            print("⚠️ Non connecté. Impossible de publier sur: \(topic)")
            return
        }
        
        mqtt.publish(topic, withString: message, qos: .qos1)
        print("📤 Publication sur \(topic): \(message)")
    }
    
    // MARK: - Data Parsing
    
    /// Analyser les données JSON reçues du capteur
    private func parsePoolSensorData(from message: String) -> PoolSensorData? {
        // Nettoyer le message en supprimant les retours à la ligne et espaces superflus
        let cleanedMessage = message
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedMessage.data(using: .utf8) else {
            print("⚠️ Impossible de convertir le message en Data")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            // Ne pas forcer iso8601, laisser le décodeur personnalisé gérer le timestamp
            let sensorData = try decoder.decode(PoolSensorData.self, from: data)
            
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            
            print("✅ Données MQTT parsées avec succès:")
            print("   📅 Timestamp: \(formatter.string(from: sensorData.timestamp))")
            print("   🌡️ Température: \(sensorData.temperature)°C")
            print("   💧 pH: \(sensorData.ph)")
            print("   🧪 Chlore: \(sensorData.chlorine) mg/L")
            print("   ⚡ ORP: \(sensorData.orp) mV")
            
            return sensorData
        } catch {
            print("⚠️ Erreur de parsing JSON: \(error)")
            print("📄 Message reçu: '\(cleanedMessage)'")
            
            // Afficher les détails de l'erreur
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   ❌ Clé manquante: \(key.stringValue)")
                    print("   📍 Contexte: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("   ❌ Type incompatible: attendu \(type)")
                    print("   � Contexte: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("   ❌ Valeur manquante pour le type: \(type)")
                    print("   📍 Contexte: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("   ❌ Données corrompues")
                    print("   📍 Contexte: \(context.debugDescription)")
                @unknown default:
                    print("   ❌ Erreur inconnue")
                }
            }
            
            // Essayer un format simplifié
            return parseSimpleFormat(from: message)
        }
    }
    
    /// Parser un format simplifié (par exemple: "temp:24.5,ph:7.2,chlorine:1.8,orp:685")
    private func parseSimpleFormat(from message: String) -> PoolSensorData? {
        let components = message.split(separator: ",")
        var temp: Double?
        var ph: Double?
        var chlorine: Double?
        var orp: Double?
        
        for component in components {
            let parts = component.split(separator: ":")
            guard parts.count == 2 else { continue }
            
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces).lowercased()
            let value = Double(parts[1].trimmingCharacters(in: .whitespaces))
            
            switch key {
            case "temp", "temperature": temp = value
            case "ph": ph = value
            case "chlorine", "cl": chlorine = value
            case "orp": orp = value
            default: break
            }
        }
        
        if let temp = temp, let ph = ph, let chlorine = chlorine, let orp = orp {
            return PoolSensorData(temperature: temp, ph: ph, chlorine: chlorine, orp: orp)
        }
        
        return nil
    }
}

// MARK: - CocoaMQTTDelegate
extension MQTTService: CocoaMQTTDelegate {
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        DispatchQueue.main.async {
            if ack == .accept {
                self.isConnected = true
                self.connectionError = nil
                print("✅ Connecté au serveur MQTT")
                
                // S'abonner aux topics en attente
                if !self.pendingSubscriptions.isEmpty {
                    print("📝 \(self.pendingSubscriptions.count) topic(s) en attente d'abonnement")
                    for topic in self.pendingSubscriptions {
                        mqtt.subscribe(topic, qos: .qos1)
                        self.subscribedTopics.insert(topic)
                        print("📡 Abonnement au topic: \(topic)")
                    }
                    self.pendingSubscriptions.removeAll()
                }
            } else {
                self.connectionError = "Connexion refusée: \(ack)"
                print("❌ Connexion refusée: \(ack)")
            }
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("📤 Message publié sur \(message.topic) (id: \(id))")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("✅ Publication confirmée (id: \(id))")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        guard let messageString = message.string else {
            print("⚠️ Message reçu mais impossible de le décoder")
            return
        }
        
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = formatter.string(from: timestamp)
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📥 NOUVEAU MESSAGE MQTT REÇU")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("⏰ Heure de réception: \(timeString)")
        print("📡 Topic: \(message.topic)")
        print("🔢 Message ID: \(id)")
        print("♻️ Retained: \(message.retained ? "OUI (message en cache)" : "NON (message frais)")")
        print("📦 QoS: \(message.qos)")
        print("📄 Payload brut:")
        print(messageString)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        DispatchQueue.main.async {
            self.lastMessage = messageString
            
            // Tenter de parser les données du capteur
            if let sensorData = self.parsePoolSensorData(from: messageString) {
                self.receivedData = sensorData
                print("✅ Données transmises à l'interface utilisateur")
            }
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        if !failed.isEmpty {
            print("❌ Échec d'abonnement aux topics: \(failed)")
        }
        if !success.allKeys.isEmpty {
            print("✅ Abonné aux topics: \(success.allKeys)")
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        print("🔕 Désabonné des topics: \(topics)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        // Ping périodique - connexion active
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        // Pong reçu - serveur répond
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            
            if let error = err {
                self.connectionError = "Déconnecté: \(error.localizedDescription)"
                print("❌ Déconnexion avec erreur: \(error.localizedDescription)")
            } else {
                print("🔌 Déconnecté du serveur MQTT")
            }
        }
    }
}
