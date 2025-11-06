# Guide de configuration des cibles Xcode - watchOS

## Problème actuel

Les fichiers Swift ne sont pas reconnus car ils ne sont pas ajoutés à la bonne cible dans Xcode.

## Solution : Ajouter les fichiers à la cible watchOS

### Méthode 1 : Via l'inspecteur de fichier (Recommandé)

Pour **CHAQUE** fichier Swift du dossier watchOS :

1. Dans Xcode, sélectionner le fichier dans le navigateur de projet (à gauche)
2. Ouvrir l'inspecteur de fichier (icône document en haut à droite, ou Cmd+Option+1)
3. Dans la section **Target Membership**, cocher **PoolSensorsWatchOS Watch App**

#### Fichiers à vérifier :

**Modèles** (dossier Models/)
- [ ] `SharedModels.swift` → Cible: PoolSensorsWatchOS Watch App

**ViewModels** (dossier ViewModels/)
- [ ] `WatchViewModel.swift` → Cible: PoolSensorsWatchOS Watch App

**Services** (dossier Services/)
- [ ] `WatchConnectivityManager.swift` → Cible: PoolSensorsWatchOS Watch App

**Vues** (dossier Views/)
- [ ] `DashboardView.swift` → Cible: PoolSensorsWatchOS Watch App
- [ ] `ServerPickerView.swift` → Cible: PoolSensorsWatchOS Watch App
- [ ] `DevicePickerView.swift` → Cible: PoolSensorsWatchOS Watch App

**Composants** (dossier Views/Components/)
- [ ] `WatchSensorCard.swift` → Cible: PoolSensorsWatchOS Watch App

**App**
- [ ] `ContentView.swift` → Cible: PoolSensorsWatchOS Watch App (déjà fait normalement)
- [ ] `PoolSensorsWatchOSApp.swift` → Cible: PoolSensorsWatchOS Watch App (déjà fait normalement)

### Méthode 2 : Vérification rapide de tous les fichiers

1. Dans Xcode, cliquer sur le projet (en haut du navigateur)
2. Sélectionner la cible **PoolSensorsWatchOS Watch App**
3. Aller dans l'onglet **Build Phases**
4. Ouvrir **Compile Sources**
5. Vérifier que tous les fichiers .swift du dossier watchOS sont listés :
   ```
   SharedModels.swift
   WatchViewModel.swift
   WatchConnectivityManager.swift
   DashboardView.swift
   ServerPickerView.swift
   DevicePickerView.swift
   WatchSensorCard.swift
   ContentView.swift
   PoolSensorsWatchOSApp.swift
   ```

6. S'il manque des fichiers, cliquer sur **+** et les ajouter

### Méthode 3 : Réimporter les fichiers (Si les méthodes 1 et 2 ne marchent pas)

Si les fichiers n'apparaissent toujours pas :

1. Dans le Finder, localiser le dossier `PoolSensorsWatchOS Watch App`
2. Dans Xcode, faire un clic droit sur le groupe "PoolSensorsWatchOS Watch App"
3. Choisir **Add Files to "PoolSensors"...**
4. Sélectionner les fichiers manquants
5. **IMPORTANT** : Cocher **"Copy items if needed"** si demandé
6. **IMPORTANT** : Cocher la cible **PoolSensorsWatchOS Watch App**
7. Cliquer sur **Add**

## Vérification de la configuration iOS

Pour l'app iOS, vérifier que **PhoneConnectivityManager.swift** est ajouté à la cible :

- [ ] `PhoneConnectivityManager.swift` → Cible: PoolSensors

## Après avoir ajouté les fichiers

1. **Clean Build Folder** : Product > Clean Build Folder (Shift+Cmd+K)
2. **Fermer Xcode complètement**
3. **Rouvrir Xcode**
4. **Recompiler** :
   - Schéma PoolSensors → Cmd+B
   - Schéma PoolSensorsWatchOS Watch App → Cmd+B

## Structure attendue dans Xcode

```
PoolSensors (projet)
├── PoolSensors (groupe iOS)
│   ├── Core/
│   │   └── Services/
│   │       └── PhoneConnectivityManager.swift ✓ Cible: PoolSensors
│   └── ...
│
└── PoolSensorsWatchOS Watch App (groupe watchOS)
    ├── Models/
    │   └── SharedModels.swift ✓ Cible: PoolSensorsWatchOS Watch App
    ├── ViewModels/
    │   └── WatchViewModel.swift ✓ Cible: PoolSensorsWatchOS Watch App
    ├── Services/
    │   └── WatchConnectivityManager.swift ✓ Cible: PoolSensorsWatchOS Watch App
    ├── Views/
    │   ├── DashboardView.swift ✓ Cible: PoolSensorsWatchOS Watch App
    │   ├── ServerPickerView.swift ✓ Cible: PoolSensorsWatchOS Watch App
    │   ├── DevicePickerView.swift ✓ Cible: PoolSensorsWatchOS Watch App
    │   └── Components/
    │       └── WatchSensorCard.swift ✓ Cible: PoolSensorsWatchOS Watch App
    ├── ContentView.swift ✓ Cible: PoolSensorsWatchOS Watch App
    └── PoolSensorsWatchOSApp.swift ✓ Cible: PoolSensorsWatchOS Watch App
```

## Commandes de vérification

### Vérifier que les fichiers existent physiquement

```bash
cd /Users/julienheinen/Documents/PoolSensors_SwiftUI/PoolSensorsWatchOS\ Watch\ App

# Lister tous les fichiers Swift
find . -name "*.swift" -type f
```

Résultat attendu :
```
./Models/SharedModels.swift
./ViewModels/WatchViewModel.swift
./Services/WatchConnectivityManager.swift
./Views/DashboardView.swift
./Views/ServerPickerView.swift
./Views/DevicePickerView.swift
./Views/Components/WatchSensorCard.swift
./ContentView.swift
./PoolSensorsWatchOSApp.swift
```

## Erreurs courantes

### "Cannot find 'X' in scope"
**Cause** : Le fichier n'est pas ajouté à la cible
**Solution** : Vérifier Target Membership dans l'inspecteur

### "No such module 'X'"
**Cause** : Import manquant ou framework non lié
**Solution** : Vérifier les imports en haut du fichier

### "Duplicate symbol"
**Cause** : Fichier ajouté à plusieurs cibles
**Solution** : Décocher les cibles non nécessaires

## Checklist finale

Avant de compiler :

- [ ] Tous les fichiers watchOS ont la cible "PoolSensorsWatchOS Watch App" cochée
- [ ] PhoneConnectivityManager.swift a la cible "PoolSensors" cochée
- [ ] Clean Build Folder effectué
- [ ] Xcode redémarré
- [ ] Les deux schémas compilent sans erreur

## Support visuel

Pour vérifier visuellement la Target Membership :

1. Sélectionner un fichier
2. Cmd+Option+1 pour ouvrir l'inspecteur
3. Chercher "Target Membership" dans la section du haut
4. Cocher la bonne cible

## Si rien ne fonctionne

Dernier recours - Recréer les groupes :

1. Dans Xcode, supprimer tous les groupes watchOS (clic droit > Delete > Remove Reference SEULEMENT)
2. Dans le Finder, vérifier que les fichiers existent toujours
3. Dans Xcode, clic droit sur le projet > Add Files to "PoolSensors"
4. Sélectionner tout le dossier "PoolSensorsWatchOS Watch App"
5. Cocher "Create groups"
6. Cocher la cible "PoolSensorsWatchOS Watch App"
7. Ajouter

Bonne configuration ! 🛠️
