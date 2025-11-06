# Guide de test rapide - Synchronisation watchOS

## Vérification avant de tester

### 1. Vérifier que tous les fichiers sont ajoutés aux bonnes cibles dans Xcode

#### Fichiers iOS (cible: PoolSensors)
- [ ] `PoolSensors/Core/Services/PhoneConnectivityManager.swift`

#### Fichiers watchOS (cible: PoolSensorsWatchOS Watch App)
- [ ] `PoolSensorsWatchOS Watch App/Services/WatchConnectivityManager.swift`

### 2. Compiler les deux apps

```bash
# Dans Xcode :
1. Sélectionner schéma "PoolSensors" → Compiler (Cmd+B)
2. Sélectionner schéma "PoolSensorsWatchOS Watch App" → Compiler (Cmd+B)
```

## Scénario de test complet

### Test 1 : Première synchronisation (5 min)

**Objectif** : Vérifier que les données iOS sont automatiquement envoyées à la Watch

**Étapes :**
1. Lancer l'app **iOS** sur iPhone (simulateur ou réel)
2. Ajouter un serveur MQTT :
   - Nom : "Mon Serveur"
   - Host : "test.mosquitto.org"
   - Port : 1883
3. Ajouter un périphérique :
   - Nom : "Piscine Test"
   - Topic : "pool/test"
   - Serveur : "Mon Serveur"
4. Se connecter au serveur (appuyer sur la carte serveur)
5. Sélectionner le périphérique
6. Lancer l'app **watchOS** sur Apple Watch (simulateur ou réelle)

**Résultat attendu :**
```
✅ Sur la Watch, vous devriez voir :
   - Indicateur "🟢 Synchronisé" en haut
   - Carte bleue "Serveur" affichant "Mon Serveur"
   - Carte verte "Périphérique" affichant "Piscine Test"
```

**Logs attendus (Console Xcode) :**
```
iPhone:
✅ WCSession activée sur iPhone
📱 Données envoyées à la Watch : 1 serveurs, 1 périphériques

Watch:
✅ WCSession activée sur Apple Watch
⌚️ Demande de mise à jour envoyée à l'iPhone
⌚️ Contexte d'application reçu de l'iPhone
⌚️ 1 serveurs synchronisés
⌚️ 1 périphériques synchronisés
⌚️ Serveur actuel synchronisé : Mon Serveur
⌚️ Périphérique sélectionné synchronisé : Piscine Test
```

### Test 2 : Synchronisation dynamique (2 min)

**Objectif** : Vérifier que les changements sur iPhone sont automatiquement synchronisés

**Étapes :**
1. Garder la Watch visible (ne pas fermer l'app)
2. Sur **iPhone**, ajouter un deuxième serveur :
   - Nom : "Serveur Cloud"
   - Host : "mqtt.example.com"
   - Port : 1883
3. Observer la **Watch** (ne rien faire sur la Watch)

**Résultat attendu :**
```
✅ Sur la Watch, après quelques secondes :
   - Le nouveau serveur "Serveur Cloud" devrait apparaître
   - Pas besoin d'appuyer sur refresh
   - Synchronisation automatique
```

**Logs attendus :**
```
iPhone:
📱 Données envoyées à la Watch : 2 serveurs, 1 périphériques

Watch:
⌚️ Contexte d'application reçu de l'iPhone
⌚️ 2 serveurs synchronisés
```

### Test 3 : Changement de sélection (2 min)

**Objectif** : Vérifier la synchronisation des sélections

**Étapes :**
1. Sur **iPhone**, ajouter un deuxième périphérique :
   - Nom : "Spa"
   - Topic : "pool/spa"
   - Serveur : "Mon Serveur"
2. Sur **iPhone**, changer de périphérique (sélectionner "Spa")
3. Observer la **Watch**

**Résultat attendu :**
```
✅ Sur la Watch :
   - La carte périphérique affiche maintenant "Spa"
   - Changement automatique, pas de refresh nécessaire
```

### Test 4 : Données MQTT temps réel (3 min)

**Objectif** : Vérifier que les données des capteurs sont synchronisées

**Prérequis :** Avoir un serveur MQTT fonctionnel ou utiliser test.mosquitto.org

**Étapes :**
1. Sur **iPhone**, s'assurer d'être connecté à un serveur MQTT
2. Publier des données sur le topic (ex: `pool/test`) :
   ```json
   {
     "temperature": 25.5,
     "pH": 7.2,
     "chlorine": 1.5,
     "orp": 650
   }
   ```
3. Observer la **Watch** (doit être réveillée)

**Résultat attendu :**
```
✅ Sur la Watch, quasi-instantanément :
   - Les 4 cartes de capteurs affichent les nouvelles valeurs
   - Température : 25.5°C
   - pH : 7.20
   - Chlore : 1.50 mg/L
   - ORP : 650 mV
   - Horodatage mis à jour : "Mis à jour il y a 1 seconde"
```

**Logs attendus :**
```
iPhone:
📱 Watch reachable: true
📱 Données de capteurs envoyées instantanément à la Watch

Watch:
⌚️ Message instantané reçu de l'iPhone
⌚️ Données de capteurs synchronisées - Temp: 25.5°C, pH: 7.20
```

### Test 5 : Refresh manuel (1 min)

**Objectif** : Vérifier que le bouton refresh fonctionne

**Étapes :**
1. Sur la **Watch**, appuyer sur l'icône de refresh (en haut à droite)
2. Observer l'indicateur de chargement
3. Attendre 1-2 secondes

**Résultat attendu :**
```
✅ Sur la Watch :
   - Indicateur de chargement visible
   - Après 1-2 sec, chargement terminé
   - Données actualisées
   - Horodatage "Mis à jour il y a 1 seconde"
```

**Logs attendus :**
```
Watch:
⌚️ Demande de mise à jour envoyée à l'iPhone

iPhone:
📱 Watch demande une actualisation des données
📱 Données envoyées à la Watch : X serveurs, Y périphériques
📱 Données de capteurs envoyées instantanément à la Watch
```

### Test 6 : Mode arrière-plan (3 min)

**Objectif** : Vérifier le transfert en arrière-plan

**Étapes :**
1. Sur la **Watch**, laisser l'app ouverte puis appuyer sur la Digital Crown
2. Éteindre l'écran de la Watch (mettre en veille)
3. Sur **iPhone**, modifier quelque chose (ajouter un serveur ou changer de périphérique)
4. Attendre 10 secondes
5. Réveiller la **Watch** et rouvrir l'app

**Résultat attendu :**
```
✅ Sur la Watch, après réouverture :
   - Les changements sont visibles
   - Les données ont été transférées en arrière-plan
   - Pas de perte de données
```

**Logs attendus :**
```
iPhone:
📱 Watch reachable: false
📱 Données de capteurs transférées en arrière-plan à la Watch

Watch (au réveil):
⌚️ UserInfo reçu de l'iPhone (arrière-plan)
⌚️ Données de capteurs synchronisées
```

## Checklist de vérification

### Synchronisation automatique
- [ ] Les serveurs iOS apparaissent sur la Watch
- [ ] Les périphériques iOS apparaissent sur la Watch
- [ ] Le serveur actif est synchronisé
- [ ] Le périphérique sélectionné est synchronisé
- [ ] Les données MQTT sont synchronisées en temps réel

### Interface Watch
- [ ] Indicateur "Synchronisé" visible quand connecté
- [ ] Indicateur "iPhone déconnecté" visible si hors de portée
- [ ] Cartes de capteurs affichent les bonnes valeurs
- [ ] Horodatage se met à jour
- [ ] Bouton refresh fonctionne

### Performance
- [ ] Synchronisation rapide (< 2 secondes)
- [ ] Pas de lag dans l'interface
- [ ] Pas de crash ou freeze
- [ ] Consommation batterie normale

### Logs
- [ ] Logs iPhone affichent les envois
- [ ] Logs Watch affichent les réceptions
- [ ] Pas d'erreurs dans la console

## Problèmes courants

### "iPhone déconnecté" affiché
**Solution :**
1. Vérifier que les deux apps sont lancées
2. Vérifier le Bluetooth sur l'iPhone
3. Rapprocher les appareils
4. Relancer les deux apps

### Pas de synchronisation
**Solution :**
1. Clean Build Folder (Shift+Cmd+K) sur les deux cibles
2. Recompiler les deux apps
3. Fermer complètement les apps
4. Relancer d'abord iPhone, puis Watch

### Données anciennes sur la Watch
**Solution :**
1. Appuyer sur le bouton refresh de la Watch
2. Vérifier que l'iPhone est connecté à MQTT
3. Publier de nouvelles données MQTT

### Simulateur Watch ne se lance pas
**Solution :**
1. Xcode > Window > Devices and Simulators
2. Supprimer les simulateurs Watch problématiques
3. Créer un nouveau simulateur
4. Relancer

## Validation finale

Si tous les tests passent :
```
✅ Synchronisation iPhone ↔ Watch : FONCTIONNELLE
✅ Transfert instantané : FONCTIONNEL
✅ Transfert arrière-plan : FONCTIONNEL
✅ Refresh manuel : FONCTIONNEL
✅ Indicateurs visuels : FONCTIONNELS
✅ Logs de débogage : COMPLETS

🎉 L'implémentation est complète et opérationnelle !
```

## Commandes utiles

### Voir les logs en temps réel
```bash
# Dans Xcode :
Cmd+Shift+Y  # Ouvrir la console
# Filtrer par "📱" pour voir les logs iPhone
# Filtrer par "⌚️" pour voir les logs Watch
```

### Reset UserDefaults (si problèmes de données)
```swift
// Sur iPhone (dans PhoneConnectivityManager) :
UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)

// Sur Watch (dans WatchViewModel) :
UserDefaults.standard.removeObject(forKey: "watch_mqtt_servers")
UserDefaults.standard.removeObject(forKey: "watch_pool_devices")
```

## Support

En cas de problème :
1. Consulter `WATCH_SYNC_GUIDE.md` pour la documentation complète
2. Consulter `SYNC_IMPLEMENTATION_SUMMARY.md` pour l'architecture
3. Vérifier les logs de console
4. Ouvrir une issue sur GitHub avec les logs

Bonne synchronisation ! 🚀
