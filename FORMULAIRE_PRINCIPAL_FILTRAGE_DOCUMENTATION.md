# FORMULAIRE PRINCIPAL DE FILTRAGE AVEC GÉNÉRATION AUTOMATIQUE DE LOT

## Vue d'ensemble

Le formulaire `FiltrageFormWithContainerId` est maintenant le **formulaire principal** pour le processus de filtrage dans l'application. Il intègre la génération automatique de numéro de lot et toute la logique complète de filtrage.

## Fonctionnalités principales

### ✅ Génération automatique de numéro de lot
- Basée sur l'ID du contenant saisi par l'utilisateur
- Format: `TYPE_DATE_NUMERO` (ex: IND_20241215_0001)
- Extraction automatique à partir de l'ID complet du contenant

### ✅ Identification intelligente des contenants
- Widget `ContainerIdentificationWidget` avec restrictions
- Validation du format d'ID: `TYPE_VILLAGE_TECHNICIEN_PRODUCTEUR_DATE_NUMERO`
- Extraction automatique de la nature du contenant (type + numéro)
- Champ nature verrouillé et rempli automatiquement

### ✅ Logique complète de filtrage
- Sauvegarde dans la collection Firestore `filtrage`
- Marquage du produit comme filtré (`estFiltre = true`) dans les collections source
- Gestion des produits d'attribution et d'extraction
- Logs distinctifs pour traçage et debug

### ✅ Interface utilisateur moderne
- Sections organisées et claires
- Calcul automatique du rendement de filtrage
- Validation des données avec feedback utilisateur
- Indicateurs de chargement et messages de succès/erreur

## Intégration dans l'interface

### Filtrage individuel
Le formulaire est accessible depuis la page principale des produits (`FiltrageProductsPage`) via le bouton "Filtrer" sur chaque carte de produit :

```dart
// Ouverture du formulaire principal pour un produit individuel
void _ouvrirFiltrageIndividuel(ProductControle product) async {
  final productData = {
    'id': product.id,
    'producteur': product.producteur,
    'village': product.village,
    // ... autres données
  };

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FiltrageFormWithContainerId(
        product: productData,
        onFiltrageComplete: () => _refresh(),
      ),
    ),
  );
}
```

### Données requises
Le formulaire attend un `Map<String, dynamic>` avec les propriétés suivantes :

```dart
final productData = {
  'id': 'ID_du_produit',
  'producteur': 'Nom_du_producteur',
  'village': 'Village',
  'site': 'Site_origine',
  'controleur': 'Nom_controleur',
  'poids_net': 25.5, // double
  'poids': 24.2,     // double
  'source': 'attribution', // ou 'extraction'
  // ... autres propriétés optionnelles
};
```

## Processus de filtrage

### 1. Saisie de l'identifiant du contenant
- L'utilisateur saisit l'ID exact du contenant
- Validation automatique du format
- Extraction automatique de la nature (type + numéro)

### 2. Génération automatique du numéro de lot
```dart
String _generateNumeroLot(String containerId) {
  final parts = containerId.split('_');
  if (parts.length >= 6) {
    final type = parts[0];      // IND, REC, SCO, MIE
    final date = parts[parts.length - 2]; // YYYYMMDD
    final numero = parts.last;  // 0001
    
    return '${type}_${date}_$numero';
  }
  return containerId; // Fallback
}
```

### 3. Sauvegarde et marquage
- Sauvegarde dans `filtrage` collection avec toutes les données
- Marquage dans les collections `attribution` et `extraction`
- Mise à jour du champ `estFiltre = true`

### 4. Exclusion des listes
Les services de filtrage excluent automatiquement les produits avec `estFiltre == true` :

```dart
// Dans FiltrageAttributionService
.where('estFiltre', isNotEqualTo: true)

// Dans FilteredProductsService  
.where('statut', isNotEqualTo: 'terminé')
```

## Logs et debugging

Le formulaire génère des logs distinctifs pour faciliter le debug :

```
📋 [FiltrageFormWithContainerId] Initialisation du formulaire principal...
🚀 [FiltrageFormWithContainerId] Début du processus de filtrage principal
📋 [FiltrageFormWithContainerId] Numéro de lot généré automatiquement: IND_20241215_0001
💾 [FiltrageFormWithContainerId] Sauvegarde des données de filtrage dans Firestore...
✅ [FiltrageFormWithContainerId] Données de filtrage sauvegardées avec succès
🏷️ [FiltrageFormWithContainerId] Marquage du produit comme filtré...
🎯 [FiltrageFormWithContainerId] Marquage terminé avec succès
✨ [FiltrageFormWithContainerId] Processus de filtrage principal terminé avec succès
```

## Avantages de cette approche

### ✅ Génération automatique
- Plus de saisie manuelle du numéro de lot
- Cohérence garantie avec l'ID du contenant
- Réduction des erreurs de saisie

### ✅ Traçabilité complète
- Logs distinctifs pour chaque étape
- Identification claire de la source des opérations
- Historique complet des actions

### ✅ Logique centralisée
- Un seul formulaire pour le processus principal
- Cohérence des données entre les collections
- Maintenance simplifiée

### ✅ Interface moderne
- Design cohérent avec le reste de l'application
- Feedback utilisateur en temps réel
- Expérience utilisateur optimisée

## Migration depuis les anciens formulaires

Les anciens formulaires (`FiltrageForm`, `FiltrageFormModal`) restent disponibles pour la compatibilité, mais **il est recommandé d'utiliser `FiltrageFormWithContainerId`** pour tous les nouveaux développements car il :

- Intègre la génération automatique de lot
- A une logique de filtrage plus robuste
- Fournit de meilleurs logs de debugging
- Offre une meilleure expérience utilisateur

## Tests et validation

Pour tester le formulaire :

1. Accéder à la page des produits de filtrage
2. Cliquer sur "Filtrer" sur une carte de produit
3. Saisir un ID de contenant valide (ex: `IND_SAKOINSÉ_JEAN_MARIE_20241215_0001`)
4. Vérifier la génération automatique du numéro de lot
5. Compléter le formulaire et valider
6. Vérifier que le produit disparaît de la liste "Produits Attribués"
7. Vérifier qu'il apparaît dans l'historique de filtrage

## Structure des données Firestore

### Collection `filtrage`
```json
{
  "product_id": "ID_du_produit",
  "container_id": "IND_SAKOINSÉ_JEAN_MARIE_20241215_0001",
  "container_nature": "Individuel - N°0001",
  "numero_lot": "IND_20241215_0001",
  "agent_filtrage": "Nom de l'agent",
  "poids_initial": 25.5,
  "poids_filtrage": 24.2,
  "date_filtrage_debut": "2024-12-15T10:00:00.000Z",
  "statut": "terminé",
  "source_type": "attribution",
  "site": "Site_origine",
  "created_at": "2024-12-15T10:30:00.000Z"
}
```

### Collections sources (attribution/extraction)
```json
{
  // ... données existantes
  "estFiltre": true  // Ajouté lors du filtrage
}
```

Ce formulaire principal garantit une expérience utilisateur fluide avec la génération automatique de numéro de lot tout en maintenant la cohérence des données et la traçabilité complète des opérations.
