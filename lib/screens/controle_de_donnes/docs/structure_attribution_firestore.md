# Structure Firestore pour les Attributions

## Vue d'ensemble

Le système d'attribution des produits dans le module de contrôle utilise une structure Firestore organisée par type de receveur et site de destination.

## Structure Firestore

```
Collection principale: [TypeReceveur]
├── Extraction/                    # Collection pour les attributions d'extraction
│   ├── Koudougou/                 # Document pour le site Koudougou
│   │   ├── statistiques: {...}   # Statistiques du site
│   │   └── attributions/          # Sous-collection des attributions
│   │       ├── attr_1234567890    # Document d'attribution
│   │       ├── attr_1234567891    # Document d'attribution
│   │       └── ...
│   ├── Bobo-Dioulasso/           # Document pour le site Bobo-Dioulasso
│   │   ├── statistiques: {...}   
│   │   └── attributions/          
│   │       └── ...
│   └── ...
├── Filtrage/                      # Collection pour les attributions de filtrage
│   ├── Koudougou/
│   ├── Bobo-Dioulasso/
│   └── ...
└── Cire/                          # Collection pour les attributions de cire
    ├── Koudougou/
    ├── Banfora/
    └── ...
```

## Types de Collections Principales

### 1. **Extraction**
- **Sites disponibles :** Koudougou, Bobo-Dioulasso, Ouagadougou, Banfora
- **Nature des produits :** Bruts uniquement
- **Utilisé pour :** Traitement initial des produits de collecte

### 2. **Filtrage**
- **Sites disponibles :** Koudougou, Bobo-Dioulasso, Ouagadougou
- **Nature des produits :** Liquides/filtrés uniquement
- **Utilisé pour :** Purification et filtration

### 3. **Cire** (en développement)
- **Sites disponibles :** Koudougou, Banfora
- **Nature des produits :** Cire uniquement
- **Utilisé pour :** Transformation en produits de cire

## Structure d'un Document Site

```json
{
  "nomSite": "Koudougou",
  "typeReceveur": "Extraction",
  "statistiques": {
    "totalAttributions": 145,
    "totalContenants": 1250,
    "premiereAttribution": "2024-01-15T10:30:00Z",
    "derniereAttribution": "2024-12-01T14:20:00Z"
  },
  "dateCreation": "2024-01-15T10:30:00Z",
  "derniereMiseAJour": "2024-12-01T14:20:00Z",
  "actif": true
}
```

## Structure d'un Document Attribution

```json
{
  "id": "attr_1701234567890",
  "type": "extraction",
  "typeLabel": "Pour Extraction",
  "dateAttribution": "2024-12-01T14:20:00Z",
  "utilisateur": "Contrôleur Principal",
  "listeContenants": [
    "CNT001_KOUD_001",
    "CNT001_KOUD_002",
    "CNT001_KOUD_003"
  ],
  "statut": "attribueExtraction",
  "commentaires": "Attribution urgente pour traitement",
  "metadata": {
    "createdFromControl": true,
    "nombreContenants": 3,
    "originalPath": "/recoltes/2024/collecte_001",
    "totalWeight": 125.5,
    "totalAmount": 75000
  },
  "source": {
    "collecteId": "collecte_001",
    "type": "recoltes",
    "site": "Koudougou",
    "dateCollecte": "2024-11-30T09:15:00Z"
  },
  "natureProduitsAttribues": "brut",
  "siteDestination": "Koudougou",
  "dateCreation": "2024-12-01T14:20:00Z",
  "derniereMiseAJour": "2024-12-01T14:20:00Z",
  "statistiques": {
    "nombreContenants": 3,
    "poidsTotalEstime": 125.5,
    "montantTotalEstime": 75000
  }
}
```

## Flux d'Attribution

1. **Sélection du Type** : L'utilisateur choisit le type d'attribution (Extraction, Filtrage)
2. **Choix du Site Receveur** : Sélection du site qui recevra les produits
3. **Sélection des Contenants** : Choix des contenants à attribuer
4. **Validation** : Vérification de la cohérence type/nature des produits
5. **Sauvegarde Firestore** : 
   - Document dans `[TypeReceveur]/[SiteReceveur]/attributions/`
   - Mise à jour des statistiques du site
6. **Notification** : Confirmation de l'attribution

## Avantages de cette Structure

### 🏗️ **Organisation Logique**
- Collections séparées par type de traitement
- Sous-collections par site de destination
- Hiérarchie claire et intuitive

### 📊 **Statistiques Faciles**
- Compteurs automatiques par site
- Agrégation simple par type de traitement
- Historique complet des attributions

### 🔍 **Requêtes Optimisées**
- Index automatiques sur les collections
- Requêtes rapides par site ou type
- Pagination efficace

### 🔒 **Sécurité et Permissions**
- Permissions granulaires par collection
- Contrôle d'accès par site
- Audit trail complet

### 📈 **Évolutivité**
- Ajout facile de nouveaux sites
- Extension simple pour nouveaux types
- Structure extensible

## Exemples de Requêtes

### Récupérer toutes les attributions d'extraction pour Koudougou
```dart
FirebaseFirestore.instance
  .collection('Extraction')
  .doc('Koudougou')
  .collection('attributions')
  .orderBy('dateAttribution', descending: true)
  .get()
```

### Obtenir les statistiques d'un site
```dart
FirebaseFirestore.instance
  .collection('Extraction')
  .doc('Koudougou')
  .get()
```

### Écouter les nouvelles attributions en temps réel
```dart
FirebaseFirestore.instance
  .collection('Extraction')
  .doc('Koudougou')
  .collection('attributions')
  .snapshots()
```

## Codes d'Exemples

Voir les fichiers :
- `FirestoreAttributionService` : Service principal
- `ControlAttributionService` : Interface avec le module de contrôle
- `ControlAttributionModal` : Interface utilisateur

## Migration depuis l'Ancien Système

Le système précédent utilisait un stockage en mémoire uniquement. La migration implique :

1. **Pas de migration de données** nécessaire (données en mémoire uniquement)
2. **Formation des utilisateurs** sur la sélection du site receveur
3. **Configuration Firestore** avec les règles de sécurité appropriées
4. **Tests** des nouveaux flux d'attribution
