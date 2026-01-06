<img width="128" height="128" alt="256x256 logo" src="https://github.com/user-attachments/assets/f865d827-914f-494f-8591-169af50c92c1" />
<img width="128" height="128" alt="dark_1024x1024" src="https://github.com/user-attachments/assets/7f798b15-5257-48cf-82c4-aac98bff48c8" />


# PoolSensors

Application iOS et watchOS native pour la surveillance et la gestion de piscines connectées via MQTT.

## Description

PoolSensors est une application SwiftUI permettant de monitorer en temps réel les paramètres physico-chimiques d'une piscine (température, pH, chlore, ORP) via des capteurs connectés à un serveur MQTT. L'application offre une interface intuitive pour visualiser les données, configurer des seuils d'alerte et calibrer les capteurs.

Une application compagnon Apple Watch est également disponible pour une consultation rapide des données directement au poignet.

### Contexte du projet

Ce projet a été développé dans le cadre d'un projet de BUT 3ème année. Mon équipe de 3 personnes a pour mission de concevoir et développer un système complet de capteurs connectés pour piscine. Cette application iOS constitue l'interface utilisateur du système, permettant aux utilisateurs de surveiller et gérer leur piscine de manière autonome.

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
- Pull-to-refresh pour forcer la reconnexion au serveur MQTT

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

### Application Apple Watch
- Dashboard simplifié avec les 4 paramètres essentiels
- **Synchronisation automatique en temps réel avec l'iPhone via WatchConnectivity**
- Sélection du serveur et du périphérique actif synchronisés
- Interface optimisée pour le petit écran
- Actualisation manuelle avec synchronisation instantanée
- Indicateur visuel d'état de connexion iPhone
- Consultation rapide sans sortir le téléphone
- Données de capteurs mises à jour en temps réel

## Captures d'écran

<img width="276" height="570" alt="Capture écran Dashboard" src="https://github.com/user-attachments/assets/317915e3-fb24-432d-b7a7-36bc0597969c" />
<img width="276" height="570" alt="Capture écran Historique" src="https://github.com/user-attachments/assets/cbba9c55-7f8d-409c-ad05-790c329af25b" />
<img width="276" height="570" alt="Capture écran Capteurs" src="https://github.com/user-attachments/assets/ed569863-19d3-403a-b215-d018697c64c1" />
<img width="276" height="570" alt="Capture écran gestion" src="https://github.com/user-attachments/assets/818068ca-9eb8-4a20-889a-1129102b638e" />
<img width="276" height="570" alt="Capture écran Paramètres" src="https://github.com/user-attachments/assets/5b171744-cbfc-42eb-8e06-a73e22950fc5" />
<img width="276" height="570" alt="Capture écran notifications" src="https://github.com/user-attachments/assets/54e5ad6a-71bc-427c-9c0d-d0b01c91f4fc" />



## Architecture technique

### Technologies utilisées
- **SwiftUI**: Framework UI déclaratif
- **Combine**: Gestion réactive des flux de données
- **CocoaMQTT**: Client MQTT pour iOS (v2.1.9)
- **UserNotifications**: Système de notifications locales
- **UserDefaults**: Persistance des préférences et calibrations

### Structure du projet

```
PoolSensors/ (iOS App)
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

PoolSensorsWatchOS Watch App/ (watchOS App)
├── Models/
│   └── SharedModels.swift               # Modèles simplifiés pour watchOS
├── ViewModels/
│   └── WatchViewModel.swift             # ViewModel watchOS
├── Views/
│   ├── DashboardView.swift              # Dashboard principal watchOS
│   ├── ServerPickerView.swift           # Sélection serveur
│   ├── DevicePickerView.swift           # Sélection périphérique
│   └── Components/
│       └── WatchSensorCard.swift        # Carte de capteur
└── Assets.xcassets/                     # Ressources watchOS
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

4. Sélectionner une cible de déploiement :
   - **PoolSensors** : Application iOS (iPhone/iPad)
   - **PoolSensorsWatchOS Watch App** : Application watchOS (Apple Watch)

5. Compiler et exécuter (Cmd+R)

### Exécuter sur Apple Watch

Pour tester l'application watchOS :

1. Connecter votre iPhone et Apple Watch
2. Sélectionner la cible "PoolSensorsWatchOS Watch App"
3. Sélectionner votre Apple Watch comme destination
4. Compiler et exécuter

Alternativement, utiliser le simulateur watchOS dans Xcode.

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

### Rafraîchir les données

Pour forcer une reconnexion au serveur MQTT et actualiser les données :

1. Dans le tableau de bord, tirer vers le bas (pull-to-refresh)
2. L'application se déconnecte puis se reconnecte automatiquement
3. Les abonnements MQTT sont rétablis
4. Les dernières valeurs retained sont récupérées

Ce geste est utile en cas de :
- Perte de connexion réseau
- Valeurs qui ne se mettent plus à jour
- Changement de réseau Wi-Fi
- Besoin de forcer la synchronisation

### Utilisation sur Apple Watch

L'application watchOS offre un accès rapide aux données principales :

#### Premier lancement
1. Lancer l'app sur votre Apple Watch
2. Des données de démonstration sont automatiquement créées
3. Naviguer dans l'interface pour sélectionner serveur et périphérique

#### Sélectionner un serveur
1. Sur le dashboard, appuyer sur la carte bleue "Serveur"
2. Parcourir la liste des serveurs disponibles
3. Appuyer sur le serveur désiré
4. Le serveur sélectionné affiche une coche verte

#### Sélectionner un périphérique
1. Sur le dashboard, appuyer sur la carte verte "Périphérique"
2. La liste affiche uniquement les périphériques du serveur actif
3. Appuyer sur le périphérique désiré
4. Le périphérique sélectionné affiche une coche bleue

#### Actualiser les données
1. Appuyer sur l'icône de rafraîchissement (en haut à droite)
2. Les données se mettent à jour avec un indicateur de chargement
3. L'horodatage de mise à jour est affiché en bas du dashboard

#### Navigation
- Utiliser la Digital Crown pour scroller dans les listes
- Appuyer sur les cartes pour naviguer
- Swiper vers la gauche pour revenir en arrière

#### Vérifier la synchronisation

**Indicateurs visuels sur la Watch :**
- 🟢 **"Synchronisé"** : iPhone connecté, données à jour
- 🟠 **"iPhone déconnecté"** : iPhone hors de portée ou Bluetooth désactivé

**Pour forcer une synchronisation :**
1. Appuyer sur le bouton de rafraîchissement (en haut à droite)
2. La Watch demande les dernières données à l'iPhone
3. L'interface se met à jour automatiquement

**Synchronisation automatique :**
- Les changements sur l'iPhone sont automatiquement envoyés à la Watch
- Les données MQTT reçues sur l'iPhone sont transférées en temps réel
- Pas besoin d'intervention manuelle dans l'utilisation normale

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

### iOS
- L'historique des données est conservé en mémoire (perdu au redémarrage de l'app)
- Pas de graphiques temporels (fonctionnalité future)
- Pas de synchronisation cloud des configurations
- Calibration non appliquée automatiquement aux données (implémentation future)
- Connexion MQTT interrompue en arrière-plan (limitation iOS)

### watchOS
- Pas de connexion MQTT directe (dépend de l'iPhone pour les données)
- Pas de complications pour le cadran (fonctionnalité future)
- Pas de notifications natives watchOS (fonctionnalité future)
- Pas de synchronisation bidirectionnelle (Watch → iPhone) pour l'instant

## Roadmap

### Version 1.0 (actuelle)
- [x] Application iOS complète avec dashboard
- [x] Gestion MQTT avec pendingSubscriptions
- [x] Système de notifications avec seuils
- [x] Calibration des capteurs (zero-point et two-point)
- [x] Export CSV des données
- [x] Pull-to-refresh pour reconnexion
- [x] Application Apple Watch avec dashboard simplifié
- [x] **Synchronisation automatique iPhone ↔ Apple Watch via WatchConnectivity**
- [x] **Transfert temps réel des données de capteurs vers la Watch**
- [x] **Synchronisation des serveurs et périphériques**

### Version 1.1
- [ ] Application automatique des calibrations aux données reçues
- [ ] Persistance de l'historique avec CoreData
- [ ] Graphiques temporels avec Swift Charts
- [ ] Widget iOS pour affichage rapide
- [ ] Synchronisation bidirectionnelle Watch → iPhone

### Version 1.2
- [ ] Synchronisation iCloud des configurations
- [ ] Export automatique périodique
- [ ] Alertes push via serveur
- [ ] Support de multiples pools
- [ ] Complications watchOS pour le cadran

### Version 2.0
- [ ] Authentification utilisateur
- [ ] Backend API REST
- [ ] Partage de données entre utilisateurs
- [ ] Analyses prédictives
- [ ] Notifications natives watchOS
- [ ] Mode hors ligne amélioré pour watchOS

## Application Apple Watch

### État actuel

Une application watchOS complète est incluse dans le projet avec les fonctionnalités suivantes :

#### Fonctionnalités implémentées
- **Dashboard simplifié** : Affichage des 4 paramètres principaux (température, pH, chlore, ORP)
- **Sélection serveur** : Liste interactive des serveurs MQTT configurés
- **Sélection périphérique** : Liste filtrée par serveur actif
- **Actualisation manuelle** : Bouton de rafraîchissement dans la barre de navigation
- **Persistance locale** : Sauvegarde des préférences dans UserDefaults
- **Interface optimisée** : Design adapté au petit écran de l'Apple Watch

#### Architecture watchOS

L'application utilise une architecture avec synchronisation automatique :

```swift
// Modèles légers pour économie de ressources
WatchMQTTServer, WatchPoolDevice, WatchSensorData

// ViewModel avec synchronisation
WatchViewModel: ObservableObject {
    - Gestion de l'état local
    - Réception des données iPhone
    - Sauvegarde UserDefaults
}

// Gestionnaire de synchronisation
WatchConnectivityManager: NSObject, WCSessionDelegate {
    - Activation WCSession
    - Réception Application Context (serveurs, périphériques)
    - Réception Messages (données capteurs temps réel)
    - Mise à jour du ViewModel
}

// Vues optimisées
DashboardView       // Vue principale avec indicateur de sync
ServerPickerView    // Sélection serveur
DevicePickerView    // Sélection périphérique
WatchSensorCard     // Composant carte
```

#### Synchronisation automatique implémentée

La synchronisation iPhone ↔ Apple Watch est **complètement fonctionnelle** :

**Architecture de synchronisation :**
```swift
// Sur iPhone (PhoneConnectivityManager)
class PhoneConnectivityManager: NSObject, WCSessionDelegate {
    func configure(with viewModel: AppViewModel) {
        // Observe les changements avec Combine
        viewModel.$servers.sink { _ in
            self.sendDataToWatch()  // Sync automatique
        }
    }
    
    func sendDataToWatch() {
        try? WCSession.default.updateApplicationContext(context)
    }
    
    func sendSensorDataToWatch() {
        if WCSession.default.isReachable {
            // Transfert instantané
            WCSession.default.sendMessage(message, replyHandler: nil)
        } else {
            // Transfert en arrière-plan
            WCSession.default.transferUserInfo(message)
        }
    }
}

// Sur Watch (WatchConnectivityManager)
class WatchConnectivityManager: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, didReceiveApplicationContext context: [String : Any]) {
        // Mise à jour automatique serveurs/périphériques
        updateViewModel(with: context)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Mise à jour temps réel données capteurs
        updateSensorData(with: message)
    }
}
```

**Données synchronisées automatiquement :**
- ✅ Liste des serveurs MQTT
- ✅ Liste des périphériques
- ✅ Serveur actuellement connecté
- ✅ Périphérique sélectionné
- ✅ Données de capteurs en temps réel (température, pH, chlore, ORP)
- ✅ État de connexion et horodatages

**Modes de transfert :**
- **Instantané** : Quand la Watch est réveillée (sendMessage)
- **Arrière-plan** : Quand la Watch est en veille (transferUserInfo)
- **Context** : Configuration persistante (updateApplicationContext)

### Développement futur watchOS

#### Version 1.1
- Synchronisation bidirectionnelle iPhone/Watch via WatchConnectivity
- Transfert des données en temps réel
- Mise à jour automatique en arrière-plan

#### Version 1.2
- Complications pour le cadran (affichage température et pH)
- Notifications natives watchOS
- Historique local limité

#### Version 2.0
- Mode standalone avec connexion réseau directe
- Graphiques miniatures
- Contrôles vocaux Siri

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
