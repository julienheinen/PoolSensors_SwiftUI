# Documentation technique détaillée – PoolSensors

> Version 1.0 – brouillon initial généré, à compléter et ajuster au fil du projet.

## 0. Sommaire

1. [Introduction et objectifs du projet](#1-introduction-et-objectifs-du-projet)  
2. [Vue d’ensemble de l’architecture](#2-vue-densemble-de-larchitecture)  
3. [Technologies et bibliothèques utilisées](#3-technologies-et-bibliothèques-utilisées)  
4. [Modèles de données iOS (Core/Models)](#4-modèles-de-données-ios-coremodels)  
5. [Services iOS (Core/Services)](#5-services-ios-coreservices)  
6. [ViewModel principal iOS (Core/ViewModels)](#6-viewmodel-principal-ios-coreviewmodels)  
7. [Vues principales iOS (App & Features)](#7-vues-principales-ios-app--features)  
8. [Application watchOS et synchronisation](#8-application-watchos-et-synchronisation)  
9. [Gestion de la persistance et des préférences](#9-gestion-de-la-persistance-et-des-préférences)  
10. [Gestion des erreurs, limites actuelles et pistes d’amélioration](#10-gestion-des-erreurs-limites-actuelles-et-pistes-damélioration)  
11. [Choix de conception, compromis et alternatives possibles](#11-choix-de-conception-compromis-et-alternatives-possibles)  
12. [Conclusion rapide](#12-conclusion-rapide)

---

## 1. Introduction et objectifs du projet

Cette documentation a pour but d’expliquer de manière assez détaillée comment l’application **PoolSensors** est structurée et pourquoi certains choix techniques ont été faits.

L’idée n’est pas de vendre une application parfaite, mais plutôt de documenter honnêtement :

- comment le code est organisé ;
- comment les données circulent entre les capteurs, le serveur MQTT, l’iPhone et l’Apple Watch ;
- pourquoi certaines bibliothèques ont été choisies (par exemple **CocoaMQTT** plutôt qu’une autre) ;
- ce qui pourrait être amélioré avec plus de temps ou d’expérience.

Donc pour résumer, ce document est là pour :

1. aider quelqu’un qui reprend le projet à comprendre où regarder ;
2. garder une trace des décisions techniques (même celles qui sont un peu bricolées) ;
3. servir de support de présentation si besoin (projet de BUT, soutenance, etc.).


## 2. Vue d’ensemble de l’architecture

### 2.1 Couches principales

L’application iOS est organisée en plusieurs "couches" assez simples :

- **Core** :
  - `Models` : les structures de données (serveur MQTT, périphérique, mesures, etc.).
  - `Services` : la logique métier réutilisable (connexion MQTT, notifications, connectivité iPhone/Watch).
  - `ViewModels` : la colle entre les services et l’interface SwiftUI.
- **App** : point d’entrée SwiftUI (`ContentView`, `PoolSensorsApp`).
- **Features** : les écrans regroupés par fonctionnalité (sélection de périphérique, settings, dashboard, etc.).
- **Ressources** : assets graphiques.

Pour watchOS, il y a une architecture parallèle, plus légère, qui se base sur des **modèles simplifiés** et sur la synchronisation avec l’iPhone via **WatchConnectivity**.

### 2.2 Flux de données global

Le chemin typique des données ressemble à ça :

1. Un capteur envoie un message MQTT (JSON) au serveur.
2. `MQTTService` (iOS) est connecté au serveur avec **CocoaMQTT** et est abonné au bon topic.
3. À chaque message reçu, `MQTTService` :
   - logge le message,
   - parse le JSON en `PoolSensorData`,
   - publie la donnée via sa propriété `@Published receivedData`.
4. `AppViewModel` observe `receivedData` avec **Combine** et met à jour :
   - les `currentReadings` (affichage temps réel),
   - l’historique `sensorData` (pour l’historique, export CSV, etc.),
   - l’état du périphérique (actif, dernier contact).
5. `NotificationService` est appelé pour vérifier les seuils et éventuellement déclencher une notification locale.
6. En parallèle, via `PhoneConnectivityManager`, les données peuvent être envoyées à l’Apple Watch.

Bref, la logique est : **capteur → MQTT → MQTTService → AppViewModel → SwiftUI / notifications / Watch**.


## 3. Technologies et bibliothèques utilisées

### 3.1 SwiftUI

L’interface est construite en **SwiftUI**, principalement pour :

- profiter du binding entre `@State` / `@ObservedObject` / `@EnvironmentObject` et l’affichage ;
- garder une syntaxe déclarative et relativement lisible ;
- gérer facilement le mode clair/sombre.

Une alternative aurait été d’utiliser UIKit + Storyboards, mais pour un projet récent et orienté iOS 16+, SwiftUI reste plus naturel.

### 3.2 Combine

**Combine** est utilisé surtout pour :

- observer les propriétés `@Published` de `MQTTService` dans `AppViewModel` ;
- réagir aux nouveaux messages MQTT (`receivedData`) ;
- suivre l’état de connexion MQTT (`isConnected`).

Un exemple dans `AppViewModel` :

```swift
private func setupMQTTObservers() {
	// Observer les données reçues du service MQTT
	mqttService.$receivedData
		.compactMap { $0 }
		.sink { [weak self] sensorData in
			self?.updateReadings(from: sensorData)
			self?.updateDeviceStatus(isActive: true)
		}
		.store(in: &cancellables)
}
```

Ici, le `sink` sert de pont entre les données réseaux (MQTT) et la logique de mise à jour côté interface.

### 3.3 CocoaMQTT

Pour la partie MQTT, la bibliothèque choisie est **CocoaMQTT** :

- elle est relativement simple à intégrer via Swift Package Manager ;
- elle expose un client orienté objet (`CocoaMQTT`) avec un delegate (`CocoaMQTTDelegate`) ;
- elle gère différents QoS, les messages retained, la reconnection, etc.

Un extrait typique de configuration du client dans `MQTTService` :

```swift
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
		return
	}

	mqtt.username = server.username ?? ""
	mqtt.password = server.password ?? ""
	mqtt.keepAlive = 60
	mqtt.delegate = self
	mqtt.enableSSL = server.useTLS

	_ = mqtt.connect()
}
```

Quelques remarques honnêtes :

- Le `clientID` pourrait être plus stable (lié au device) plutôt qu’un UUID aléatoire à chaque connexion, mais ici ce n’était pas critique.
- La configuration TLS est minimale (`enableSSL = server.useTLS`). Une version plus aboutie gérerait les certificats, la validation stricte, etc.
- Le code ne gère pas encore tous les cas d’erreur possibles (timeouts, reconnections automatiques plus avancées, etc.).

Pour la gestion des messages reçus, le delegate CocoaMQTT est utilisé :

```swift
func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
	guard let messageString = message.string else {
		print("⚠️ Message reçu mais impossible de le décoder")
		return
	}

	DispatchQueue.main.async {
		self.lastMessage = messageString

		// Tenter de parser les données du capteur
		if let sensorData = self.parsePoolSensorData(from: messageString) {
			self.receivedData = sensorData
		}
	}
}
```

On voit ici le rôle central de `parsePoolSensorData` qui transforme une `String` JSON en structure `PoolSensorData` exploitable dans le reste de l’app.

### 3.4 UserNotifications

Le framework **UserNotifications** est utilisé via un service maison `NotificationService` (singleton). Il permet :

- de demander l’autorisation d’envoyer des notifications locales ;
- de programmer des notifications en fonction des seuils définis (pH, chlore, etc.) ;
- de gérer un "cooldown" pour éviter le spam.

L’idée ici n’est pas de réinventer une couche de notification, mais juste d’enrober UserNotifications dans une API plus simple à utiliser depuis `AppViewModel`.

### 3.5 WatchConnectivity

**WatchConnectivity** est utilisée pour synchroniser :

- la liste des serveurs ;
- la liste des périphériques ;
- le serveur / périphérique sélectionné ;
- les dernières mesures reçues.

Le `PhoneConnectivityManager` côté iPhone et le `WatchConnectivityManager` côté Watch se chargent de :

- envoyer un `applicationContext` pour la configuration (serveurs / périphériques) ;
- envoyer des `messages` ou `userInfo` pour les données temps réel.

### 3.6 UserDefaults

Pour la persistance légère (serveurs, périphériques, sélection actuelle), l’app utilise **UserDefaults** avec encodage JSON :

```swift
if let serversData = try? encoder.encode(servers) {
	UserDefaults.standard.set(serversData, forKey: serversKey)
}
```

Clairement, pour une version plus avancée, une base type **CoreData** serait plus robuste (notamment pour l’historique des mesures). Ici, l’objectif était d’avoir quelque chose qui fonctionne rapidement sans gérer un schéma de base de données complet.


## 4. Modèles de données iOS (Core/Models)

### 4.1 `MQTTServer`

Le modèle `MQTTServer` représente un serveur MQTT configuré dans l’app :

```swift
struct MQTTServer: Identifiable, Codable {
	let id: UUID
	var name: String
	var host: String
	var port: Int
	var username: String?
	var password: String?
	var useTLS: Bool
	var isConnected: Bool
}
```

Quelques points :

- `Identifiable` est pratique pour les listes SwiftUI (`ForEach`).
- `Codable` permet la sauvegarde directe via `JSONEncoder` / `JSONDecoder`.
- `isConnected` est dérivé de l’état réel du client MQTT, mais stocké ici pour simplifier l’affichage.

Lien avec le reste :

- `AppViewModel` maintient un tableau `[MQTTServer]`.
- `MQTTService` utilise `MQTTServer` pour récupérer `host`, `port`, credentials, etc. au moment de la connexion.

### 4.2 `PoolDevice`

Le modèle `PoolDevice` représente un capteur (ou un périphérique) relié à un serveur MQTT :

```swift
struct PoolDevice: Identifiable, Codable {
	let id: UUID
	var name: String
	var deviceType: String
	var mqttTopic: String
	var serverID: UUID  // ID du serveur MQTT auquel appartient ce périphérique
	var isActive: Bool
	var lastSeen: Date?
}
```

Idées principales :

- `mqttTopic` est le topic sur lequel les données de ce périphérique arrivent.
- `serverID` fait le lien avec un `MQTTServer` donné.
- `isActive` et `lastSeen` sont mis à jour lorsqu’une nouvelle mesure est reçue.

Dans `AppViewModel`, la sélection d’un périphérique déclenche automatiquement :

```swift
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
}
```

Donc pour résumer, `PoolDevice` sert de pivot entre l’interface (sélection de périphérique) et le topic MQTT à écouter.

### 4.3 `PoolSensorData`

`PoolSensorData` est le modèle des mesures reçues :

```swift
struct PoolSensorData: Identifiable, Codable {
	let id: UUID
	let timestamp: Date
	let temperature: Double
	let ph: Double
	let chlorine: Double
	let orp: Double
}
```

La particularité est surtout dans le **décodage personnalisé** pour supporter plusieurs formats de timestamp :

```swift
// Décodage personnalisé pour gérer le timestamp optionnel et différents formats
init(from decoder: Decoder) throws {
	let container = try decoder.container(keyedBy: CodingKeys.self)

	self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()

	if let timestampString = try? container.decode(String.self, forKey: .timestamp) {
		let iso8601Formatter = ISO8601DateFormatter()
		iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
		if let date = iso8601Formatter.date(from: timestampString) {
			self.timestamp = date
		} else {
			iso8601Formatter.formatOptions = [.withInternetDateTime]
			self.timestamp = iso8601Formatter.date(from: timestampString) ?? Date()
		}
	} else if let timestampDouble = try? container.decode(Double.self, forKey: .timestamp) {
		self.timestamp = Date(timeIntervalSince1970: timestampDouble)
	} else if let timestampInt = try? container.decode(Int.self, forKey: .timestamp) {
		self.timestamp = Date(timeIntervalSince1970: TimeInterval(timestampInt))
	} else {
		self.timestamp = Date()
	}

	self.temperature = try container.decode(Double.self, forKey: .temperature)
	self.ph = try container.decode(Double.self, forKey: .ph)
	self.chlorine = try container.decode(Double.self, forKey: .chlorine)
	self.orp = try container.decode(Double.self, forKey: .orp)
}
```

Tout ça pour dire : le modèle est un peu plus défensif que strict. Il accepte plusieurs formats de timestamp, ce qui simplifie la vie si les capteurs n’envoient pas exactement le même format à chaque fois.

### 4.4 `SensorReading` et `SensorStatus`

Ces deux types sont utilisés surtout pour l’affichage sur le dashboard :

```swift
struct SensorReading: Identifiable {
	let id: UUID
	let name: String
	let value: String
	let unit: String
	let status: SensorStatus
	let icon: String
}

enum SensorStatus {
	case normal
	case warning
	case critical
	case offline
}
```

`SensorReading` n’est pas `Codable` car il n’est pas sauvegardé tel quel. Il est reconstruit à partir de `PoolSensorData` dans `AppViewModel` pour alimenter les cartes SwiftUI.


## 5. Services iOS (Core/Services)

### 5.1 `MQTTService` – gestion MQTT avec CocoaMQTT

`MQTTService` encapsule l’utilisation de **CocoaMQTT** et expose un API plus simple au reste de l’app.

#### 5.1.1 Connexion et configuration du client

La méthode principale de connexion :

```swift
func connect(to server: MQTTServer) {
	disconnect()

	self.currentServer = server

	let clientID = "PoolSensors-\(UUID().uuidString)"
	mqtt = CocoaMQTT(clientID: clientID, host: server.host, port: UInt16(server.port))

	guard let mqtt = mqtt else {
		connectionError = "Impossible de créer le client MQTT"
		return
	}

	mqtt.username = server.username ?? ""
	mqtt.password = server.password ?? ""
	mqtt.keepAlive = 60
	mqtt.delegate = self
	mqtt.enableSSL = server.useTLS

	let success = mqtt.connect()
	if !success {
		connectionError = "Échec de la connexion au serveur MQTT"
	}
}
```

Ce qu’on peut en dire :

- La méthode ne gère pas encore un système de reconnexion automatique avancé. Pour l’instant, on laisse CocoaMQTT et l’utilisateur gérer la reconnexion (via un pull-to-refresh côté interface).
- On pourrait externaliser la création du `clientID` pour le rendre plus prévisible.

#### 5.1.2 Gestion des abonnements et file d’attente

Pour éviter de perdre des abonnements si on les demande avant que la connexion soit établie, un système de "pendingSubscriptions" est utilisé :

```swift
private var subscribedTopics: Set<String> = []
private var pendingSubscriptions: Set<String> = []

func subscribe(to topic: String) {
	guard let mqtt = mqtt else {
		pendingSubscriptions.insert(topic)
		return
	}

	if isConnected {
		mqtt.subscribe(topic, qos: .qos1)
		subscribedTopics.insert(topic)
	} else {
		pendingSubscriptions.insert(topic)
	}
}
```

Et dans le delegate, une fois la connexion acceptée :

```swift
func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
	DispatchQueue.main.async {
		if ack == .accept {
			self.isConnected = true
			self.connectionError = nil

			if !self.pendingSubscriptions.isEmpty {
				for topic in self.pendingSubscriptions {
					mqtt.subscribe(topic, qos: .qos1)
					self.subscribedTopics.insert(topic)
				}
				self.pendingSubscriptions.removeAll()
			}
		} else {
			self.connectionError = "Connexion refusée: \(ack)"
		}
	}
}
```

Donc pour résumer : si on appelle `subscribe(to:)` avant que la connexion ne soit prête, le topic part juste dans une `Set` et sera traité plus tard.

#### 5.1.3 Réception et parsing des messages

Lorsqu’un message arrive :

```swift
func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
	guard let messageString = message.string else {
		print("⚠️ Message reçu mais impossible de le décoder")
		return
	}

	DispatchQueue.main.async {
		self.lastMessage = messageString

		if let sensorData = self.parsePoolSensorData(from: messageString) {
			self.receivedData = sensorData
		}
	}
}
```

La fonction `parsePoolSensorData` essaie d’abord de décoder du JSON conforme à `PoolSensorData` :

```swift
private func parsePoolSensorData(from message: String) -> PoolSensorData? {
	let cleanedMessage = message
		.replacingOccurrences(of: "\n", with: "")
		.replacingOccurrences(of: "\r", with: "")
		.trimmingCharacters(in: .whitespacesAndNewlines)

	guard let data = cleanedMessage.data(using: .utf8) else {
		return nil
	}

	do {
		let decoder = JSONDecoder()
		let sensorData = try decoder.decode(PoolSensorData.self, from: data)
		return sensorData
	} catch {
		// Log détaillé, puis tentative avec un format simplifié
		return parseSimpleFormat(from: message)
	}
}
```

L’option `parseSimpleFormat` permet de garder un minimum de robustesse si un capteur envoie un format du type :

```text
temp:24.5,ph:7.2,chlorine:1.8,orp:685
```

Ce n’est pas forcément idéal d’avoir deux formats, mais dans un contexte de projet étudiant avec du matériel qui peut évoluer, c’est un compromis pour ne pas planter l’app.

### 5.2 `NotificationService`

`NotificationService` centralise :

- la configuration des seuils ;
- la vérification des valeurs (`checkPoolValues`) ;
- l’envoi de notifications avec un cooldown pour éviter le spam.

`AppViewModel` l’appelle après chaque nouvelle donnée :

```swift
NotificationService.shared.checkPoolValues(sensorData)
```

Un point à noter : la logique de seuils est ici codée côté app. On pourrait l’externaliser (par exemple dans un backend) pour plus de flexibilité, mais ce n’était pas nécessaire pour la première version.

### 5.3 `PhoneConnectivityManager`

Ce service (côté iPhone) s’occupe de pousser les données vers l’Apple Watch via **WatchConnectivity**. Typiquement :

- envoie les serveurs/périphériques quand ils changent ;
- envoie les dernières mesures de `PoolSensorData`.

L’approche est volontairement simple :

- pas (encore) de synchro bidirectionnelle ;
- la Watch dépend des données de l’iPhone.


## 6. ViewModel principal iOS (Core/ViewModels)

`AppViewModel` est le point central côté iOS :

```swift
class AppViewModel: ObservableObject {
	@Published var servers: [MQTTServer] = []
	@Published var devices: [PoolDevice] = []
	@Published var selectedDevice: PoolDevice?
	@Published var currentServer: MQTTServer?
	@Published var sensorData: [PoolSensorData] = []
	@Published var currentReadings: [SensorReading] = []

	let mqttService = MQTTService()
	private var cancellables = Set<AnyCancellable>()
}
```

Rôles principaux :

1. Gérer la liste des serveurs et des périphériques.
2. Gérer le serveur courant et le périphérique sélectionné.
3. Observer `mqttService` pour mettre à jour les lectures affichées.
4. Sauvegarder/restaurer la configuration via `UserDefaults`.

### 6.1 Mise à jour des lectures

Quand une nouvelle `PoolSensorData` arrive, `updateReadings` construit les `SensorReading` pour le dashboard :

```swift
private func updateReadings(from sensorData: PoolSensorData) {
	NotificationService.shared.checkPoolValues(sensorData)

	DispatchQueue.main.async {
		self.currentReadings = [
			SensorReading(
				name: "Température",
				value: String(format: "%.1f", sensorData.temperature),
				unit: "°C",
				status: self.temperatureStatus(sensorData.temperature),
				icon: "thermometer"
			),
			// ... autres capteurs
		]

		self.sensorData.append(sensorData)
	}
}
```

L’avantage de cette approche, c’est que les vues SwiftUI n’ont pas besoin de connaître la structure exacte de `PoolSensorData`; elles consomment juste un tableau de `SensorReading` prêt à afficher.

### 6.2 Gestion des serveurs et périphériques

Exemple : connexion à un serveur depuis le ViewModel :

```swift
func connectToServer(_ server: MQTTServer) {
	for i in 0..<servers.count {
		servers[i].isConnected = (servers[i].id == server.id)
	}

	currentServer = servers.first(where: { $0.id == server.id })

	if let selectedDevice = selectedDevice,
	   selectedDevice.serverID != server.id {
		self.selectedDevice = nil
	}

	mqttService.connect(to: server)
	saveData()
}
```

Ce n’est pas la gestion d’état la plus sophistiquée du monde, mais pour un projet de cette taille, ça reste lisible.

### 6.3 Persistance avec UserDefaults

`AppViewModel` gère lui-même la sauvegarde et le chargement :

```swift
func saveData() {
	let encoder = JSONEncoder()

	if let serversData = try? encoder.encode(servers) {
		UserDefaults.standard.set(serversData, forKey: serversKey)
	}

	if let devicesData = try? encoder.encode(devices) {
		UserDefaults.standard.set(devicesData, forKey: devicesKey)
	}
}
```

On pourrait discuter de déplacer cette logique dans un service dédié, mais pour l’instant, le fait de l’avoir ici évite de multiplier les couches.


## 7. Vues principales iOS (App & Features)

*(Cette section peut encore être détaillée vue par vue, mais l’idée générale est : chaque Feature a ses propres vues SwiftUI qui consomment `AppViewModel`.)*

- `ContentView` : TabView principale, injection de `AppViewModel` dans l’environnement.
- `DashboardView` : affiche `currentReadings`, permet de rafraîchir la connexion (pull-to-refresh).
- `DeviceSelectionView` : permet de choisir un périphérique et un serveur.
- `SettingsView`, `MQTTServersListView`, `DevicesListView` : gestion des serveurs et périphériques.
- `NotificationSettingsView`, `CalibrationView` : configuration avancée.


## 8. Application watchOS et synchronisation

Sur watchOS, l’app est volontairement plus légère :

- modèles simplifiés ;
- moins de paramètres ;
- focus sur la consultation rapide des 4 valeurs principales.

La synchronisation iPhone ↔ Watch se fait avec **WatchConnectivity** et repose sur :

- un `WatchViewModel` côté Watch ;
- un `WatchConnectivityManager` qui reçoit les contexts/messages et met à jour le ViewModel.

Les mêmes concepts de base se retrouvent :

- serveurs ;
- périphériques ;
- dernières mesures.


## 9. Gestion de la persistance et des préférences

Actuellement :

- **UserDefaults** pour :
  - la liste des serveurs ;
  - la liste des périphériques ;
  - le serveur courant ;
  - le périphérique sélectionné.
- aucun stockage persistant de l’historique détaillé des mesures (l’historique est en mémoire).

Avec plus de temps, on pourrait :

- migrer l’historique vers **CoreData** pour éviter de tout perdre à chaque redémarrage ;
- stocker certains secrets (mots de passe MQTT) dans le **Keychain** plutôt que dans UserDefaults.


## 10. Gestion des erreurs, limites actuelles et pistes d’amélioration

Quelques limites connues :

- La reconnexion MQTT est assez basique (pull-to-refresh manuel plutôt qu’un système automatique avancé).
- La validation des données reçues pourrait être plus stricte (par exemple, vérifier les ranges avant de les accepter).
- L’historique complet n’est pas persistant.
- La partie sécurité (TLS, certificats, stockage des mots de passe) pourrait être renforcée.

Malgré ça, l’objectif de base est atteint : avoir une app capable de se connecter à un serveur MQTT, d’afficher les données en temps réel, de notifier en cas de dépassement de seuil, et de refléter ces infos sur une Apple Watch.


## 11. Choix de conception, compromis et alternatives possibles

Quelques choix assumés :

- **SwiftUI + Combine** : choix logique pour un projet iOS moderne, mais il reste des coins qui pourraient être mieux structurés (par exemple en séparant plus clairement la logique de persistance).
- **CocoaMQTT** : choisi pour sa simplicité. D’autres clients MQTT existent, certains plus complets, mais le but n’était pas de couvrir tous les cas d’usage industriels.
- **UserDefaults** : très pratique pour démarrer vite, moins adapté pour de gros volumes de données.

Alternatives possibles :

- Passage à **CoreData** ou **Realm** pour l’historique.
- Mise en place d’un **backend** (API REST) pour centraliser les données de plusieurs piscines / utilisateurs.
- Gestion plus poussée de la sécurité TLS (certificats clients, validation de chaîne, etc.).

Tout ça pour dire : le code actuel est "suffisant" pour un projet étudiant et une première version fonctionnelle, mais il laisse de la marge pour des évolutions plus professionnelles.


## 12. Conclusion rapide

Cette documentation n’a pas vocation à être parfaite non plus, mais elle essaie au moins de raconter comment l’app est construite, sans enjoliver.

En résumé :

- les modèles décrivent clairement les serveurs, les périphériques et les mesures ;
- `MQTTService` s’appuie sur CocoaMQTT pour faire le lien avec le serveur ;
- `AppViewModel` joue le rôle de chef d’orchestre côté iOS ;
- les vues SwiftUI restent relativement simples en consommant ces données ;
- la Watch récupère une version allégée de tout ça via WatchConnectivity.

Avec plus de temps, il serait intéressant de :

- durcir la partie sécurité ;
- ajouter des graphiques temporels ;
- rendre la persistance de l’historique plus robuste ;
- améliorer la synchro iPhone ↔ Watch (bidirectionnelle, plus autonome).

Mais pour l’instant, l’essentiel est là : surveiller une piscine connectée.
