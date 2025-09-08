# 🚀 Guide de Déploiement Apisavana

## 📱 Application Flutter de Gestion Apicole

### 🌐 Déploiement Web (Vercel/Netlify)

#### Prérequis
- Build web inclus dans le repository
- Configuration Vercel/Netlify prête

#### Déploiement sur Vercel

1. **Connecter le Repository**
   ```bash
   # Cloner le repository
   git clone [URL_DU_REPO]
   cd apisavana_gestion
   ```

2. **Configuration Vercel**
   - Fichier `vercel.json` inclus
   - Build directory: `build/web`
   - Output directory: `build/web`

3. **Variables d'Environnement**
   ```
   FLUTTER_WEB=true
   NODE_ENV=production
   ```

4. **Déploiement Automatique**
   - Push sur main → déploiement automatique
   - Preview pour les branches de développement

#### Déploiement sur Netlify

1. **Configuration Build**
   ```
   Build command: flutter build web --release
   Publish directory: build/web
   ```

2. **Redirections (_redirects)**
   ```
   /*    /index.html   200
   ```

### 🔥 Configuration Firebase

#### Index Firestore Requis
```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Se connecter
firebase login

# Déployer les index
firebase deploy --only firestore:indexes
```

#### Collections Principales
- `collecte` - Données de collecte
- `controle` - Contrôle qualité
- `extraction` - Processus d'extraction
- `filtrage` - Filtrage des produits
- `conditionnement` - Conditionnement
- `ventes` - Gestion des ventes
- `prelevements` - Prélèvements commerciaux
- `restitutions` - Restitutions produits
- `pertes` - Déclarations de pertes

### 📊 Modules Disponibles

#### ✅ Modules Opérationnels
- **Collecte** : Gestion des collectes de miel
- **Contrôle** : Contrôle qualité des produits
- **Extraction** : Processus d'extraction
- **Filtrage** : Filtrage et traçabilité
- **Conditionnement** : Mise en emballages
- **Gestion de Vente** : Ventes, restitutions, pertes

#### 🎯 Fonctionnalités Clés
- **Interface responsive** : Mobile et desktop
- **Authentification** : Firebase Auth
- **Temps réel** : Synchronisation Firestore
- **Traçabilité complète** : Du producteur au consommateur
- **Gestion des rôles** : Admin, Magazinier, Commercial
- **Statistiques avancées** : Tableaux de bord complets

### 🛠️ Développement Local

#### Installation
```bash
# Cloner le repository
git clone [URL_DU_REPO]
cd apisavana_gestion

# Installer les dépendances
flutter pub get

# Lancer en mode développement
flutter run -d chrome
```

#### Build Local
```bash
# Build web
flutter build web --release

# Build Android
flutter build apk --release

# Build Windows
flutter build windows --release
```

### 🔧 Maintenance

#### Mise à jour des Dépendances
```bash
flutter pub upgrade
flutter pub get
```

#### Correction des Erreurs
- Logs disponibles dans Firebase Console
- Debug via Flutter DevTools
- Monitoring des performances

### 📈 Performance

#### Optimisations Incluses
- **Lazy loading** des modules
- **Cache Firestore** pour les données fréquentes
- **Compression** des assets web
- **Service Worker** pour le cache offline

#### Métriques de Performance
- **Temps de chargement** : < 3s
- **First Contentful Paint** : < 1.5s
- **Lighthouse Score** : > 90

### 🆘 Support

#### Problèmes Courants
1. **Erreurs d'index Firebase** → Déployer `firestore.indexes.json`
2. **Problèmes de build** → Vérifier `TROUBLESHOOTING_WINDOWS.md`
3. **Erreurs de permissions** → Vérifier les règles Firestore

#### Documentation
- `FIREBASE_SETUP.md` - Configuration Firebase
- `TROUBLESHOOTING_WINDOWS.md` - Résolution problèmes
- `CORRECTIONS_CONDITIONNEMENT.md` - Corrections modules

### 🎉 Version Actuelle

**Version** : 2.0.0  
**Date** : Janvier 2025  
**Statut** : Production Ready ✅

#### Nouvelles Fonctionnalités
- Module de gestion de vente complet
- Formulaires de vente, restitution, perte
- Interface admin et commercial
- Traçabilité améliorée
- Corrections de stabilité

#### Prochaines Versions
- Module de rapports avancés
- API mobile native
- Intégration comptabilité
- Notifications push
