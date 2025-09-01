# 📊 STATISTIQUES AVANCÉES RÉCOLTES

## 🎯 **IMPLÉMENTATION DE LA SOUS-COLLECTION `statistiques_avancees`**

Le système de statistiques avancées des récoltes a été **conservé et adapté** à la nouvelle architecture `Sites/{site}/nos_collectes_recoltes/`. 

## 🏗️ **ARCHITECTURE COMPLÈTE FINALE**

```
📂 Firestore Database
├── 📂 Collection: "Sites"
│   └── 📄 Document: "{site}" (ex: "Koudougou")
│       └── 📂 Sous-collection: "nos_collectes_recoltes"
│           ├── 📄 Document: {auto-id-1}              ← Collecte individuelle 1
│           ├── 📄 Document: {auto-id-2}              ← Collecte individuelle 2
│           ├── 📄 Document: {auto-id-3}              ← Collecte individuelle 3
│           └── 📄 Document: "statistiques_avancees"  ← ✅ STATS AVANCÉES
```

**Chemin complet :** `Sites/{site}/nos_collectes_recoltes/statistiques_avancees`

## 🔧 **SERVICE CRÉÉ : `StatsRecoltesService`**

### **📂 Fichier :** `lib/data/services/stats_recoltes_service.dart`

### **🎯 Fonctions principales :**

1. **`saveCollecteRecolte()`** : Enregistre une collecte + génère les stats
2. **`regenerateAdvancedStats()`** : Recalcule toutes les statistiques

## 📊 **STRUCTURE DU DOCUMENT `statistiques_avancees`**

### **🌍 1. TOTAUX GLOBAUX**
```json
{
  "totauxGlobaux": {
    "totalCollectes": 15,
    "totalPoids": 4040.0,
    "totalMontant": 4350000.0,
    "totalContenants": 42,
    "totalSots": 25,
    "totalFuts": 12,
    "totalBidons": 5,
    "floralesCumulees": ["KARITÉ", "MANGUIER", "NÉRÉ"],
    "regionsCouvertes": ["CENTRE-OUEST", "HAUTS-BASSINS"]
  }
}
```

### **📅 2. STATISTIQUES PAR MOIS**
```json
{
  "parMois": [
    {
      "mois": "2025-08",
      "totalCollectes": 8,
      "totalPoids": 2040.0,
      "totalMontant": 2175000.0,
      "totalContenants": 20,
      "totalSots": 12,
      "totalFuts": 6,
      "totalBidons": 2
    },
    {
      "mois": "2025-07",
      "totalCollectes": 7,
      "totalPoids": 2000.0,
      "totalMontant": 2175000.0,
      "totalContenants": 22,
      "totalSots": 13,
      "totalFuts": 6,
      "totalBidons": 3
    }
  ]
}
```

### **🌍 3. STATISTIQUES PAR RÉGION**
```json
{
  "regions": [
    {
      "nom": "CENTRE-OUEST",
      "totalCollectes": 12,
      "totalPoids": 3040.0,
      "totalMontant": 3350000.0,
      "totalContenants": 32,
      "provinces": ["BOULKIEMDÉ", "SANGUIÉ"],
      "floralesDominantes": ["KARITÉ", "MANGUIER"]
    },
    {
      "nom": "HAUTS-BASSINS", 
      "totalCollectes": 3,
      "totalPoids": 1000.0,
      "totalMontant": 1000000.0,
      "totalContenants": 10,
      "provinces": ["HOUET"],
      "floralesDominantes": ["NÉRÉ", "KARITÉ"]
    }
  ]
}
```

### **👨‍💼 4. STATISTIQUES PAR TECHNICIEN**
```json
{
  "techniciens": [
    {
      "nom": "Sitelé SANOU",
      "uid": "cHP9OBBGeBeiyzmt39we2oJ3fy82",
      "totalCollectes": 8,
      "totalPoids": 2540.0,
      "totalMontant": 2700000.0,
      "totalContenants": 26,
      "regionsDesservies": ["CENTRE-OUEST"],
      "collectes": [
        {
          "id": "F0t8XN0vxQHTR2Z6DfSJ",
          "date": "2025-08-28T08:02:10.679394",
          "poids": 4040.0,
          "montant": 4350000.0,
          "nombreContenants": 2,
          "region": "CENTRE-OUEST",
          "province": "BOULKIEMDÉ",
          "commune": "KOUDOUGOU",
          "village": "RAMONGO"
        }
      ]
    }
  ]
}
```

### **🕒 5. MÉTADONNÉES**
```json
{
  "derniereMAJ": "2025-08-28T08:02:13.000Z"
}
```

## 🔄 **PROCESSUS D'ENREGISTREMENT MODIFIÉ**

### **🔴 AVANT (Enregistrement simple) :**
```dart
final docRef = await FirebaseFirestore.instance
    .collection('Sites')
    .doc(selectedSite!)
    .collection('nos_collectes_recoltes')
    .add(collecteData);
```

### **🟢 APRÈS (Avec statistiques avancées) :**
```dart
final collecteId = await StatsRecoltesService.saveCollecteRecolte(
  site: selectedSite!,
  collecteData: collecteData,
);
```

## ⚡ **FONCTIONNEMENT DU SERVICE**

### **📝 1. Enregistrement d'une collecte :**
```dart
static Future<String> saveCollecteRecolte({
  required String site,
  required Map<String, dynamic> collecteData,
}) async {
  // 1. Enregistrer la collecte dans nos_collectes_recoltes
  final docRef = await _firestore
      .collection('Sites')
      .doc(site)
      .collection('nos_collectes_recoltes')
      .add(collecteData);

  // 2. Régénérer toutes les statistiques avancées
  await regenerateAdvancedStats(site);

  return docRef.id;
}
```

### **📊 2. Régénération des statistiques :**
```dart
static Future<void> regenerateAdvancedStats(String site) async {
  // 1. Charger toutes les collectes du site
  final collectesSnapshot = await _firestore
      .collection('Sites')
      .doc(site)
      .collection('nos_collectes_recoltes')
      .get();

  // 2. Calculer tous les totaux et statistiques
  // (voir code complet dans le service)

  // 3. Enregistrer dans statistiques_avancees
  await _firestore
      .collection('Sites')
      .doc(site)
      .collection('nos_collectes_recoltes')
      .doc('statistiques_avancees')
      .set(statistiques);
}
```

## 📈 **DONNÉES CALCULÉES AUTOMATIQUEMENT**

### **🎯 Par collecte :**
- ✅ **Totaux** : poids, montant, nombre de contenants
- ✅ **Répartition contenants** : Sots, Fûts, Bidons
- ✅ **Géolocalisation** : région, province, commune, village
- ✅ **Technicien** : nom, UID, historique

### **📊 Agrégations :**
- ✅ **Par mois** : évolution temporelle
- ✅ **Par région** : couverture géographique + provinces
- ✅ **Par technicien** : performance individuelle + historique
- ✅ **Globales** : totaux du site entier

### **🌸 Analytics spécialisées :**
- ✅ **Prédominances florales** cumulées par région
- ✅ **Régions couvertes** par le site
- ✅ **Évolution mensuelle** complète
- ✅ **Performance techniciens** avec détails

## 🔍 **EXEMPLE DE GÉNÉRATION AUTOMATIQUE**

### **📝 Nouvelle collecte enregistrée :**
```json
{
  "site": "Koudougou",
  "region": "CENTRE-OUEST",
  "province": "BOULKIEMDÉ", 
  "commune": "KOUDOUGOU",
  "village": "RAMONGO",
  "technicien_nom": "Sitelé SANOU",
  "technicien_uid": "cHP9OBBGeBeiyzmt39we2oJ3fy82",
  "predominances_florales": ["MANGUIER"],
  "contenants": [
    {"containerType": "Sot", "weight": 2020, "unitPrice": 1000, "total": 2020000},
    {"containerType": "Fût", "weight": 2020, "unitPrice": 1150, "total": 2323000}
  ],
  "totalWeight": 4040,
  "totalAmount": 4343000,
  "createdAt": "2025-08-28T08:02:10.679Z"
}
```

### **📊 Mise à jour automatique des stats :**

1. **Totaux globaux** : +1 collecte, +4040kg, +4343000 FCFA
2. **Mois 2025-08** : +1 collecte, +1 Sot, +1 Fût
3. **Région CENTRE-OUEST** : +1 collecte, +BOULKIEMDÉ province, +MANGUIER florale
4. **Technicien Sitelé** : +1 collecte, +CENTRE-OUEST région, +détails collecte

## ✅ **AVANTAGES DE CETTE IMPLÉMENTATION**

### **📊 Business Intelligence :**
- ✅ **Tableaux de bord** automatiques par site
- ✅ **Évolution temporelle** des collectes
- ✅ **Performance techniciens** détaillée
- ✅ **Couverture géographique** complète

### **🚀 Performance :**
- ✅ **Statistiques pré-calculées** (pas de requêtes lourdes)
- ✅ **Mise à jour automatique** à chaque collecte
- ✅ **Données toujours cohérentes**

### **🔧 Maintenance :**
- ✅ **Service centralisé** pour toute la logique
- ✅ **Recalcul complet** si besoin de correction
- ✅ **Structure identique** à l'ancien système

## 🧪 **TESTS RECOMMANDÉS**

### **✅ Tests fonctionnels :**
1. **Créer une collecte** et vérifier la génération des stats
2. **Vérifier les totaux** dans `statistiques_avancees`
3. **Contrôler les agrégations** par mois/région/technicien
4. **Tester plusieurs collectes** du même technicien

### **🔍 Tests de données :**
1. **Structure du document** `statistiques_avancees`
2. **Cohérence des totaux** avec les collectes individuelles
3. **Tri des données** (mois desc, régions/techniciens asc)
4. **Gestion des cas vides** (pas de collectes)

---

## 📞 **RÉSUMÉ TECHNIQUE**

**🎯 OBJECTIF ATTEINT :**
- ✅ **Conservation** de la sous-collection `statistiques_avancees`
- ✅ **Adaptation** à la nouvelle architecture `Sites/{site}/nos_collectes_recoltes/`
- ✅ **Structure identique** à l'ancien système
- ✅ **Génération automatique** à chaque enregistrement

**🔧 FICHIERS MODIFIÉS :**
- **Service créé :** `lib/data/services/stats_recoltes_service.dart`
- **Module modifié :** `lib/screens/collecte_de_donnes/nos_collecte_recoltes/nouvelle_collecte_recolte.dart`

**📊 DOCUMENT GÉNÉRÉ :**
- **Chemin :** `Sites/{site}/nos_collectes_recoltes/statistiques_avancees`
- **Contenu :** Totaux globaux + parMois + regions + techniciens + derniereMAJ

**Le système de statistiques avancées des récoltes est maintenant pleinement fonctionnel dans la nouvelle architecture ! 🚀**
