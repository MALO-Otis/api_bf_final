# 🗃️ ENREGISTREMENT RÉCOLTE - BASE DE DONNÉES

## 📊 **ANALYSE COMPLÈTE DE L'ENREGISTREMENT EN BASE DE DONNÉES**

Voici **exactement** ce qui se passe quand on enregistre une récolte dans la base de données Firestore !

## 🏗️ **ARCHITECTURE DE LA BASE DE DONNÉES**

### **📁 Structure Firestore :**

```
Firestore (Database)
├── 📂 Collection: "{site}" (ex: "Koudougou", "Bobo", etc.)
│   └── 📄 Document: "collectes_recolte"
│       ├── 🔢 derniere_mise_a_jour: timestamp
│       ├── 🔢 total_collectes: number
│       └── 📂 Sous-collection: "collectes_recolte"
│           ├── 📄 Document: {auto-generated-id-1}
│           ├── 📄 Document: {auto-generated-id-2}
│           └── 📄 Document: {auto-generated-id-3}
│               ├── site: "Koudougou"
│               ├── region: "Centre-Ouest"
│               ├── province: "Boulkiemdé"
│               ├── commune: "Koudougou"
│               ├── village: "BAKARIDJAN"
│               ├── technicien_nom: "YAMEOGO Justin"
│               ├── technicien_uid: "abc123..."
│               ├── utilisateur_nom: "Jean OUEDRAOGO"
│               ├── utilisateur_email: "jean@apisavana.com"
│               ├── predominances_florales: ["Karité", "Néré"]
│               ├── contenants: [...]
│               ├── totalWeight: 25.5
│               ├── totalAmount: 63750
│               ├── status: "en_attente"
│               ├── createdAt: timestamp
│               └── updatedAt: timestamp
```

## 🚀 **PROCESSUS D'ENREGISTREMENT ÉTAPE PAR ÉTAPE**

### **📝 ÉTAPE 1 : VALIDATION DES DONNÉES**

```dart
void submitHarvest() async {
  // 🔍 Validation stricte avant enregistrement
  List<String> erreurs = [];

  if (containers.isEmpty) {
    erreurs.add('Ajoutez au moins un contenant');
  }
  if (selectedSite == null || selectedSite!.isEmpty) {
    erreurs.add('Sélectionnez un site');
  }
  if (selectedTechnician == null || selectedTechnician!.isEmpty) {
    erreurs.add('Sélectionnez un technicien');
  }
  // ... autres validations

  if (erreurs.isNotEmpty) {
    // ❌ Arrêt si erreurs détectées
    setState(() => statusMessage = erreurs.join(', '));
    return;
  }
```

### **📦 ÉTAPE 2 : PRÉPARATION DES DONNÉES**

```dart
// 🏗️ Construction de l'objet à enregistrer
final collecteData = {
  // 📍 INFORMATIONS GÉOGRAPHIQUES
  'site': selectedSite!,                    // "Koudougou"
  'region': selectedRegion!,                // "Centre-Ouest"
  'province': selectedProvince!,            // "Boulkiemdé"
  'commune': selectedCommune!,              // "Koudougou"
  'village': selectedVillage!,              // "BAKARIDJAN" OU village personnalisé

  // 👨‍💼 INFORMATIONS PERSONNEL
  'technicien_nom': selectedTechnician!,    // "YAMEOGO Justin"
  'technicien_uid': user.uid,               // ID Firebase du technicien connecté
  'utilisateur_nom': '${currentUserData!['prenom']} ${currentUserData!['nom']}',
  'utilisateur_email': currentUserData!['email'],

  // 🌸 PRÉDOMINANCES FLORALES
  'predominances_florales': selectedFlorales,  // ["Karité", "Néré", "Acacia"]

  // 📦 CONTENANTS (LISTE COMPLÈTE)
  'contenants': containers.map((c) => {
    'hiveType': c.hiveType,              // "Traditionnelle" | "Moderne"
    'containerType': c.containerType,    // "Sot" | "Fût" | "Bidon"
    'weight': c.weight,                  // 12.5 (kg)
    'unitPrice': c.unitPrice,            // 2500.0 (FCFA)
    'total': c.total,                    // 31250.0 (weight * unitPrice)
  }).toList(),

  // 💰 TOTAUX CALCULÉS
  'totalWeight': totalWeight,           // 25.5 (somme de tous les poids)
  'totalAmount': totalAmount,           // 63750.0 (somme de tous les montants)

  // 📋 MÉTADONNÉES
  'status': 'en_attente',               // Statut initial
  'createdAt': FieldValue.serverTimestamp(),    // Date de création
  'updatedAt': FieldValue.serverTimestamp(),    // Date de modification
};
```

### **💾 ÉTAPE 3 : ENREGISTREMENT FIRESTORE (2 OPÉRATIONS)**

#### **🏗️ Opération 1 : Ajout du document collecte**

```dart
// 📝 Enregistrement dans la sous-collection
final docRef = await FirebaseFirestore.instance
    .collection(selectedSite!)           // Ex: "Koudougou"
    .doc('collectes_recolte')           // Document parent
    .collection('collectes_recolte')    // Sous-collection
    .add(collecteData);                 // 🆕 Nouveau document avec ID auto-généré

// ✅ Résultat : Document créé avec un ID unique (ex: "abc123def456...")
```

#### **📊 Opération 2 : Mise à jour des statistiques**

```dart
// 🔄 Mise à jour du document parent pour les statistiques
await FirebaseFirestore.instance
    .collection(selectedSite!)          // Ex: "Koudougou"
    .doc('collectes_recolte')           // Document parent
    .set({
      'derniere_mise_a_jour': FieldValue.serverTimestamp(),  // 🕒 Timestamp actuel
      'total_collectes': FieldValue.increment(1),            // 🔢 +1 collecte
    }, SetOptions(merge: true));        // ✅ Fusion avec données existantes
```

## 📂 **COLLECTIONS ET DOCUMENTS CRÉÉS**

### **🎯 1. COLLECTION PRINCIPALE : `{site}`**

**Nom dynamique** selon le site sélectionné :
- `Koudougou` (si site = "Koudougou")
- `Bobo` (si site = "Bobo")
- `Mangodara` (si site = "Mangodara")
- `Po` (si site = "Po")
- Etc.

### **📄 2. DOCUMENT PARENT : `collectes_recolte`**

**Chemin :** `{site}/collectes_recolte`

**Contenu :**
```json
{
  "derniere_mise_a_jour": "2024-01-15T14:30:25.123Z",
  "total_collectes": 42
}
```

**Rôle :** 
- 📊 Statistiques globales du site
- 🕒 Suivi de la dernière activité
- 🔢 Compteur total des collectes

### **📂 3. SOUS-COLLECTION : `collectes_recolte`**

**Chemin :** `{site}/collectes_recolte/collectes_recolte`

**Contenu :** Documents individuels de chaque collecte

### **📄 4. DOCUMENTS COLLECTE INDIVIDUELS**

**Chemin :** `{site}/collectes_recolte/collectes_recolte/{auto-id}`

**Structure complète :**

```json
{
  // 📍 GÉOLOCALISATION
  "site": "Koudougou",
  "region": "Centre-Ouest", 
  "province": "Boulkiemdé",
  "commune": "Koudougou",
  "village": "BAKARIDJAN",

  // 👨‍💼 PERSONNEL
  "technicien_nom": "YAMEOGO Justin",
  "technicien_uid": "firebase-uid-123",
  "utilisateur_nom": "Jean OUEDRAOGO", 
  "utilisateur_email": "jean@apisavana.com",

  // 🌸 FLORE
  "predominances_florales": ["Karité", "Néré", "Acacia"],

  // 📦 CONTENANTS DÉTAILLÉS
  "contenants": [
    {
      "hiveType": "Traditionnelle",
      "containerType": "Fût", 
      "weight": 12.5,
      "unitPrice": 2500.0,
      "total": 31250.0
    },
    {
      "hiveType": "Moderne",
      "containerType": "Bidon",
      "weight": 13.0, 
      "unitPrice": 2500.0,
      "total": 32500.0
    }
  ],

  // 💰 TOTAUX
  "totalWeight": 25.5,
  "totalAmount": 63750.0,

  // 📋 MÉTADONNÉES  
  "status": "en_attente",
  "createdAt": "2024-01-15T14:30:25.123Z",
  "updatedAt": "2024-01-15T14:30:25.123Z"
}
```

## 🔧 **CHAMPS ET TYPES DE DONNÉES**

### **📊 TABLEAU COMPLET DES CHAMPS :**

| **Champ** | **Type** | **Exemple** | **Source** | **Obligatoire** |
|-----------|----------|-------------|------------|-----------------|
| **site** | String | "Koudougou" | selectedSite | ✅ |
| **region** | String | "Centre-Ouest" | selectedRegion | ✅ |
| **province** | String | "Boulkiemdé" | selectedProvince | ✅ |
| **commune** | String | "Koudougou" | selectedCommune | ✅ |
| **village** | String | "BAKARIDJAN" | selectedVillage / personnalisé | ✅ |
| **technicien_nom** | String | "YAMEOGO Justin" | selectedTechnician | ✅ |
| **technicien_uid** | String | "abc123..." | Firebase Auth | ✅ |
| **utilisateur_nom** | String | "Jean OUEDRAOGO" | Firestore utilisateur | ✅ |
| **utilisateur_email** | String | "jean@apisavana.com" | Firestore utilisateur | ✅ |
| **predominances_florales** | Array<String> | ["Karité", "Néré"] | selectedFlorales | ❌ |
| **contenants** | Array<Object> | [{...}, {...}] | containers | ✅ |
| **totalWeight** | Number | 25.5 | Calculé automatiquement | ✅ |
| **totalAmount** | Number | 63750.0 | Calculé automatiquement | ✅ |
| **status** | String | "en_attente" | Valeur fixe | ✅ |
| **createdAt** | Timestamp | 2024-01-15T14:30:25Z | FieldValue.serverTimestamp() | ✅ |
| **updatedAt** | Timestamp | 2024-01-15T14:30:25Z | FieldValue.serverTimestamp() | ✅ |

### **📦 STRUCTURE DES CONTENANTS :**

Chaque élément du tableau `contenants` :

| **Champ** | **Type** | **Valeurs possibles** | **Exemple** |
|-----------|----------|-----------------------|-------------|
| **hiveType** | String | "Traditionnelle" \| "Moderne" | "Traditionnelle" |
| **containerType** | String | "Sot" \| "Fût" \| "Bidon" | "Fût" |
| **weight** | Number | > 0 | 12.5 |
| **unitPrice** | Number | ≥ 0 (facultatif) | 2500.0 |
| **total** | Number | weight × unitPrice | 31250.0 |

## 🎯 **EXEMPLES CONCRETS D'ENREGISTREMENT**

### **🌾 Exemple 1 : Collecte Complète**

**Données saisies :**
- **Site :** Koudougou
- **Technicien :** YAMEOGO Justin  
- **Localisation :** Centre-Ouest > Boulkiemdé > Koudougou > BAKARIDJAN
- **Contenants :** 1 Fût Traditionnelle (12.5 kg à 2500 FCFA)
- **Florales :** Karité, Néré

**Collections créées/mises à jour :**

```
📂 Koudougou/
├── 📄 collectes_recolte
│   ├── derniere_mise_a_jour: 2024-01-15T14:30:25Z
│   └── total_collectes: 1
└── 📂 collectes_recolte/
    └── 📄 abc123def456...
        ├── site: "Koudougou"
        ├── region: "Centre-Ouest"
        ├── province: "Boulkiemdé" 
        ├── commune: "Koudougou"
        ├── village: "BAKARIDJAN"
        ├── technicien_nom: "YAMEOGO Justin"
        ├── contenants: [{"hiveType": "Traditionnelle", "containerType": "Fût", "weight": 12.5, "unitPrice": 2500.0, "total": 31250.0}]
        ├── totalWeight: 12.5
        ├── totalAmount: 31250.0
        └── status: "en_attente"
```

### **✍️ Exemple 2 : Collecte avec Village Personnalisé**

**Données saisies :**
- **Site :** Bobo
- **Technicien :** SANOU Sitelé
- **Localisation :** Hauts-Bassins > Houet > Bobo-Dioulasso > **Mon Village Perso**
- **Contenants :** 1 Bidon Moderne (15 kg, prix non défini)

**Collections créées/mises à jour :**

```
📂 Bobo/
├── 📄 collectes_recolte  
│   ├── derniere_mise_a_jour: 2024-01-15T15:45:10Z
│   └── total_collectes: 1
└── 📂 collectes_recolte/
    └── 📄 xyz789ghi012...
        ├── site: "Bobo"
        ├── region: "Hauts-Bassins"
        ├── province: "Houet"
        ├── commune: "Bobo-Dioulasso"
        ├── village: "Mon Village Perso"           # ✅ Village personnalisé
        ├── technicien_nom: "SANOU Sitelé"
        ├── contenants: [{"hiveType": "Moderne", "containerType": "Bidon", "weight": 15.0, "unitPrice": 0.0, "total": 0.0}]
        ├── totalWeight: 15.0
        ├── totalAmount: 0.0                       # ✅ Prix facultatif = 0
        └── status: "en_attente"
```

## 🔄 **FLUX COMPLET DE DONNÉES**

### **📊 Diagramme du processus :**

```
👨‍💻 Utilisateur saisit
    ↓
🔍 Validation formulaire
    ↓
🏗️ Construction collecteData  
    ↓
💾 Firestore.collection(site).doc('collectes_recolte').collection('collectes_recolte').add(data)
    ↓
📊 Firestore.collection(site).doc('collectes_recolte').set({stats}, merge: true)
    ↓  
📝 Ajout historique local (interface)
    ↓
🔄 Rechargement historique Firestore
    ↓
✅ Réinitialisation formulaire
```

## 🛡️ **SÉCURITÉ ET PERMISSIONS**

### **🔐 Authentification requise :**
- ✅ Utilisateur doit être connecté (`FirebaseAuth.instance.currentUser`)
- ✅ UID du technicien enregistré dans chaque collecte
- ✅ Email et nom de l'utilisateur tracés

### **📊 Isolation par site :**
- ✅ Chaque site a sa propre collection
- ✅ Pas de mélange entre sites
- ✅ Statistiques séparées par site

## 🎯 **AVANTAGES DE CETTE ARCHITECTURE**

### **⚡ Performance :**
- **Collections séparées** par site = requêtes plus rapides
- **Sous-collections** = organisation claire
- **Index automatiques** Firestore

### **📊 Scalabilité :**
- **Croissance illimitée** : chaque site peut avoir des milliers de collectes
- **Statistiques** mises à jour automatiquement
- **Historique complet** préservé

### **🔍 Traçabilité :**
- **Qui ?** : technicien_nom + technicien_uid + utilisateur_email
- **Quoi ?** : contenants détaillés + totaux
- **Où ?** : site + région + province + commune + village  
- **Quand ?** : createdAt + updatedAt
- **Combien ?** : poids + montant par contenant et total

### **🛠️ Maintenance :**
- **Structure claire** et documentée
- **Champs typés** et validés
- **Évolution possible** (ajout de champs)

---

## 📞 **RÉSUMÉ EXÉCUTIF**

**🗃️ QUE SE PASSE-T-IL EXACTEMENT ?**

1. **✅ Validation** des données saisies
2. **🏗️ Construction** d'un objet collecte complet
3. **💾 Enregistrement** dans `{site}/collectes_recolte/collectes_recolte/{auto-id}`
4. **📊 Mise à jour** des statistiques dans `{site}/collectes_recolte`
5. **📝 Ajout** à l'historique local de l'interface
6. **🔄 Rechargement** de l'historique depuis Firestore

**📂 COLLECTIONS CRÉÉES :**
- **1 collection** par site : `Koudougou`, `Bobo`, `Mangodara`, etc.
- **1 document** de stats par site : `collectes_recolte`
- **1 sous-collection** par site : `collectes_recolte` 
- **1 document** par collecte individuelle (ID auto-généré)

**🔢 CHAMPS STOCKÉS :**
- **16 champs** principaux + sous-objets contenants
- **Géolocalisation complète** : site → région → province → commune → village
- **Personnel** : technicien + utilisateur  
- **Contenants détaillés** : type ruche, type contenant, poids, prix
- **Métadonnées** : timestamps, statut, totaux

**Cette architecture assure une traçabilité complète, des performances optimales et une scalabilité maximale ! 🚀**
