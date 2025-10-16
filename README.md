# PoolSensors

Application iOS native pour la surveillance et la gestion de piscines connectées via MQTT.

## Description

PoolSensors est une application SwiftUI permettant de monitorer en temps réel les paramètres physico-chimiques d'une piscine (température, pH, chlore, ORP) via des capteurs connectés à un serveur MQTT. L'application offre une interface intuitive pour visualiser les données, configurer des seuils d'alerte et calibrer les capteurs.

## Fonctionnalités

### Gestion des serveurs MQTT
- Connexion à un ou plusieurs serveurs MQTT
- Configuration des paramètres (hôte, port, authentification, SSL/TLS)
- Test de connexion en temps réel
- Support des messages MQTT retained pour récupération automatique des dernières valeurs

### Gestion des périphériques
- Ajout et configuration de multiples capteurs
- Association de chaque capteur à un serveur MQTT spécifique
- Filtrage des périphériques par serveur dans le tableau de bord
- Affichage du statut de connexion (en ligne/hors ligne)
- Configuration des topics MQTT personnalisés

### Tableau de bord
- Visualisation en temps réel des données de capteurs
- Affichage des dernières valeurs pour chaque paramètre
- Cartes de données avec code couleur selon les seuils
- Sélection dynamique du serveur et du périphérique actif
- Mise à jour automatique via abonnements MQTT

### Système de notifications
- Alertes locales pour dépassement de seuils (température, pH, chlore, ORP)
- Configuration personnalisée des valeurs minimales et maximales
- Système de cooldown pour éviter le spam de notifications (configurable)
- Activation/désactivation par paramètre
- Bouton de test pour vérifier les notifications

### Calibration des capteurs
- Interface de calibration professionnelle à deux points
- Support de la calibration zero-point (offset uniquement)
- Support de la calibration two-point (offset + slope)
- Calculs automatiques de l'offset et du coefficient de pente
- Sauvegarde persistante des calibrations dans UserDefaults
- Instructions contextuelles pour chaque étape
- Validation des valeurs saisies

### Historique et export
- Affichage chronologique des mesures
- Conservation de l'historique des données reçues
- Export des données au format CSV
- Partage des données via la feuille de partage iOS
- Confirmation avant suppression de l'historique

### Interface utilisateur
- Design SwiftUI moderne et réactif
- Mode clair/sombre automatique
- Navigation intuitive avec onglets
- Formulaires de configuration détaillés
- Alertes de confirmation pour actions destructives

## Architecture technique

### Technologies utilisées
- **SwiftUI**: Framework UI déclaratif
- **Combine**: Gestion réactive des flux de données
- **CocoaMQTT**: Client MQTT pour iOS (v2.1.9)
- **UserNotifications**: Système de notifications locales
- **UserDefaults**: Persistance des préférences et calibrations

### Structure du projet

```
PoolSensors/
├── App/
│   └── ContentView.swift                 # Vue principale avec TabView
├── Core/
│   ├── Models/
│   │   ├── MQTTServer.swift             # Modèle serveur MQTT
│   │   ├── PoolDevice.swift             # Modèle périphérique
│   │   ├── PoolSensorData.swift         # Données de capteurs
│   │   └── NotificationSettings.swift   # Configuration notifications
│   ├── Services/
│   │   ├── MQTTService.swift            # Service MQTT avec queue
│   │   └── NotificationService.swift    # Gestion notifications
│   └── ViewModels/
│       └── AppViewModel.swift           # ViewModel principal
├── Features/
│   ├── Authentification/                # (réservé pour futur)
│   ├── Home/
│   │   └── Views/
│   │       └── DashboardView.swift      # Tableau de bord
│   ├── DeviceSettings/
│   │   └── Views/
│   │       ├── DeviceSettingsView.swift # Configuration périphérique
│   │       └── CalibrationView.swift    # Calibration capteurs
│   ├── Settings/
│   │   └── Views/
│   │       ├── SettingsView.swift       # Paramètres généraux
│   │       └── NotificationSettingsView.swift
│   └── History/
│       └── Views/
│           └── HistoryView.swift        # Historique des mesures
└── Resources/
    └── Assets.xcassets/                 # Ressources graphiques
```

### Modèles de données

#### MQTTServer
```swift
struct MQTTServer: Identifiable, Codable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String?
    var password: String?
    var useTLS: Bool
}
```

#### PoolDevice
```swift
struct PoolDevice: Identifiable, Codable {
    let id: UUID
    var name: String
    var serverID: UUID
    var mqttTopic: String
    var isActive: Bool
    var lastSeen: Date?
}
```

#### PoolSensorData
```swift
struct PoolSensorData: Identifiable, Codable {
    let id: UUID
    var temperature: Double?
    var pH: Double?
    var chlorine: Double?
    var orp: Double?
    var timestamp: Date
}
```

### Service MQTT

Le service MQTT implémente un système de queue pour gérer les abonnements avant connexion :

```swift
class MQTTService: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var receivedData: PoolSensorData?
    
    private var pendingSubscriptions: Set<String> = []
    
    // Les subscriptions sont mises en queue si non connecté
    // et traitées automatiquement après didConnectAck
}
```

### Service de notifications

Système de notifications avec cooldown pour éviter le spam :

```swift
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var thresholds: NotificationThresholds
    
    func checkPoolValues(_ data: PoolSensorData)
    func sendAlertWithCooldown(...)
    func requestAuthorization()
}
```

## Configuration MQTT

### Format des messages

L'application s'attend à recevoir des messages JSON sur les topics configurés :

```json
{
  "temperature": 25.5,
  "pH": 7.2,
  "chlorine": 1.5,
  "orp": 650
}
```

### Topics MQTT

Format recommandé : `pool/sensor/<device_id>`

Exemple : `pool/sensor/main`

### QoS et Retained

- QoS 1 utilisé pour garantir la livraison
- Messages retained recommandés pour récupération au démarrage
- Reconnexion automatique en cas de perte de connexion

## Installation

### Prérequis

- Xcode 15.0 ou supérieur
- iOS 16.0 ou supérieur
- Swift 5.9 ou supérieur
- Compte développeur Apple (pour déploiement sur appareil)

### Dépendances

Le projet utilise Swift Package Manager pour gérer les dépendances :

- **CocoaMQTT** (v2.1.9) : Client MQTT
  - Repository : https://github.com/emqx/CocoaMQTT

### Étapes d'installation

1. Cloner le repository :
```bash
git clone https://github.com/julienheinen/PoolSensors_SwiftUI.git
cd PoolSensors_SwiftUI
```

2. Ouvrir le projet dans Xcode :
```bash
open PoolSensors.xcodeproj
```

3. Attendre la résolution automatique des dépendances Swift Package Manager

4. Sélectionner une cible de déploiement (simulateur ou appareil)

5. Compiler et exécuter (Cmd+R)

## Configuration initiale

### Premier lancement

1. **Ajouter un serveur MQTT** :
   - Aller dans l'onglet Paramètres
   - Appuyer sur "Ajouter un serveur"
   - Configurer les paramètres de connexion
   - Tester la connexion

2. **Ajouter un périphérique** :
   - Aller dans l'onglet Sélection
   - Appuyer sur "+"
   - Renseigner le nom et le topic MQTT
   - Associer au serveur créé précédemment

3. **Configurer les notifications** (optionnel) :
   - Aller dans Paramètres > Notifications
   - Activer les notifications souhaitées
   - Définir les seuils min/max
   - Autoriser les notifications iOS si demandé

4. **Calibrer les capteurs** (optionnel) :
   - Sélectionner un périphérique dans le dashboard
   - Aller dans Informations du capteur
   - Accéder à "Calibrer les capteurs"
   - Suivre les instructions pour chaque capteur

## Utilisation

### Surveillance en temps réel

1. Dans l'onglet Tableau de bord
2. Sélectionner le serveur actif
3. Sélectionner le périphérique à monitorer
4. Les données s'affichent automatiquement

### Calibration d'un capteur

#### Mode Zero-Point (offset uniquement)
1. Sélectionner le capteur à calibrer
2. Choisir "Zero-Point"
3. Plonger le capteur dans une solution de référence connue
4. Entrer la valeur de référence et la valeur mesurée
5. Appliquer la calibration

#### Mode Two-Point (offset + pente)
1. Sélectionner le capteur à calibrer
2. Choisir "Two-Point"
3. Premier point : solution de référence basse
4. Deuxième point : solution de référence haute
5. Appliquer la calibration

Formule appliquée : `Valeur corrigée = (Valeur mesurée × pente) + offset`

### Export des données

1. Aller dans Paramètres
2. Appuyer sur "Exporter les données"
3. Choisir l'application de destination
4. Les données sont exportées au format CSV

## Sécurité

### Connexions MQTT
- Support TLS/SSL pour connexions sécurisées
- Authentification par username/password
- Mots de passe stockés de manière sécurisée dans le Keychain iOS (à implémenter)

### Données locales
- Persistance via UserDefaults (solution légère actuelle)
- Recommandation future : migration vers CoreData ou Keychain pour données sensibles

### Permissions iOS
- Notifications locales : autorisation demandée au premier usage
- Aucune permission réseau requise (MQTT fonctionne en arrière-plan)

## Limitations connues

- L'historique des données est conservé en mémoire (perdu au redémarrage de l'app)
- Pas de graphiques temporels (fonctionnalité future)
- Pas de synchronisation cloud des configurations
- Calibration non appliquée automatiquement aux données (implémentation future)
- Connexion MQTT interrompue en arrière-plan (limitation iOS)

## Roadmap

### Version 1.1
- [ ] Application automatique des calibrations aux données reçues
- [ ] Persistance de l'historique avec CoreData
- [ ] Graphiques temporels avec Swift Charts
- [ ] Widget iOS pour affichage rapide

### Version 1.2
- [ ] Synchronisation iCloud des configurations
- [ ] Export automatique périodique
- [ ] Alertes push via serveur
- [ ] Support de multiples pools

### Version 2.0
- [ ] Authentification utilisateur
- [ ] Backend API REST
- [ ] Partage de données entre utilisateurs
- [ ] Analyses prédictives

## Contribution

Les contributions sont les bienvenues. Pour contribuer :

1. Fork le projet
2. Créer une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

### Standards de code

- Respecter les conventions Swift standard
- Commenter les fonctions complexes
- Utiliser SwiftUI pour toutes les vues
- Éviter les force unwraps (`!`)
- Privilégier les `guard let` et `if let`

## Support

Pour toute question ou problème :
- Ouvrir une issue sur GitHub
- Contacter : julienheinen@example.com

## Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## Auteur

Julien Heinen - Développement initial

## Remerciements

- Projet de piscine connectée
- Communauté CocoaMQTT pour le client MQTT
- Communauté SwiftUI pour les ressources et exemples