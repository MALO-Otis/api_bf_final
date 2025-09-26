# Structure Firestore - Contrôles Qualité

## Vue d'ensemble

Les données de contrôle qualité sont maintenant sauvegardées dans Firestore avec une organisation par site pour assurer l'isolation des données.

## Structure Firestore

```
Collection: controles_qualite/
├── Koudougou/                     # Site utilisateur
│   └── controles/                 # Sous-collection des contrôles
│       ├── CT-001_1703847600000   # ID unique : CodeContenant_timestamp
│       ├── CT-002_1703851200000
│       └── ...
├── Bobo-Dioulasso/               # Autre site
│   └── controles/
│       └── ...
└── ...
```

## Document de Contrôle Qualité

### Structure des Données

```json
{
  "id": "CT-001_1703847600000",
  "containerCode": "CT-001",
  "receptionDate": "2023-12-29T10:00:00Z",
  "producer": "Jean Dupont",
  "apiaryVillage": "Sakoinsé",
  "hiveType": "Langstroth",
  "collectionStartDate": "2023-12-20T00:00:00Z",
  "collectionEndDate": "2023-12-28T00:00:00Z",
  "honeyNature": "brut",
  "containerType": "Bidon 25L",
  "containerNumber": "001",
  "totalWeight": 25.5,
  "honeyWeight": 24.0,
  "quality": "Excellent",
  "waterContent": 18.5,
  "floralPredominance": "Karité",
  "conformityStatus": "conforme",
  "nonConformityCause": null,
  "observations": "Miel de très bonne qualité",
  "controllerName": "Marie Ouédraogo",
  "createdAt": "2023-12-29T10:30:00Z",
  "site": "Koudougou",
  "dateCreation": "2023-12-29T10:30:00Z",
  "derniereMiseAJour": "2023-12-29T10:30:00Z"
}
```

### Champs Obligatoires

- **id** : Identifiant unique généré automatiquement
- **containerCode** : Code du contenant contrôlé
- **receptionDate** : Date de réception du contenant
- **producer** : Nom du producteur
- **apiaryVillage** : Village du rucher
- **totalWeight** : Poids total du contenant
- **honeyWeight** : Poids du miel
- **conformityStatus** : Statut de conformité (conforme/nonConforme)
- **controllerName** : Nom du contrôleur
- **site** : Site de l'utilisateur (filtrage automatique)

### Champs Optionnels

- **hiveType** : Type de ruche
- **collectionStartDate/EndDate** : Période de collecte
- **quality** : Évaluation qualitative
- **waterContent** : Taux d'humidité
- **floralPredominance** : Prédominance florale
- **nonConformityCause** : Cause de non-conformité (si applicable)
- **observations** : Observations du contrôleur

## Services Implémentés

### QualityControlService

#### Nouvelles Fonctionnalités Firestore

```dart
// Sauvegarde en Firestore avec isolation par site
Future<bool> saveQualityControl(QualityControlData data)

// Récupération avec cache local
Future<QualityControlData?> getQualityControl(String containerCode, DateTime receptionDate)

// Récupération de tous les contrôles depuis Firestore
Future<List<QualityControlData>> getAllQualityControlsFromFirestore()
```

#### Organisation des Données

1. **Collection principale** : `controles_qualite`
2. **Document par site** : `{siteUtilisateur}`
3. **Sous-collection** : `controles`
4. **Document contrôle** : `{containerCode}_{timestamp}`

#### Gestion du Cache

- **Cache local** : `_qualityControlsCache` pour performance
- **Synchronisation** : Cache mis à jour lors des opérations Firestore
- **Compatibilité** : Méthodes existantes utilisent le cache

## Avantages de la Nouvelle Architecture

### 🔒 **Isolation par Site**
- Chaque site ne voit que ses propres contrôles
- Sécurité renforcée des données
- Performance optimisée (requêtes filtrées)

### 💾 **Persistance Réelle**
- Données sauvegardées en base réelle
- Pas de perte lors du redémarrage
- Synchronisation multi-utilisateurs

### ⚡ **Performance**
- Cache local pour accès rapide
- Requêtes indexées par date
- Pagination possible pour gros volumes

### 🔄 **Évolutivité**
- Structure extensible
- Support des requêtes complexes
- Statistiques en temps réel

## Migration et Compatibilité

### Compatibilité Ascendante

Les méthodes existantes continuent de fonctionner :
```dart
// Toujours disponible (utilise le cache)
List<QualityControlData> getQualityControlsByDateRange(DateTime start, DateTime end)
QualityStats getQualityStats({DateTime? startDate, DateTime? endDate})
```

### Nouvelles Fonctionnalités

```dart
// Nouvelles méthodes asynchrones Firestore
Future<List<QualityControlData>> getAllQualityControlsFromFirestore()
Future<QualityControlData?> getQualityControl(String containerCode, DateTime receptionDate)
```

## Utilisation dans l'Interface

### Formulaire de Contrôle

Le formulaire existant fonctionne sans modification :
1. **Saisie** des données de contrôle
2. **Validation** des champs obligatoires
3. **Sauvegarde automatique** en Firestore
4. **Message de confirmation** avec détails

### Récupération des Données

```dart
// Dans le formulaire ou widgets
final service = QualityControlService();

// Sauvegarder (maintenant en Firestore)
await service.saveQualityControl(qualityData);

// Récupérer (maintenant depuis Firestore)
final control = await service.getQualityControl(containerCode, receptionDate);
```

## Règles de Sécurité Firestore

```javascript
// Proposition de règles Firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Collection contrôles qualité
    match /controles_qualite/{siteId}/controles/{controleId} {
      allow read, write: if request.auth != null 
        && request.auth.token.site == siteId;
    }
  }
}
```

## Monitoring et Debug

### Logs de Debug

```dart
if (kDebugMode) {
  print('✅ Contrôle qualité sauvegardé en Firestore: controles_qualite/$siteUtilisateur/controles/$docId');
  print('📊 Contenant: ${data.containerCode}');
  print('👤 Contrôleur: ${data.controllerName}');
  print('✅ Conformité: ${data.conformityStatus.label}');
}
```

### Points de Surveillance

- **Taille des documents** : Vérifier que les observations ne sont pas trop longues
- **Fréquence des requêtes** : Optimiser avec le cache
- **Erreurs de conversion** : Types de données Firestore → Dart

## Tests de Validation

### Test de Sauvegarde

1. **Remplir** le formulaire de contrôle
2. **Valider** les données
3. **Cliquer** "Enregistrer le contrôle"
4. **Vérifier** le message "Contrôle enregistré avec succès"
5. **Contrôler** dans la console Firestore

### Test de Récupération

1. **Sauvegarder** un contrôle
2. **Fermer/Rouvrir** l'application
3. **Rechercher** le contrôle par code contenant
4. **Vérifier** que toutes les données sont présentes

### Test d'Isolation

1. **Connecter** un utilisateur site A
2. **Sauvegarder** un contrôle
3. **Connecter** un utilisateur site B
4. **Vérifier** qu'il ne voit pas le contrôle du site A

## Prochaines Étapes

- [ ] Interface de consultation des contrôles
- [ ] Statistiques en temps réel depuis Firestore
- [ ] Export PDF des contrôles qualité
- [ ] Notifications de non-conformité
- [ ] Dashboard qualité par site

Le système de contrôle qualité est maintenant connecté à Firestore et sauvegarde réellement les données ! 🎉✅
