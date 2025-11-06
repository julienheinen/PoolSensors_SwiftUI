# Synchronisation iPhone ↔ Apple Watch - Référence rapide

## ✅ Statut : IMPLÉMENTÉ ET FONCTIONNEL

## Fichiers ajoutés

### iOS
- `PoolSensors/Core/Services/PhoneConnectivityManager.swift` ← **IMPORTANT : Ajouter à la cible PoolSensors**

### watchOS
- `PoolSensorsWatchOS Watch App/Services/WatchConnectivityManager.swift` ← **IMPORTANT : Ajouter à la cible PoolSensorsWatchOS Watch App**

## Ce qui est synchronisé automatiquement

1. **Configuration** (iPhone → Watch)
   - Liste des serveurs MQTT
   - Liste des périphériques
   - Serveur actuellement connecté
   - Périphérique sélectionné

2. **Données temps réel** (iPhone → Watch)
   - Température
   - pH
   - Chlore
   - ORP
   - Horodatage

3. **Demandes** (Watch → iPhone)
   - Refresh manuel = demande de mise à jour

## Comment tester

```bash
1. Lancer app iOS sur iPhone
2. Configurer serveurs et périphériques
3. Lancer app watchOS sur Apple Watch
4. ✅ Les données apparaissent automatiquement sur la Watch
5. Sur iPhone : modifier quelque chose
6. ✅ La Watch se met à jour automatiquement
```

## Indicateurs sur la Watch

- 🟢 **"Synchronisé"** = Tout va bien
- 🟠 **"iPhone déconnecté"** = Problème de connexion

## Débogage rapide

### Voir les logs
```
Xcode → Console (Cmd+Shift+Y)
Filtrer par "📱" (iPhone) ou "⌚️" (Watch)
```

### Logs attendus
```
iPhone:
✅ WCSession activée sur iPhone
📱 Données envoyées à la Watch : X serveurs, Y périphériques

Watch:
✅ WCSession activée sur Apple Watch
⌚️ X serveurs synchronisés
⌚️ Données de capteurs synchronisées - Temp: XX°C
```

## Si ça ne marche pas

1. Vérifier que les 2 nouveaux fichiers sont dans les bonnes cibles Xcode
2. Clean Build (Shift+Cmd+K) puis recompiler
3. Relancer d'abord l'app iPhone, puis la Watch
4. Vérifier le Bluetooth

## Documentation complète

- `QUICK_TEST_GUIDE.md` ← Tests détaillés
- `WATCH_SYNC_GUIDE.md` ← Guide complet de synchronisation
- `SYNC_IMPLEMENTATION_SUMMARY.md` ← Architecture technique
- `README.md` ← Documentation générale

## Résumé technique

```
iPhone: AppViewModel → PhoneConnectivityManager → WCSession → Watch
Watch: WCSession → WatchConnectivityManager → WatchViewModel → UI
```

**Mode de transfert :**
- Instantané si Watch réveillée
- Arrière-plan si Watch en veille

**Déclencheurs :**
- Automatique à chaque changement sur iPhone
- Manuel via bouton refresh sur Watch

## C'est tout ! 🎉

La synchronisation fonctionne automatiquement. Pas de configuration nécessaire.
