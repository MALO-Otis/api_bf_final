# Système d'Enregistrement des Récoltes - Documentation Technique

## Vue d'ensemble

Ce système d'enregistrement des récoltes a été conçu en suivant le même pattern de sécurité et d'organisation que le système de collecte individuelle, mais adapté pour le contexte des récoltes de miel.

## Structure Firestore

### Architecture de données
```
Sites/
  └── {nomSite}/
      └── nos_recoltes/
          ├── recolte_{timestamp}_{site}/          # Documents de récolte individuels
          └── _statistiques_structurees            # Document de statistiques globales
```

### Exemple concret
```
Sites/
  └── Koudougou/
      └── nos_recoltes/
          ├── recolte_1704654321000_koudougou
          ├── recolte_1704654421000_koudougou
          └── _statistiques_structurees
```

## Flux de traitement

### 1. Validation des données
- ✅ Vérification des contenants (min. 1)
- ✅ Validation du site sélectionné
- ✅ Validation du technicien assigné
- ✅ Contrôle de cohérence des calculs (poids/montant)

### 2. Génération d'ID sécurisé
```dart
final String idRecolte = 'recolte_${now.millisecondsSinceEpoch}_${selectedSite!.replaceAll(' ', '_').toLowerCase()}';
```

### 3. Vérification d'unicité
- ✅ Contrôle anti-collision d'ID
- ✅ Double vérification avant écriture

### 4. Enregistrement sécurisé
- ✅ Écriture uniquement dans `Sites/{nomSite}/nos_recoltes/`
- ✅ Aucune modification d'autres collections
- ✅ Traçabilité complète avec métadonnées

## Structure des données de récolte

### Document principal (récolte)
```json
{
  "id": "recolte_1704654321000_koudougou",
  "site": "Koudougou",
  "region": "Centre-Ouest",
  "province": "Boulkiemdé",
  "commune": "Koudougou",
  "village": "Koudougou",
  "technicien_nom": "Otis Malo",
  "technicien_telephone": "+226 70 12 34 56",
  "predominances_florales": ["Acacia", "Néré"],
  "contenants": [
    {
      "id": "container_1",
      "hiveType": "Traditionnelle",
      "containerType": "Pôt",
      "weight": 25.5,
      "unitPrice": 2500,
      "total": 63750
    }
  ],
  "totalWeight": 25.5,
  "totalAmount": 63750,
  "nombreContenants": 1,
  "status": "en_attente",
  "createdAt": "2024-01-07T10:12:01.000Z",
  "updatedAt": "2024-01-07T10:12:01.000Z",
  "metadata": {
    "createdBy": "app_mobile",
    "version": "1.0",
    "source": "nouvelle_collecte_recolte"
  }
}
```

### Document de statistiques (`_statistiques_structurees`)
```json
{
  "type": "statistiques_recoltes",
  "derniere_mise_a_jour": "2024-01-07T10:12:01.000Z",
  "periode_debut": "2024-01-01T00:00:00.000Z",
  "periode_fin": "2024-01-07T10:12:01.000Z",
  "resume_global": {
    "nombre_recoltes": 15,
    "poids_total_kg": 380.5,
    "montant_total_fcfa": 951250,
    "poids_moyen_kg": 25.37,
    "montant_moyen_fcfa": 63416.67
  },
  "repartition_techniciens": [
    {
      "technicien": "Otis Malo",
      "nombre_recoltes": 8,
      "poids_total_kg": 204.2
    }
  ],
  "types_contenants": [
    {
      "type": "Pôt",
      "quantite": 12
    },
    {
      "type": "Fût",
      "quantite": 8
    }
  ],
  "types_ruches": [
    {
      "type": "Traditionnelle",
      "quantite": 15
    },
    {
      "type": "Moderne",
      "quantite": 5
    }
  ],
  "derniere_recolte": { /* Données de la dernière récolte */ }
}
```

## Fonctionnalités de sécurité

### 1. Validation en temps réel
- ✅ Contrôles de saisie avec messages d'erreur explicites
- ✅ Validation des calculs automatiques
- ✅ Vérification de l'intégrité des données

### 2. Sécurité Firestore
- ✅ Écriture limitée aux collections autorisées
- ✅ ID personnalisés pour éviter les collisions
- ✅ Vérifications d'existence avant écriture
- ✅ Logs détaillés pour le débogage

### 3. Traçabilité
- ✅ Timestamps précis (création/modification)
- ✅ Métadonnées d'origine
- ✅ Historique complet conservé
- ✅ Logs de toutes les opérations

## Gestion des statistiques

### Génération automatique
Les statistiques sont automatiquement générées et mises à jour après chaque nouvelle récolte :
- Résumé global (totaux, moyennes)
- Répartition par technicien
- Analyse des types de contenants et ruches
- Conservation de la dernière récolte

### Performance
- Calculs optimisés sur des documents structurés
- Limitation du nombre de documents traités
- Mise à jour incrémentale des totaux

## Historique et filtrage

### Chargement intelligent
- ✅ Lecture depuis la structure Sites/{nomSite}/nos_recoltes/
- ✅ Filtrage par site et technicien
- ✅ Pagination pour les performances
- ✅ Gestion des erreurs et documents corrompus

### Interface utilisateur
- ✅ Historique local pour la session courante
- ✅ Historique Firestore multi-utilisateur
- ✅ Filtres dynamiques
- ✅ Actualisation en temps réel

## Comparaison avec le système de collecte individuelle

| Aspect | Collecte Individuelle | Collecte Récolte |
|--------|----------------------|------------------|
| **Structure** | `Sites/{site}/nos_achats_individuels/` | `Sites/{site}/nos_recoltes/` |
| **Données centrales** | Producteur + Contenants | Technicien + Contenants |
| **Validation** | Producteur requis | Technicien requis |
| **Statistiques** | Par producteur/village | Par technicien/site |
| **Sécurité** | ✅ Identique | ✅ Identique |
| **ID Format** | `collecte_{timestamp}_{producteur}` | `recolte_{timestamp}_{site}` |

## Avantages du système

### 1. Cohérence architecturale
- Même pattern de sécurité que les collectes individuelles
- Structure Firestore logique et évolutive
- Code réutilisable et maintenable

### 2. Sécurité renforcée
- Écriture contrôlée dans des collections dédiées
- Validation complète avant enregistrement
- Traçabilité intégrale des opérations

### 3. Performance
- Requêtes optimisées par site
- Statistiques pré-calculées
- Chargement intelligent de l'historique

### 4. Évolutivité
- Structure extensible pour nouveaux champs
- Compatibilité avec de futurs modules
- Intégration facile avec d'autres systèmes

## Code d'exemple

### Enregistrement d'une récolte
```dart
// Validation et génération d'ID
final String idRecolte = 'recolte_${DateTime.now().millisecondsSinceEpoch}_${selectedSite!.toLowerCase()}';

// Enregistrement sécurisé
final recolteRef = FirebaseFirestore.instance
    .collection('Sites')
    .doc(selectedSite!)
    .collection('nos_recoltes')
    .doc(idRecolte);

await recolteRef.set(recolteData);

// Génération des statistiques
await _genererStatistiquesRecolte(selectedSite!, recolteData);
```

### Lecture de l'historique
```dart
// Lecture sécurisée depuis la bonne collection
Query query = FirebaseFirestore.instance
    .collection('Sites')
    .doc(siteAChercher)
    .collection('nos_recoltes')
    .orderBy('createdAt', descending: true)
    .limit(50);

final snapshot = await query.get();
```

Ce système garantit une gestion complète, sécurisée et performante des récoltes de miel, en parfaite cohérence avec l'architecture existante de l'application Apisavana.
