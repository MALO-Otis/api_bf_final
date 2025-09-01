# 📋 Système d'Attribution pour Extraction/Maturation

## 🎯 **Vue d'ensemble**

Le système d'attribution permet de gérer l'attribution des contenants d'extraction vers des lots pour les processus d'extraction et de maturation. Il s'intègre parfaitement au module Extraction existant sans le modifier inutilement.

## 🏗️ **Architecture**

### **📁 Structure des fichiers**
```
lib/screens/extraction/
├── models/
│   └── attribution_models.dart          # Modèles de données
├── services/
│   └── attribution_service.dart         # Service de gestion
├── pages/
│   └── attribution_page.dart           # Interface principale
└── widgets/
    ├── attribution_card.dart           # Carte d'affichage
    ├── attribution_modals.dart         # Modals de création/édition
    ├── attribution_filters.dart        # Système de filtres
    └── attribution_stats.dart          # Statistiques
```

### **🗃️ Entité AttributionExtraction**
```dart
class AttributionExtraction {
  final String id;                      // Identifiant unique
  final DateTime dateAttribution;       // Date/heure d'attribution
  final String utilisateur;            // Nom de l'agent/admin
  final String lotId;                   // Numéro de lot (obligatoire)
  final List<String> listeContenants;  // IDs des ExtractionProduct
  final AttributionStatus statut;      // Statut du workflow
  final String? commentaires;          // Commentaires optionnels
  final Map<String, dynamic> metadata; // Données additionnelles
}
```

### **📊 Statuts du workflow**
1. **attribueExtraction** - Attribution initiale
2. **enCoursExtraction** - Extraction en cours
3. **extraitEnAttente** - Extrait, en attente de maturation
4. **attribueMaturation** - Attribué pour maturation
5. **enCoursMaturation** - Maturation en cours
6. **termineMaturation** - Processus terminé
7. **annule** - Attribution annulée

## 🚀 **Fonctionnalités**

### **✅ Gestion des attributions**
- ✨ **Création d'attribution** avec sélection multiple de contenants
- 📝 **Modification** des attributions existantes
- ❌ **Annulation** avec traçabilité
- 🔒 **Validation** : numéro de lot unique, contenants non déjà attribués

### **🎨 Interface utilisateur**
- 📱 **Responsive** : Desktop, tablette, mobile
- 🔍 **Recherche** par lot, utilisateur, statut
- 🎛️ **Filtres avancés** : statuts, utilisateurs, dates
- 📈 **Statistiques temps réel** avec animations

### **💾 Stockage local**
- 🗂️ **Données en mémoire** pour tests sans backend
- 📤 **Export/Import JSON** pour persistance locale
- 🔄 **Service Singleton** avec notifications de changements

## 🎮 **Utilisation**

### **🖥️ Accès depuis le module Extraction**
- **Desktop** : Bouton "Attributions" dans le header
- **Mobile** : FloatingActionButton "Attributions"

### **➕ Créer une attribution**
1. Cliquer sur "Nouvelle Attribution"
2. Sélectionner l'utilisateur et saisir le numéro de lot
3. Choisir les contenants à attribuer (sélection multiple)
4. Ajouter des commentaires optionnels
5. Valider - le système vérifie l'unicité du lot

### **✏️ Modifier une attribution**
1. Cliquer sur "Modifier" dans la carte d'attribution
2. Changer le statut, les contenants, ou les commentaires
3. La modification est tracée (date, utilisateur)

### **📋 Filtrer et rechercher**
- **Recherche textuelle** : Par lot ou utilisateur
- **Filtres par statut** : Sélection multiple
- **Filtres par utilisateur** : Tous les utilisateurs actifs
- **Filtres par date** : Période d'attribution

## 🔧 **Intégration technique**

### **🔗 Avec le module Extraction existant**
```dart
// Dans extraction_page.dart
void _openAttributionPage() {
  Get.to(() => const AttributionPage());
}
```

### **📡 Service d'attribution**
```dart
final AttributionService _service = AttributionService();

// Créer une attribution
await _service.creerAttribution(
  utilisateur: 'Marie Dupont',
  lotId: 'LOT_2024001',
  listeContenants: ['prod_1', 'prod_2'],
  commentaires: 'Attribution urgente',
);

// Vérifier si un contenant est attribué
bool isAttribue = _service.contenantEstAttribue('prod_1');
```

### **🎨 Thème et design**
- Cohérence avec le design du module Extraction
- Dégradés bleu-violet pour l'identification
- Animations fluides et feedback utilisateur
- Icônes Material Design

## 📱 **Responsive Design**

### **🖥️ Desktop (> 1200px)**
- Grille 2 colonnes pour les cartes d'attribution
- Statistiques en ligne
- Modals larges avec plus d'espace

### **📟 Tablette (600-1200px)**
- Liste verticale des attributions
- Statistiques empilées
- Interface optimisée tactile

### **📱 Mobile (< 600px)**
- Liste simple avec cartes compactes
- FloatingActionButton d'accès rapide
- Modals plein écran

## 🔒 **Sécurité et validation**

### **✅ Validations métier**
- Numéro de lot unique (sauf statut annulé)
- Contenants non déjà attribués
- Impossible de modifier/annuler si terminé
- Traçabilité complète des modifications

### **🛡️ Gestion d'erreurs**
```dart
try {
  await service.creerAttribution(...);
} catch (e) {
  Get.snackbar('Erreur', e.toString());
}
```

## 📊 **Statistiques**

### **🎯 Métriques principales**
- Total des attributions
- Répartition par statut (en cours, terminées, annulées)
- Répartition par utilisateur
- Évolution temporelle

### **📈 Visualisation**
- Barres de progression animées
- Graphiques en temps réel
- Codes couleur par statut
- Compteurs avec animations

## 🔮 **Extensibilité future**

### **🌐 Migration vers base de données**
Le service est conçu pour être facilement connecté à une vraie base de données :
```dart
// Remplacer les méthodes mock par des appels API
Future<String> creerAttribution(...) async {
  // POST /api/attributions
  final response = await http.post(...);
  return response.data['id'];
}
```

### **🔄 Intégration Firestore**
```dart
// Collection Firestore future
final attributionsRef = FirebaseFirestore.instance
    .collection('Sites')
    .doc(siteId)
    .collection('attributions_extraction');
```

## 🚀 **Performance**

- **Singleton pattern** pour éviter les instances multiples
- **ChangeNotifier** pour les mises à jour réactives
- **Filtrage en mémoire** très rapide
- **Animations optimisées** 60fps
- **Lazy loading** des widgets complexes

## 🎉 **Résultat final**

✅ **Système d'attribution complet et professionnel**  
✅ **Interface moderne et intuitive**  
✅ **Données gérées localement** (testable sans backend)  
✅ **Intégration transparente** avec le module Extraction  
✅ **Architecture modulaire** et extensible  
✅ **Design responsive** pour tous les écrans  
✅ **Code propre** et maintenable  

**Le système est prêt à être utilisé et peut être facilement connecté à une vraie base de données plus tard ! 🎯**
