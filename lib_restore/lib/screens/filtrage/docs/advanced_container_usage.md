# Widget Avancé d'Identification des Contenants - Module Filtrage

## Vue d'ensemble

Ce widget implémente une approche sécurisée pour l'identification des contenants avec protection de la partie fixe et modification du code numéro uniquement.

## Fonctionnement

### Exemple d'ID : `REC_NONA_HIPPOLYTEYAMEOGO_20250902_0002`

**Structure :**
- 🔒 **Partie fixe protégée** : `REC_NONA_HIPPOLYTEYAMEOGO_20250902_`
- ✏️ **Code modifiable** : `0002` (seulement les 4 derniers chiffres)

## Fonctionnalités

### 1. Protection de la partie fixe
- ✅ **Seuls les 4 derniers chiffres** peuvent être modifiés
- ❌ **Impossible de modifier** le type, village, technicien, producteur, date
- 🔄 **Validation en temps réel** des modifications

### 2. Synchronisation automatique
- 📱 **Champ "Numéro code"** se met à jour automatiquement
- 🔒 **Champ verrouillé** - aucune saisie manuelle possible
- ⚡ **Mise à jour instantanée** lors du changement du numéro dans l'ID

### 3. Génération automatique de la nature
- 🤖 **Nature du contenant** générée automatiquement
- 📝 **Format** : `{Type} - N°{Numéro}`
- 🔒 **Champ en lecture seule**

## Composants

### AdvancedContainerIdWidget
**Fichier:** `lib/screens/filtrage/widgets/advanced_container_id_widget.dart`

#### Utilisation :
```dart
AdvancedContainerIdWidget(
  onContainerChanged: (containerId, containerNature, numeroCode) {
    print('ID: $containerId');
    print('Nature: $containerNature');
    print('Code: $numeroCode');
  },
  initialContainerId: 'REC_NONA_HIPPOLYTEYAMEOGO_20250902_0002',
)
```

#### Paramètres :
- `onContainerChanged`: Callback appelé à chaque modification
- `initialContainerId`: ID initial (optionnel)

#### Retours dans le callback :
- `containerId`: ID complet du contenant
- `containerNature`: Nature générée automatiquement
- `numeroCode`: Code numéro extrait (4 chiffres)

## Restrictions d'entrée

### InputFormatter avancé
Le widget utilise `AdvancedContainerIdInputFormatter` qui :

1. **Protège la partie fixe** : Impossible de la modifier
2. **Limite le numéro** : Maximum 4 chiffres
3. **Valide en temps réel** : Rejette les modifications invalides
4. **Format automatique** : Complète avec des zéros si nécessaire

### Validation
- ✅ **Type valide** : REC, SCO, IND, MIE
- ✅ **Date valide** : Format YYYYMMDD (8 chiffres)
- ✅ **Numéro valide** : Exactement 4 chiffres
- ✅ **Structure** : Minimum 6 parties séparées par `_`

## Interface utilisateur

### Champ "Identifiant du contenant"
- 🎯 **Hint** visuel de la partie modifiable
- 🔍 **Aide contextuelle** sur les restrictions
- ✅ **Validation visuelle** avec icônes et couleurs

### Champ "Numéro code *"
- 🔒 **Icône de verrouillage**
- 🔄 **Indicateur de synchronisation**
- 📝 **Message explicatif** du verrouillage

### Champ "Nature du contenant"
- 🤖 **Génération automatique**
- 🔒 **Lecture seule**
- 💡 **Indication de la source** (extraite de l'ID)

## Exemples d'utilisation

### 1. Modification du numéro
```
Initial: REC_NONA_HIPPOLYTEYAMEOGO_20250902_0002
Modifier le numéro à: 0005
Résultat: REC_NONA_HIPPOLYTEYAMEOGO_20250902_0005
```

### 2. Tentative de modification de la partie fixe
```
Tentative: Modifier "NONA" en "VILLAGE"
Résultat: ❌ Modification rejetée, retour à l'état précédent
```

### 3. Synchronisation du numéro code
```
ID: REC_NONA_HIPPOLYTEYAMEOGO_20250902_0007
Numéro code automatique: 0007
Nature automatique: Récolte - N°0007
```

## Messages d'aide

Le widget fournit plusieurs niveaux d'aide :

### 1. Aide contextuelle
- 🔍 **Explication** du fonctionnement
- 📝 **Exemples** d'IDs valides
- ⚠️ **Limitations** clairement expliquées

### 2. Feedback visuel
- 🟢 **Vert** : Structure valide
- 🔴 **Rouge** : Erreur de format
- 🟠 **Orange** : Champs synchronisés

### 3. Messages d'erreur
- 📍 **Précis** : Indique exactement le problème
- 💡 **Constructifs** : Suggère comment corriger

## Tests et démonstration

### Page de démonstration
**Fichier:** `lib/screens/filtrage/pages/advanced_container_demo.dart`

#### Fonctionnalités de test :
- 🎮 **Boutons prédéfinis** pour tester différents IDs
- 📊 **Décomposition visuelle** de l'ID
- 🔍 **Affichage en temps réel** des valeurs extraites
- 📝 **Journal des modifications**

#### IDs de test inclus :
```
REC_NONA_HIPPOLYTEYAMEOGO_20250902_0001
SCO_VILLAGE_TECH_PROD_20250101_0003  
IND_SAKOINSÉ_JEAN_MARIE_20241215_0005
MIE_BOBO_AGENT_APICULTEUR_20250315_0010
```

## Intégration dans l'application

### Remplacement d'un formulaire existant

**Avant :**
```dart
// Ancien système avec 2 champs séparés
TextFormField(
  decoration: InputDecoration(labelText: 'ID Contenant'),
),
TextFormField(
  decoration: InputDecoration(labelText: 'Numéro code'),
),
```

**Après :**
```dart
// Nouveau système unifié et sécurisé
AdvancedContainerIdWidget(
  onContainerChanged: (containerId, nature, numeroCode) {
    _containerId = containerId;
    _containerNature = nature;
    _numeroCode = numeroCode;
  },
)
```

### Gestion d'état
```dart
class _MyFormState extends State<MyForm> {
  String _containerId = '';
  String _containerNature = '';
  String _numeroCode = '';

  void _onContainerChanged(String id, String nature, String code) {
    setState(() {
      _containerId = id;
      _containerNature = nature; 
      _numeroCode = code;
    });
    
    // Logique métier additionnelle si nécessaire
    _validateForm();
  }
}
```

## Sécurité et validation

### Protection des données
- 🛡️ **Partie fixe** impossible à corrompre
- ✅ **Validation stricte** du format
- 🔒 **Champs critiques** en lecture seule

### Expérience utilisateur
- 🎯 **Focus** sur ce qui peut être modifié
- 💡 **Guidance claire** sur les restrictions
- ⚡ **Feedback immédiat** sur les modifications

### Performance
- 🚀 **Validation en temps réel** sans lag
- 💾 **Mémoire optimisée** avec disposal correct
- 📱 **Responsive** sur tous les écrans

## Maintenance

### Points d'attention
1. **Format d'ID** : Vérifier que le format reste cohérent
2. **Types de collecte** : Maintenir la liste des types valides
3. **Validation** : Adapter selon les besoins métier

### Extension possible
- Ajout de nouveaux types de collecte
- Personnalisation des formats de numéro
- Intégration avec d'autres systèmes de validation
