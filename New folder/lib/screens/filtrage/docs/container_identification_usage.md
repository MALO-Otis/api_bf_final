# Widget d'Identification des Contenants - Module Filtrage

## Vue d'ensemble

Le module de filtrage dispose désormais d'un système sécurisé pour l'identification des contenants avec les restrictions demandées :

1. **Champ "Identifiant du contenant"** : Seuls les codes numériques de contenant sont autorisés
2. **Champ "Nature du contenant"** : Automatiquement rempli et verrouillé, basé sur l'identifiant

## Composants créés

### 1. ContainerIdentificationWidget
**Fichier:** `lib/screens/filtrage/widgets/container_identification_widget.dart`

Widget principal qui implémente les restrictions demandées :

#### Fonctionnalités :
- ✅ **Restriction de saisie** : Seuls les caractères alphanumériques, underscore (_) et tiret (-) sont autorisés
- ✅ **Validation format** : Vérification du format d'ID correct (TYPE_VILLAGE_TECHNICIEN_PRODUCTEUR_DATE_NUMERO)
- ✅ **Extraction automatique** : La nature du contenant est automatiquement extraite de l'ID
- ✅ **Verrouillage** : Le champ "Nature du contenant" est en lecture seule
- ✅ **Conversion automatique** : Le texte saisi est automatiquement converti en majuscules
- ✅ **Feedback visuel** : Icônes et couleurs pour indiquer la validité de l'ID

#### Utilisation :
```dart
ContainerIdentificationWidget(
  onContainerChanged: (containerId, containerNature) {
    // Gérer les changements
    print('ID: $containerId');
    print('Nature: $containerNature');
  },
  initialContainerId: 'IND_SAKOINSÉ_JEAN_MARIE_20241215_0001', // Optionnel
)
```

### 2. Formats d'ID acceptés

Le widget accepte uniquement les IDs dans le format suivant :
```
{TYPE}_{VILLAGE}_{TECHNICIEN}_{PRODUCTEUR}_{DATE}_{NUMERO}
```

**Types autorisés :**
- `REC` : Récolte
- `SCO` : SCOOP  
- `IND` : Individuel
- `MIE` : Miellerie

**Exemple d'ID valide :**
```
IND_SAKOINSÉ_JEAN_MARIE_20241215_0001
```

### 3. Extraction automatique de la nature

À partir de l'ID, le widget extrait automatiquement :
- Le **type** de collecte (Récolte, SCOOP, Individuel, Miellerie)
- Le **numéro** du contenant (les 4 derniers chiffres)

**Exemple :**
- ID : `IND_SAKOINSÉ_JEAN_MARIE_20241215_0001`
- Nature extraite : `Individuel - N°0001`

## Pages d'exemple

### 1. ContainerIdentificationDemo
**Fichier:** `lib/screens/filtrage/pages/container_identification_demo.dart`

Page de démonstration simple montrant le widget en action.

### 2. FiltrageFormWithContainerId  
**Fichier:** `lib/screens/filtrage/widgets/filtrage_form_with_container_id.dart`

Formulaire complet de filtrage intégrant le widget d'identification avec :
- Validation complète
- Calcul automatique du rendement
- Gestion des dates
- Interface responsive

## Restrictions implémentées

### 1. Champ "Identifiant du contenant"
- ❌ **Caractères spéciaux** bloqués (sauf _ et -)
- ❌ **Espaces** non autorisés
- ❌ **Caractères accentués** bloqués
- ✅ **Seulement** : A-Z, 0-9, _, -
- ✅ **Conversion automatique** en majuscules

### 2. Champ "Nature du contenant"
- 🔒 **Champ verrouillé** - aucune saisie manuelle possible
- 🤖 **Remplissage automatique** basé sur l'ID
- 🔄 **Mise à jour en temps réel** quand l'ID change
- ⚠️ **Indicateur visuel** de verrouillage

## Validation et contrôles

### Validation de l'ID
1. **Format** : Vérification de la structure TYPE_..._NUMERO
2. **Type** : Doit être REC, SCO, IND, ou MIE
3. **Date** : Format YYYYMMDD (8 chiffres)
4. **Numéro** : 4 chiffres exactement
5. **Parties** : Minimum 6 parties séparées par _

### Feedback utilisateur
- 🟢 **Icône verte** : ID valide
- 🔴 **Message d'erreur** : ID invalide avec explication
- 🔵 **Aide contextuelle** : Information sur le format attendu

## Intégration dans l'application

### Comment remplacer un champ existant

1. **Remplacer** l'ancien TextFormField par ContainerIdentificationWidget
2. **Supprimer** le champ "Nature du contenant" s'il existe séparément
3. **Écouter** les changements via le callback `onContainerChanged`

**Avant :**
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Identifiant du contenant',
  ),
),
TextFormField(
  decoration: InputDecoration(
    labelText: 'Nature du contenant',
  ),
),
```

**Après :**
```dart
ContainerIdentificationWidget(
  onContainerChanged: (containerId, containerNature) {
    // Les deux valeurs sont fournies automatiquement
    setState(() {
      _containerId = containerId;
      _containerNature = containerNature;
    });
  },
)
```

## Messages d'aide pour l'utilisateur

Le widget fournit automatiquement :
- **Instructions** sur le format d'ID
- **Exemples** d'IDs valides  
- **Explication** du verrouillage du champ Nature
- **Feedback** en temps réel sur la validité

## Accessibilité et UX

- 📱 **Responsive** : S'adapte aux petits écrans
- ♿ **Accessible** : Labels et tooltips appropriés
- 🎨 **Cohérent** : Suit le design system de l'application
- ⚡ **Performance** : Validation en temps réel sans lag

## Tests et validation

Pour tester le widget :
1. Naviguez vers `ContainerIdentificationDemo`
2. Essayez de saisir différents types de caractères
3. Vérifiez que seuls les caractères autorisés passent
4. Observez la mise à jour automatique du champ Nature
5. Testez avec des IDs valides et invalides

**IDs de test :**
- ✅ `IND_SAKOINSÉ_JEAN_MARIE_20241215_0001` (valide)
- ❌ `IND_SAKOINSÉ_JEAN@MARIE_20241215_0001` (@ non autorisé)
- ❌ `XYZ_SAKOINSÉ_JEAN_MARIE_20241215_0001` (type XYZ invalide)
- ❌ `IND_SAKOINSÉ_JEAN_MARIE_2024121_0001` (date incomplète)
