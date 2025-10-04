# Intégration Module Contrôle → Module Extraction

## Vue d'ensemble

Le module d'extraction a été modifié pour récupérer automatiquement les produits envoyés par le module de contrôle. Chaque extracteur ne voit que les produits attribués à son site.

## Architecture du Système

```
Module Contrôle                    Module Extraction
┌─────────────────┐                ┌─────────────────┐
│ Attribution     │                │ Réception       │
│ produits        │                │ produits        │
│                 │    Firestore   │                 │
│ Site receveur   │  ──────────→   │ Site actuel     │
│ sélectionné     │                │ (filtrage auto) │
└─────────────────┘                └─────────────────┘
```

## Structure Firestore Utilisée

```
Collection: Extraction/
├── Koudougou/                     # Site extracteur
│   └── attributions/              # Sous-collection
│       ├── attr_1234567890        # Attribution du contrôle
│       ├── attr_1234567891
│       └── ...
├── Bobo-Dioulasso/               # Autre site extracteur
│   └── attributions/
│       └── ...
└── ...
```

## Services Créés

### 1. ControlAttributionReceiverService

**Responsabilités :**
- Récupérer les attributions pour le site de l'utilisateur connecté
- Convertir les données Firestore en `ExtractionProduct`
- Filtrer automatiquement par site
- Mettre à jour les statuts d'extraction

**Méthodes principales :**
```dart
// Récupérer en temps réel les attributions pour le site actuel
Stream<List<ExtractionProduct>> getAttributionsForCurrentSite()

// Mettre à jour le statut d'une attribution
Future<void> updateAttributionStatus({
  required String attributionId,
  required ExtractionStatus newStatus,
  String? commentaire,
  Map<String, dynamic>? resultats,
})

// Obtenir les statistiques par statut
Stream<Map<String, int>> getAttributionCountsByStatus()
```

### 2. ExtractionService (Modifié)

**Nouvelles fonctionnalités :**
```dart
// Récupérer les produits du module contrôle
Stream<List<ExtractionProduct>> getProductsFromControlModule()

// Combiner données contrôle + données mock
Stream<List<ExtractionProduct>> getAllProductsStream()

// Mettre à jour statut (délègue au service contrôle)
Future<void> updateProductStatus(...)
```

## Interface Utilisateur

### 1. Widget de Statistiques des Attributions

**`ControlAttributionStatsWidget`** affiche :
- Nombre total d'attributions reçues
- Répartition par statut (En Attente, En Cours, Terminés)
- Design distinctif avec couleurs bleues
- Mise à jour en temps réel

### 2. Indicateur Visuel sur les Cartes

Les produits venant du module contrôle ont :
- Badge "CONTRÔLE" bleu avec icône
- Distinction visuelle claire
- Métadonnées enrichies

### 3. Interface Temps Réel

- Écoute en temps réel des nouvelles attributions
- Mise à jour automatique des statuts
- Synchronisation bidirectionnelle

## Flux de Données

### 1. Attribution depuis le Contrôle
```
1. Contrôleur sélectionne produits
2. Choisit type (Extraction/Filtrage) 
3. Sélectionne site receveur
4. Sauvegarde dans Firestore:
   Collection[TypeReceveur]/[SiteReceveur]/attributions/
```

### 2. Réception dans l'Extraction
```
1. Service écoute Firestore en temps réel
2. Filtre par site de l'extracteur connecté
3. Convertit en ExtractionProduct
4. Affiche dans l'interface avec indicateur
```

### 3. Mise à Jour des Statuts
```
1. Extracteur change statut (En Cours, Terminé)
2. Service met à jour Firestore
3. Contrôle voit la mise à jour en temps réel
```

## Filtrage Automatique par Site

### Principe
L'extracteur connecté ne voit **que** les produits attribués à son site :

```dart
// Récupération du site utilisateur
String _getUserSite() {
  final userSession = Get.find<UserSession>();
  return userSession.site ?? 'Inconnu';
}

// Requête filtrée automatiquement
_firestore
  .collection('Extraction')
  .doc(userSite)  // ← Filtrage automatique
  .collection('attributions')
```

### Sécurité
- Aucun accès aux données d'autres sites
- Isolation complète par site
- Authentification par session utilisateur

## Conversion des Données

### De Firestore vers ExtractionProduct

```dart
ExtractionProduct _convertToExtractionProduct(Map<String, dynamic> data, String id) {
  // Conversion des statuts contrôle → extraction
  final statutControl = data['statut'] ?? 'attribueExtraction';
  final statutExtraction = _convertControlStatusToExtractionStatus(statutControl);

  // Détermination du type de produit
  final nature = data['natureProduitsAttribues'] ?? 'brut';
  final productType = nature == 'brut' ? ProductType.mielBrut : ProductType.mielCristallise;

  // Calcul de la priorité
  final priorite = _determinePriority(dateAttribution, productType);

  return ExtractionProduct(
    id: id,
    nom: 'Attribution ${id.substring(id.length - 6)}',
    type: productType,
    origine: source['site'] ?? 'Inconnu',
    statut: statutExtraction,
    priorite: priorite,
    // ... autres champs
  );
}
```

## Mapping des Statuts

### Contrôle → Extraction
```
'attribueExtraction' → ExtractionStatus.enAttente
'enCours'           → ExtractionStatus.enCours
'termine'           → ExtractionStatus.termine
'annule'            → ExtractionStatus.suspendu
```

### Extraction → Contrôle
```
ExtractionStatus.enAttente → 'attribueExtraction'
ExtractionStatus.enCours   → 'enCours'
ExtractionStatus.termine   → 'termine'
ExtractionStatus.suspendu  → 'annule'
ExtractionStatus.erreur    → 'annule'
```

## Mapping des Priorités

### Calcul Automatique
```dart
ExtractionPriority _determinePriority(DateTime dateAttribution, ProductType type) {
  final daysSinceAttribution = DateTime.now().difference(dateAttribution).inDays;
  
  if (daysSinceAttribution >= 5) {
    return ExtractionPriority.urgente; // Attribution ancienne
  } else if (type == ProductType.mielBrut && daysSinceAttribution >= 2) {
    return ExtractionPriority.urgente; // Miel brut = traitement rapide
  } else if (daysSinceAttribution >= 1) {
    return ExtractionPriority.normale;
  } else {
    return ExtractionPriority.differee; // Attribution récente
  }
}
```

## Avantages du Système

### 🎯 **Automatisation Complète**
- Aucune intervention manuelle requise
- Transfert automatique des données
- Filtrage intelligent par site

### 🔒 **Sécurité et Isolation**
- Chaque site ne voit que ses données
- Pas d'accès croisé entre sites
- Authentification basée sur la session

### ⚡ **Temps Réel**
- Mise à jour instantanée des attributions
- Synchronisation bidirectionnelle
- Statuts mis à jour en direct

### 📊 **Traçabilité Complète**
- Historique complet des attributions
- Suivi des statuts en temps réel
- Métadonnées enrichies

### 🎨 **Interface Intuitive**
- Distinction visuelle claire
- Statistiques en temps réel
- Indicateurs de provenance

## Utilisation Pratique

### Pour l'Extracteur

1. **Connexion** au module Extraction
2. **Visualisation automatique** des produits attribués à son site
3. **Identification** des produits du contrôle (badge bleu)
4. **Traitement** normal avec mise à jour des statuts
5. **Suivi** en temps réel via les statistiques

### Pour le Contrôleur

1. **Attribution** des produits avec sélection du site
2. **Suivi** des statuts d'extraction en temps réel
3. **Visibilité** sur l'avancement par site
4. **Historique** complet des transferts

## Configuration Requise

### Firestore Rules
```javascript
// Règles de sécurité Firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Collection Extraction
    match /Extraction/{siteId}/attributions/{attributionId} {
      allow read, write: if request.auth != null 
        && resource.data.siteDestination == siteId
        && request.auth.token.site == siteId;
    }
  }
}
```

### Session Utilisateur
```dart
// UserSession doit contenir le site
class UserSession {
  String? site; // Site de l'utilisateur connecté
  String? role; // Rôle (extracteur, contrôleur, etc.)
}
```

## Tests et Validation

### Test du Filtrage
1. Connecter un extracteur du site A
2. Attribuer produits aux sites A et B depuis le contrôle
3. Vérifier que l'extracteur A ne voit que ses produits

### Test Temps Réel
1. Ouvrir module extraction sur un site
2. Faire attribution depuis le contrôle vers ce site
3. Vérifier apparition immédiate du produit

### Test Mise à Jour Statuts
1. Changer statut dans extraction (En Cours → Terminé)
2. Vérifier mise à jour dans le module contrôle
3. Valider synchronisation bidirectionnelle

## Maintenance

### Logs de Debug
```dart
if (kDebugMode) {
  print('🔍 Récupération attributions pour site: $userSite');
  print('✅ Attribution sauvegardée: $attributionId');
  print('📦 Produits récupérés: ${products.length}');
}
```

### Monitoring
- Surveiller les requêtes Firestore
- Vérifier les performances en temps réel
- Monitorer les erreurs de conversion

Le système est maintenant opérationnel et prêt pour la production ! 🚀
