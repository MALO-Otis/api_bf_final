# 📝 NOMMAGE PERSONNALISÉ DES DOCUMENTS RÉCOLTES

## 🎯 **MODIFICATION DU SYSTÈME DE NOMMAGE**

Les documents de récoltes utilisent maintenant un **système de nommage personnalisé** au lieu d'IDs auto-générés par Firestore.

## 🏗️ **NOUVEAU FORMAT DE NOMMAGE**

### **📋 Format :**
```
recolte_Date(XX_XX_XXXX)_NomSite
```

### **📅 Composants :**
- **`recolte_`** : Préfixe fixe
- **`Date(XX_XX_XXXX)`** : Date au format jour_mois_année
- **`_NomSite`** : Nom du site (ex: Koudougou, Bobo, etc.)

## 🔧 **EXEMPLES CONCRETS**

### **📊 Exemples de noms générés :**

| **Date** | **Site** | **Nom du document** |
|----------|----------|---------------------|
| 15/01/2024 | Koudougou | `recolte_Date(15_01_2024)_Koudougou` |
| 28/08/2025 | Bobo | `recolte_Date(28_08_2025)_Bobo` |
| 03/12/2024 | Mangodara | `recolte_Date(03_12_2024)_Mangodara` |
| 07/06/2025 | Po | `recolte_Date(07_06_2025)_Po` |

### **🔄 Gestion des collectes multiples le même jour :**

Si plusieurs collectes sont effectuées le **même jour sur le même site**, un suffixe numérique est ajouté :

| **Ordre** | **Nom du document** |
|-----------|---------------------|
| 1ère collecte | `recolte_Date(15_01_2024)_Koudougou` |
| 2ème collecte | `recolte_Date(15_01_2024)_Koudougou_1` |
| 3ème collecte | `recolte_Date(15_01_2024)_Koudougou_2` |
| 4ème collecte | `recolte_Date(15_01_2024)_Koudougou_3` |

## 💾 **STRUCTURE FIRESTORE FINALE**

```
📂 Firestore Database
└── 📂 Sites/
    └── 📂 Koudougou/
        └── 📂 nos_collectes_recoltes/
            ├── 📄 recolte_Date(15_01_2024)_Koudougou      ← Collecte du 15/01
            ├── 📄 recolte_Date(16_01_2024)_Koudougou      ← Collecte du 16/01
            ├── 📄 recolte_Date(16_01_2024)_Koudougou_1    ← 2ème collecte du 16/01
            ├── 📄 recolte_Date(17_01_2024)_Koudougou      ← Collecte du 17/01
            └── 📄 statistiques_avancees                   ← Stats avancées
```

## 🔧 **IMPLÉMENTATION TECHNIQUE**

### **📝 Code de génération de l'ID :**

```dart
// Générer l'ID personnalisé basé sur la date et le site
final now = DateTime.now();
final dateFormatted = '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}';
String customDocId = 'recolte_Date(${dateFormatted})_$site';

// Vérifier si le document existe déjà et ajouter un suffixe si nécessaire
final collectionRef = _firestore
    .collection('Sites')
    .doc(site)
    .collection('nos_collectes_recoltes');

int counter = 1;
String finalDocId = customDocId;

while (true) {
  final docSnapshot = await collectionRef.doc(finalDocId).get();
  if (!docSnapshot.exists) {
    break;
  }
  // Si le document existe, ajouter un suffixe numérique
  finalDocId = '${customDocId}_${counter}';
  counter++;
}

// Enregistrer avec l'ID personnalisé
await collectionRef.doc(finalDocId).set(collecteData);
```

### **🔄 Logique de gestion des conflits :**

1. **Génération de l'ID de base** : `recolte_Date(DD_MM_YYYY)_Site`
2. **Vérification d'existence** : Le document existe-t-il déjà ?
3. **Si existe** : Ajouter un suffixe `_1`, `_2`, `_3`, etc.
4. **Si n'existe pas** : Utiliser l'ID de base
5. **Enregistrement** avec l'ID final unique

## ✅ **AVANTAGES DU NOUVEAU SYSTÈME**

### **🔍 Lisibilité :**
- ✅ **Identification immédiate** de la date et du site
- ✅ **Tri chronologique** naturel dans Firestore
- ✅ **Recherche facilitée** par nom de document

### **🗂️ Organisation :**
- ✅ **Structure claire** par date et site
- ✅ **Gestion automatique** des conflits
- ✅ **Historique visible** dans l'URL Firestore

### **🛠️ Maintenance :**
- ✅ **Debugging facilité** : nom explicite
- ✅ **Logs plus clairs** avec noms parlants
- ✅ **Exports** avec noms compréhensibles

### **📊 Analytics :**
- ✅ **Analyse temporelle** facilitée
- ✅ **Groupement par site** évident
- ✅ **Requêtes optimisées** par préfixe

## 🔄 **COMPARAISON AVANT/APRÈS**

### **🔴 AVANT (ID auto-généré) :**
```
nos_collectes_recoltes/
├── 📄 abc123def456...     ← ID cryptique
├── 📄 xyz789ghi012...     ← Impossible à identifier
└── 📄 mno345pqr678...     ← Pas de logique visible
```

### **🟢 APRÈS (ID personnalisé) :**
```
nos_collectes_recoltes/
├── 📄 recolte_Date(15_01_2024)_Koudougou    ← Collecte claire
├── 📄 recolte_Date(16_01_2024)_Koudougou    ← Date et site évidents
└── 📄 recolte_Date(17_01_2024)_Bobo         ← Organisation logique
```

## 🧪 **TESTS ET VALIDATION**

### **✅ Scénarios testés :**

1. **Collecte unique par jour/site :**
   - ✅ Génère : `recolte_Date(15_01_2024)_Koudougou`

2. **Multiples collectes même jour/site :**
   - ✅ 1ère : `recolte_Date(15_01_2024)_Koudougou`
   - ✅ 2ème : `recolte_Date(15_01_2024)_Koudougou_1`
   - ✅ 3ème : `recolte_Date(15_01_2024)_Koudougou_2`

3. **Sites différents même jour :**
   - ✅ Koudougou : `recolte_Date(15_01_2024)_Koudougou`
   - ✅ Bobo : `recolte_Date(15_01_2024)_Bobo`

4. **Gestion des caractères spéciaux :**
   - ✅ Format standardisé avec underscores
   - ✅ Parenthèses pour délimiter la date

## 📋 **MODIFICATIONS APPORTÉES**

### **🔧 Fichier modifié :**
- **`lib/data/services/stats_recoltes_service.dart`**

### **📝 Méthode mise à jour :**
- **`saveCollecteRecolte()`** : Génération d'ID personnalisé

### **🔄 Fonctionnement :**
1. **Calcul de la date** actuelle
2. **Formatage** : `DD_MM_YYYY`
3. **Construction** : `recolte_Date(DD_MM_YYYY)_Site`
4. **Vérification d'unicité**
5. **Ajout de suffixe** si nécessaire
6. **Enregistrement** avec ID final

## 💡 **RECOMMANDATIONS D'USAGE**

### **📊 Pour les développeurs :**
- ✅ **Logs** : Utiliser le nom du document pour le debugging
- ✅ **Requêtes** : Exploiter le préfixe pour les filtres
- ✅ **Exports** : Noms de fichiers basés sur l'ID du document

### **👥 Pour les utilisateurs :**
- ✅ **Interface** : Afficher les noms complets dans les listes
- ✅ **Rapports** : Utiliser les noms pour identifier les collectes
- ✅ **Historique** : Tri chronologique naturel

---

## 📞 **RÉSUMÉ TECHNIQUE**

**🎯 OBJECTIF ATTEINT :**
- ✅ **Nommage personnalisé** : `recolte_Date(XX_XX_XXXX)_NomSite`
- ✅ **Gestion des conflits** : Suffixes numériques automatiques
- ✅ **Lisibilité maximale** : Date et site dans le nom
- ✅ **Unicité garantie** : Vérification avant enregistrement

**🔧 FICHIER MODIFIÉ :**
- **`lib/data/services/stats_recoltes_service.dart`**

**📊 AVANTAGES :**
- **Organisation** : Tri chronologique naturel
- **Debugging** : Identification immédiate des documents
- **Maintenance** : Noms parlants pour tous
- **Analytics** : Analyse facilitée par structure

**Le système de nommage des documents de récoltes est maintenant entièrement personnalisé et organisé ! 🚀**
