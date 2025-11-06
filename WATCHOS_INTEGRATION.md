# Guide d'intégration de l'application watchOS

## Fichiers créés

L'application watchOS complète a été créée avec la structure suivante :

```
PoolSensorsWatchOS Watch App/
├── ContentView.swift                    ✅ Modifié - Point d'entrée principal
├── PoolSensorsWatchOSApp.swift         ✅ Existant - Configuration app
├── README.md                            ✅ Nouveau - Documentation watchOS
├── Models/
│   └── SharedModels.swift               ✅ Nouveau - Modèles de données
├── ViewModels/
│   └── WatchViewModel.swift             ✅ Nouveau - Logique métier
└── Views/
    ├── DashboardView.swift              ✅ Nouveau - Vue principale
    ├── ServerPickerView.swift           ✅ Nouveau - Sélection serveur
    ├── DevicePickerView.swift           ✅ Nouveau - Sélection périphérique
    └── Components/
        └── WatchSensorCard.swift        ✅ Nouveau - Composant carte
```

## Étapes d'intégration dans Xcode

### 1. Vérifier que tous les fichiers sont dans la cible watchOS

1. Ouvrir le projet dans Xcode
2. Dans le navigateur de projet, sélectionner chaque fichier .swift
3. Dans l'inspecteur de fichier (à droite), vérifier que "Target Membership" inclut **PoolSensorsWatchOS Watch App**

Fichiers à vérifier :
- [ ] Models/SharedModels.swift
- [ ] ViewModels/WatchViewModel.swift
- [ ] Views/DashboardView.swift
- [ ] Views/ServerPickerView.swift
- [ ] Views/DevicePickerView.swift
- [ ] Views/Components/WatchSensorCard.swift
- [ ] ContentView.swift (modifié)

### 2. Compiler l'application watchOS

1. Dans Xcode, sélectionner le schéma **PoolSensorsWatchOS Watch App**
2. Choisir une destination :
   - Simulateur : "Apple Watch Series 9 (45mm)"
   - Appareil physique : Votre Apple Watch connectée
3. Appuyer sur Cmd+B pour compiler
4. Résoudre les éventuelles erreurs de compilation

### 3. Exécuter sur le simulateur

1. Produit > Destination > Apple Watch Series 9 (45mm)
2. Appuyer sur Cmd+R pour exécuter
3. Le simulateur Apple Watch devrait se lancer
4. L'application devrait afficher le dashboard avec les données de démo

### 4. Exécuter sur un appareil physique

**Prérequis :**
- iPhone couplé avec une Apple Watch
- iPhone et Apple Watch connectés au Mac
- Certificats de développement configurés

**Étapes :**
1. Connecter l'iPhone au Mac via USB
2. Déverrouiller l'iPhone et l'Apple Watch
3. Dans Xcode, sélectionner votre Apple Watch comme destination
4. Appuyer sur Cmd+R
5. Autoriser l'installation sur l'appareil si demandé

## Fonctionnalités à tester

### Test 1 : Navigation de base
- [ ] L'app se lance sans crash
- [ ] Le dashboard s'affiche avec les données de démo
- [ ] La carte serveur affiche "Serveur Local"
- [ ] La carte périphérique affiche "Piscine principale"
- [ ] Les 4 cartes de capteurs sont visibles (Température, pH, Chlore, ORP)

### Test 2 : Sélection de serveur
- [ ] Appuyer sur la carte bleue "Serveur"
- [ ] La liste affiche 2 serveurs (Local et Cloud)
- [ ] Le serveur actuel a une coche
- [ ] Sélectionner l'autre serveur
- [ ] Retour au dashboard avec le nouveau serveur

### Test 3 : Sélection de périphérique
- [ ] Appuyer sur la carte verte "Périphérique"
- [ ] La liste affiche les périphériques du serveur actif
- [ ] Le périphérique actuel a une coche
- [ ] Sélectionner un autre périphérique
- [ ] Retour au dashboard avec le nouveau périphérique

### Test 4 : Actualisation
- [ ] Appuyer sur l'icône de rafraîchissement (en haut à droite)
- [ ] Un indicateur de chargement apparaît
- [ ] Les valeurs se mettent à jour (simulées aléatoirement)
- [ ] L'horodatage est mis à jour

### Test 5 : Persistance
- [ ] Sélectionner un serveur et un périphérique spécifiques
- [ ] Fermer complètement l'application (swiper vers le haut)
- [ ] Relancer l'application
- [ ] Vérifier que la sélection est conservée

### Test 6 : Scroll et navigation
- [ ] Utiliser la Digital Crown pour scroller
- [ ] Le scroll est fluide
- [ ] Toutes les cartes sont accessibles
- [ ] Swiper vers la gauche pour revenir en arrière

## Problèmes courants et solutions

### Erreur : "No such module 'SwiftUI'"
**Solution :** Vérifier que le Deployment Target de la cible watchOS est >= watchOS 9.0

### Erreur : Fichiers non trouvés
**Solution :** Vérifier que tous les fichiers sont bien dans le groupe "PoolSensorsWatchOS Watch App" et ont la bonne Target Membership

### Simulateur qui ne démarre pas
**Solution :** 
1. Xcode > Preferences > Platforms
2. Télécharger les Simulators watchOS si manquants
3. Redémarrer Xcode

### L'app ne s'installe pas sur l'Apple Watch physique
**Solution :**
1. Vérifier que l'iPhone et l'Apple Watch sont connectés
2. Sur l'iPhone : Réglages > Général > VPN et gestion des périphériques
3. Faire confiance au certificat de développement
4. Réessayer l'installation

### Compilation lente
**Solution :**
1. Xcode > Product > Clean Build Folder (Shift+Cmd+K)
2. Fermer et rouvrir Xcode
3. Recompiler le projet

## Prochaines étapes

### Développement futur (Version 1.1)

Pour implémenter la synchronisation avec l'iPhone :

1. **Ajouter WatchConnectivity aux deux cibles**
   - iOS : Créer `PhoneConnectivityManager.swift`
   - watchOS : Créer `WatchConnectivityManager.swift`

2. **Configurer la session dans l'app iOS**
   ```swift
   WCSession.default.delegate = PhoneConnectivityManager.shared
   WCSession.default.activate()
   ```

3. **Envoyer les données depuis l'iPhone**
   ```swift
   func sendDataToWatch() {
       let data = // Encoder PoolSensorData
       try? WCSession.default.updateApplicationContext(["sensorData": data])
   }
   ```

4. **Recevoir les données sur la Watch**
   ```swift
   func session(_ session: WCSession, didReceiveApplicationContext context: [String : Any]) {
       // Décoder et mettre à jour le ViewModel
   }
   ```

### Documentation complémentaire

- README principal du projet : `/README.md`
- README watchOS : `/PoolSensorsWatchOS Watch App/README.md`
- Documentation Apple WatchConnectivity : https://developer.apple.com/documentation/watchconnectivity

## Support

Pour toute question ou problème :
1. Vérifier les logs de console dans Xcode (Cmd+Shift+Y)
2. Consulter le README watchOS
3. Ouvrir une issue sur GitHub

## Résumé

✅ Application watchOS complète créée
✅ Dashboard avec affichage des 4 paramètres
✅ Sélection serveur et périphérique
✅ Données de démonstration fonctionnelles
✅ Interface optimisée pour Apple Watch
✅ Persistance locale avec UserDefaults
✅ Documentation complète

L'application est prête à être testée et peut être utilisée immédiatement avec les données de démonstration. La synchronisation avec l'iPhone sera implémentée dans la version 1.1 via WatchConnectivity.
