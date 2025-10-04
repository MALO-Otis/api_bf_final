# Guide de Déploiement

## Vercel - Configuration Flutter Web

### 1. Configuration automatique
Le fichier `vercel.json` est configuré pour Flutter Web avec :
- Build automatique depuis `build/web/`
- Rewrites pour le routing Flutter
- Headers de cache optimisés

### 2. Déploiement sur Vercel
1. Connecter le repository GitHub à Vercel
2. Vercel détectera automatiquement la configuration
3. Le déploiement se fera automatiquement à chaque push

### 3. Variables d'environnement (si nécessaire)
Si vous utilisez des variables d'environnement, les ajouter dans les settings Vercel :
- `FLUTTER_WEB_CANVASKIT_URL`
- Autres variables Firebase si nécessaire

### 4. Résolution des erreurs communes
- **Erreur "routes cannot be present"** : ✅ Corrigée - utilisation de `rewrites` uniquement
- **404 sur les routes** : ✅ Résolu avec rewrites vers `/index.html`

## Firebase
```bash
firebase deploy --only firestore:indexes
```

## Structure des fichiers de déploiement
- `vercel.json` : Configuration Vercel (✅ corrigée)
- `build/web/` : Build Flutter Web (✅ inclus)
- `firestore.indexes.json` : Index Firebase (✅ inclus)

## Vérification du déploiement
1. Build local : `flutter build web --release`
2. Test local : Servir `build/web/` avec un serveur HTTP
3. Push vers GitHub
4. Vérifier le déploiement Vercel