# Nouvelle Collecte Achat Individuelle

## Description

Cette page permet de créer une nouvelle collecte d'achat individuelle pour un producteur de miel. Elle respecte scrupuleusement l'architecture Firestore définie et intègre des animations modernes avec une gestion d'erreurs robuste.

## Fonctionnalités

### ✅ Sélection dynamique d'un producteur
- **StreamBuilder/Firestore** : Liste temps réel des producteurs depuis `Sites/{nomSite}/utilisateurs/`
- **Animation fluide** : Ouverture/fermeture de la modale avec DraggableScrollableSheet
- **Pagination** : Support jusqu'à 20 producteurs par page (configurable)

### ✅ Ajout d'un nouveau producteur
- **Formulaire complet** : Validé en temps réel avec animations de validation
- **Validation stricte** : Vérification de l'unicité du numéro producteur
- **Enregistrement sécurisé** : Uniquement si toutes les données sont valides
- **Indépendance totale** : Pas de dépendance à l'ajout de collecte

### ✅ Saisie multi-contenants pour une collecte
- **Ajout/Suppression animée** : Fade/Slide transitions pour les lignes de contenants
- **Champs par contenant** :
  - Type de ruche (Traditionnelle, Moderne)
  - Type de miel (Acacia, Lavande, Tilleul, Châtaignier, Toutes fleurs)
  - Quantité en kg
  - Prix unitaire en FCFA
  - Note optionnelle
- **Calcul automatique** : Poids et montant total en temps réel avec animation

### ✅ Résumé visuel animé avant validation
- **Card récapitulative** : Avec transitions d'apparition
- **Informations affichées** :
  - Nombre de contenants
  - Poids total
  - Montant total
  - Origines florales détectées
- **Bloc d'erreurs animé** : Si données manquantes/incohérentes

### ✅ Enregistrement de la collecte
- **Transaction Firestore atomique** avec 4 étapes :
  1. Enregistrement dans `Sites/{nomSite}/nos_achats_individuels/collectes_YYYY_MM_DD_XXX`
  2. Ajout dans la sous-collection `collectes` du producteur
  3. Mise à jour des statistiques du producteur
  4. Mise à jour des statistiques du site
- **Validation stricte** : Rien n'est enregistré si une info obligatoire manque

### ✅ Gestion erreurs/UX
- **Aucun crash possible** : Chaque opération Firestore est entourée de try/catch
- **Messages d'erreur visuels** : SnackBar animées avec couleurs appropriées
- **Validation en direct** : Boutons désactivés si formulaire invalide
- **Animation shake** : Si tentative d'enregistrement avec données manquantes

## Architecture Firestore

### Producteur individuel
**Chemin** : `Sites/{nomSite}/utilisateurs/prod_{numero}`

```json
{
  "nomPrenom": "string",
  "numero": "string", 
  "sexe": "Masculin|Féminin",
  "age": "number",
  "appartenance": "string",
  "cooperative": "string",
  "localisation": {
    "region": "string",
    "province": "string", 
    "commune": "string",
    "village": "string",
    "secteur": "string"
  },
  "nbRuchesTrad": "number",
  "nbRuchesMod": "number", 
  "totalRuches": "number",
  "nombreCollectes": "number",
  "poidsTotal": "number",
  "montantTotal": "number",
  "originesFlorale": ["string"],
  "derniereCollecte": "Timestamp",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### Collecte individuelle  
**Chemin** : `Sites/{nomSite}/nos_achats_individuels/collectes_YYYY_MM_DD_XXX`

```json
{
  "id_collecte": "string",
  "date_achat": "Timestamp",
  "poids_total": "number",
  "montant_total": "number", 
  "nombre_contenants": "number",
  "id_producteur": "string",
  "nom_producteur": "string",
  "contenants": [
    {
      "type_ruche": "string",
      "type_miel": "string", 
      "quantite": "number",
      "prix_unitaire": "number",
      "note": "string"
    }
  ],
  "origines_florales": ["string"],
  "collecteur_id": "string",
  "collecteur_nom": "string",
  "observations": "string",
  "statut": "collecte_terminee",
  "created_at": "Timestamp"
}
```

### Statistiques mises à jour

#### Producteur
- `nombreCollectes` : Incrémenté de 1
- `poidsTotal` : Incrémenté du poids de la collecte
- `montantTotal` : Incrémenté du montant de la collecte
- `derniereCollecte` : Mis à jour avec la date actuelle
- `originesFlorale` : Ajout des nouvelles origines
- `updatedAt` : Mis à jour

#### Site (`Sites/{nomSite}/site_infos/infos`)
- `total_collectes_individuelles` : Incrémenté de 1
- `total_poids_collecte_individuelle` : Incrémenté du poids
- `total_montant_collecte_individuelle` : Incrémenté du montant
- `collectes_par_mois.YYYY-MM` : Incrémenté de 1
- `contenant_collecter_par_mois.YYYY-MM` : Incrémenté du nombre de contenants
- `derniere_activite` : Mis à jour

## Animations implémentées

### Fade Animation
- **Utilisation** : Transition d'apparition de la page principale
- **Durée** : 300ms avec courbe `easeInOut`

### Slide Animation  
- **Utilisation** : Transition de glissement des éléments
- **Durée** : 400ms avec courbe `easeOutCubic`

### Shake Animation
- **Utilisation** : Animation d'erreur sur validation
- **Durée** : 500ms avec courbe `elasticIn`

### Container Animations
- **AnimatedContainer** : Pour les transitions de couleur et taille
- **AnimatedSwitcher** : Pour les changements de contenu

## Debug et Logs

Le code inclut des **prints détaillés** à chaque étape :

```dart
print("🟢 Initialisation"); // Succès
print("🟡 En cours");      // Information
print("🔴 Erreur");        // Erreur
print("✅ Terminé");       // Succès final
```

### Exemple de logs
```
🟢 NouvelleCollecteIndividuellePage - Initialisation
🟢 Session utilisateur trouvée: Sophie Durand - Site: Ouaga
🟡 _ajouterContenant - Ajout nouveau contenant
🟡 Calcul poids total: 25.5 kg
🟡 Calcul montant total: 765000 FCFA
🟡 _enregistrerCollecte - Début enregistrement
🟡 ID collecte généré: collectes_2025_08_04_1722771234567
🟡 Début transaction Firestore
🟡 Transaction - Étape 1: Enregistrement collecte principale
🟡 Transaction - Étape 2: Ajout à la sous-collection du producteur
🟡 Transaction - Étape 3: Mise à jour statistiques producteur
🟡 Transaction - Étape 4: Mise à jour statistiques site
✅ Transaction terminée avec succès
```

## Utilisation

1. **Accès** : Dashboard → Module COLLECTE → "Achats Individuels"
2. **Sélection producteur** : Cliquer sur "Sélectionner un producteur" ou "Ajouter nouveau producteur"
3. **Saisie contenants** : Remplir les informations pour chaque contenant
4. **Validation** : Vérifier le résumé et cliquer sur "Enregistrer la collecte"

## Configuration

Les constantes sont définies dans `lib/utils/app_config.dart` :
- Types de ruches et miels
- Limites de validation  
- Couleurs et styles
- Messages d'erreur

## Dependencies requises

```yaml
dependencies:
  flutter:
    sdk: flutter
  cloud_firestore: ^4.15.8
  get: ^4.6.6
  firebase_auth: ^4.17.8
```

## Performance

- **Pagination** : Maximum 20 producteurs chargés à la fois
- **StreamBuilder** : Mise à jour temps réel de la liste des producteurs
- **Transactions atomiques** : Garantit la cohérence des données
- **Validation locale** : Réduit les appels Firestore inutiles
