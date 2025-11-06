# Guide de synchronisation iPhone ↔ Apple Watch

## Vue d'ensemble

La synchronisation entre l'iPhone et l'Apple Watch est maintenant **complètement implémentée** via WatchConnectivity. Les données sont automatiquement partagées en temps réel entre les deux appareils.

## Architecture de synchronisation

### iPhone (PhoneConnectivityManager)
```
AppViewModel → PhoneConnectivityManager → WCSession → Apple Watch
    ↓                      ↓
Combine Publishers    Convertit les données
observe changes       au format compatible
```

### Apple Watch (WatchConnectivityManager)
```
WCSession → WatchConnectivityManager → WatchViewModel → UI
              ↓                            ↓
        Décode les données          Met à jour l'interface
```

## Données synchronisées

### 1. Configuration (Application Context)
Synchronisées automatiquement via `updateApplicationContext`:
- **Serveurs MQTT** : Liste complète des serveurs configurés
- **Périphériques** : Liste complète des périphériques
- **Serveur actuel** : Serveur actuellement connecté
- **Périphérique sélectionné** : Périphérique actif

**Déclencheurs de synchronisation :**
- Ajout/suppression d'un serveur
- Ajout/suppression d'un périphérique
- Changement de serveur actif
- Changement de périphérique sélectionné

### 2. Données de capteurs (Messages)
Synchronisées en temps réel via `sendMessage` ou `transferUserInfo`:
- **Température** : En degrés Celsius
- **pH** : Valeur du pH
- **Chlore** : En mg/L
- **ORP** : En mV
- **Timestamp** : Horodatage de la mesure

**Modes de transfert :**
- **Instantané** : Si l'Apple Watch est accessible (réveillée)
- **Arrière-plan** : Si l'Apple Watch est en veille

## Flux de synchronisation

### Au démarrage de l'app iOS
```
1. PoolSensorsApp.init()
2. PhoneConnectivityManager.shared activé
3. WCSession activée
4. PhoneConnectivityManager.configure(with: viewModel)
5. Observers Combine configurés sur viewModel
6. Envoi initial des données à la Watch
```

### Au démarrage de l'app watchOS
```
1. ContentView.onAppear()
2. WatchConnectivityManager.shared activé
3. WCSession activée
4. WatchConnectivityManager.configure(with: viewModel)
5. requestUpdateFromPhone() appelé
6. Réception et affichage des données
```

### Lors d'un changement sur l'iPhone
```
1. Utilisateur modifie serveur/périphérique
2. AppViewModel @Published déclenche
3. PhoneConnectivityManager.sendDataToWatch()
4. updateApplicationContext() envoyé
5. Watch reçoit didReceiveApplicationContext
6. WatchViewModel mis à jour
7. Interface Watch actualisée automatiquement
```

### Lors de nouvelles données MQTT
```
1. MQTTService reçoit des données
2. AppViewModel.receivedData mis à jour
3. PhoneConnectivityManager.sendSensorDataToWatch()
4. Message instantané ou transfert arrière-plan
5. Watch reçoit les données
6. WatchViewModel.sensorData mis à jour
7. Cartes de capteurs actualisées
```

### Lors d'un refresh sur la Watch
```
1. Utilisateur appuie sur le bouton refresh
2. WatchViewModel.refreshData()
3. WatchConnectivityManager.requestUpdateFromPhone()
4. Message envoyé à l'iPhone
5. iPhone répond avec les dernières données
6. Watch met à jour l'interface
```

## États de connexion

### Activated
- WCSession est active et prête
- La synchronisation peut avoir lieu
- Affichage : ✅ "Synchronisé"

### Not Activated
- WCSession n'est pas encore activée
- En attente d'activation
- Affichage : ⏳ Initialisation...

### Reachable
- L'Apple Watch est réveillée et accessible
- Transfert instantané possible
- Préféré pour les données temps réel

### Not Reachable
- L'Apple Watch est en veille
- Transfert en arrière-plan utilisé
- Données livrées au prochain réveil

## Indicateurs visuels sur la Watch

### État de synchronisation
En haut du dashboard :
- 🟢 **"Synchronisé"** : iPhone connecté et accessible
- 🟠 **"iPhone déconnecté"** : WCSession non activée ou iPhone hors de portée
- (Rien) : Synchronisation en cours

### Serveur actuel
Carte bleue avec :
- 🟢 Cercle vert : Serveur connecté
- Nom du serveur depuis l'iPhone

### Périphérique actif
Carte verte avec :
- 🟢 Cercle vert : Périphérique en ligne
- 🔴 Cercle rouge : Périphérique hors ligne
- Nom du périphérique depuis l'iPhone

## Gestion des erreurs

### iPhone déconnecté
**Symptôme** : Indicateur orange sur la Watch

**Causes possibles :**
- iPhone hors de portée Bluetooth
- Bluetooth désactivé sur l'iPhone
- WCSession non activée

**Solution :**
1. Vérifier que l'iPhone est à proximité
2. Vérifier le Bluetooth sur l'iPhone
3. Redémarrer l'app sur l'iPhone et la Watch

### Données non synchronisées
**Symptôme** : Watch affiche des données anciennes

**Causes possibles :**
- Apple Watch en veille lors de l'envoi
- Transfert en arrière-plan en attente

**Solution :**
1. Réveiller la Watch
2. Appuyer sur le bouton refresh
3. Les données s'actualiseront

### Échec de synchronisation
**Symptôme** : Erreur dans les logs

**Causes possibles :**
- Corruption de données
- Problème de décodage
- Session expirée

**Solution :**
1. Fermer complètement les deux apps
2. Relancer d'abord l'app iPhone
3. Puis lancer l'app Watch
4. La synchronisation devrait reprendre

## Persistance

### Sur l'iPhone
- Données sauvegardées dans UserDefaults
- PhoneConnectivityManager observe les changements
- Synchronisation automatique à chaque modification

### Sur la Watch
- Données reçues sauvegardées dans UserDefaults
- Permettent de conserver l'état entre les lancements
- Mise à jour automatique lors de la synchronisation

## Logs de débogage

### Sur l'iPhone
```
✅ WCSession activée sur iPhone
📱 Données envoyées à la Watch : X serveurs, Y périphériques
📱 Watch reachable: true/false
📱 Données de capteurs envoyées instantanément à la Watch
```

### Sur la Watch
```
✅ WCSession activée sur Apple Watch
⌚️ Demande de mise à jour envoyée à l'iPhone
⌚️ iPhone reachable: true/false
⌚️ Contexte d'application reçu de l'iPhone
⌚️ X serveurs synchronisés
⌚️ Y périphériques synchronisés
⌚️ Serveur actuel synchronisé : [nom]
⌚️ Périphérique sélectionné synchronisé : [nom]
⌚️ Données de capteurs synchronisées - Temp: XXX°C, pH: X.XX
```

## Test de la synchronisation

### Test 1 : Synchronisation initiale
1. Lancer l'app sur l'iPhone
2. Configurer serveurs et périphériques
3. Lancer l'app sur la Watch
4. **Résultat attendu** : Les serveurs et périphériques apparaissent sur la Watch

### Test 2 : Ajout de serveur
1. Sur l'iPhone, ajouter un nouveau serveur
2. Observer la Watch
3. **Résultat attendu** : Le nouveau serveur apparaît automatiquement

### Test 3 : Changement de périphérique
1. Sur l'iPhone, changer de périphérique actif
2. Observer la Watch
3. **Résultat attendu** : La Watch affiche le nouveau périphérique

### Test 4 : Données MQTT en temps réel
1. Sur l'iPhone, s'assurer d'être connecté à MQTT
2. Observer la Watch (réveillée)
3. Les données MQTT arrivent sur l'iPhone
4. **Résultat attendu** : Les valeurs se mettent à jour instantanément sur la Watch

### Test 5 : Refresh depuis la Watch
1. Sur la Watch, appuyer sur le bouton refresh
2. Observer les logs de l'iPhone
3. **Résultat attendu** : L'iPhone envoie les dernières données

### Test 6 : Mode arrière-plan
1. Laisser la Watch se mettre en veille
2. Sur l'iPhone, modifier une configuration
3. Réveiller la Watch
4. **Résultat attendu** : Les changements sont visibles

## Optimisations

### Économie de batterie
- Transfert arrière-plan quand la Watch est en veille
- Pas de synchronisation continue
- Mise à jour uniquement sur changement

### Efficacité réseau
- `updateApplicationContext` : remplace le contexte précédent (pas de queue)
- `sendMessage` : instantané pour données critiques
- `transferUserInfo` : en queue pour données moins urgentes

### Gestion mémoire
- Modèles légers sur watchOS (WatchMQTTServer, etc.)
- Pas de dépendances lourdes (CocoaMQTT uniquement sur iOS)
- Suppression des données de démo (économie de mémoire)

## Améliorations futures

### Version 1.2
- [ ] Synchronisation bidirectionnelle (Watch → iPhone)
- [ ] Changement de serveur/périphérique depuis la Watch
- [ ] Indicateur de transfert en cours
- [ ] Gestion des conflits de synchronisation

### Version 2.0
- [ ] Complications synchronisées
- [ ] Notifications watchOS depuis l'iPhone
- [ ] Historique synchronisé (dernières 100 mesures)
- [ ] Mode offline amélioré avec cache intelligent

## Résolution de problèmes avancés

### Réinitialiser complètement la synchronisation

#### Sur l'iPhone
```swift
// Dans PhoneConnectivityManager
WCSession.default.delegate = nil
WCSession.default.invalidate()
// Puis relancer l'app
```

#### Sur la Watch
```swift
// Supprimer toutes les données sauvegardées
UserDefaults.standard.removeObject(forKey: "watch_mqtt_servers")
UserDefaults.standard.removeObject(forKey: "watch_pool_devices")
// Puis relancer l'app
```

### Vérifier l'état de WCSession

Dans la console Xcode :
```
po WCSession.default.activationState
po WCSession.default.isReachable
po WCSession.default.isPaired
po WCSession.default.isWatchAppInstalled
```

## Support

Pour tout problème de synchronisation :
1. Consulter les logs dans Xcode (Window > Devices and Simulators > View Device Logs)
2. Vérifier que les deux apps sont à jour
3. Vérifier la version de watchOS (minimum 9.0)
4. Ouvrir une issue sur GitHub avec les logs

## Résumé

✅ Synchronisation complète implémentée
✅ Données de configuration (serveurs, périphériques)
✅ Données de capteurs en temps réel
✅ Mode instantané et arrière-plan
✅ Persistance sur les deux plateformes
✅ Indicateurs visuels d'état
✅ Gestion des erreurs
✅ Optimisé pour la batterie

La synchronisation iPhone ↔ Apple Watch est maintenant **complètement fonctionnelle** et prête à l'emploi !
