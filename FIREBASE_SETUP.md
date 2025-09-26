# 🔥 Configuration Firebase pour Apisavana

## 📊 Index Firestore Requis

L'application nécessite plusieurs index composites pour fonctionner correctement.

### 🚀 Déploiement Automatique des Index

1. **Installer Firebase CLI** (si pas déjà fait) :
   ```bash
   npm install -g firebase-tools
   ```

2. **Se connecter à Firebase** :
   ```bash
   firebase login
   ```

3. **Initialiser le projet** (si pas déjà fait) :
   ```bash
   firebase init firestore
   ```

4. **Déployer les index** :
   ```bash
   firebase deploy --only firestore:indexes
   ```

### 🔗 Création Manuelle via Console Firebase

Si vous préférez créer les index manuellement, voici les liens directs générés par les erreurs :

1. **Index pour conditionnement (site + date)** :
   - Aller sur : https://console.firebase.google.com/project/apisavana-bf-226/firestore/indexes
   - Créer un index composite sur la collection `conditionnement` :
     - Champ 1 : `site` (Ascending)
     - Champ 2 : `date` (Descending)

2. **Index pour filtrage (statutFiltrage + site + dateFiltrage)** :
   - Collection : `filtrage`
   - Champs :
     - `statutFiltrage` (Ascending)
     - `site` (Ascending) 
     - `dateFiltrage` (Descending)

3. **Index pour ventes (commercialId + dateVente)** :
   - Collection : `ventes`
   - Champs :
     - `commercialId` (Ascending)
     - `dateVente` (Descending)

4. **Index pour prélèvements (commercialId + datePrelevement)** :
   - Collection : `prelevements`
   - Champs :
     - `commercialId` (Ascending)
     - `datePrelevement` (Descending)

5. **Index pour restitutions (commercialId + dateRestitution)** :
   - Collection : `restitutions`
   - Champs :
     - `commercialId` (Ascending)
     - `dateRestitution` (Descending)

6. **Index pour pertes (commercialId + datePerte)** :
   - Collection : `pertes`
   - Champs :
     - `commercialId` (Ascending)
     - `datePerte` (Descending)

### ⏱️ Temps de Création

- Les index peuvent prendre plusieurs minutes à être créés
- Vous pouvez suivre le progrès dans la console Firebase
- L'application fonctionnera normalement une fois tous les index créés

### 🔍 Vérification

Pour vérifier que les index sont bien créés :

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner votre projet `apisavana-bf-226`
3. Aller dans **Firestore Database** > **Index**
4. Vérifier que tous les index sont en statut "Enabled"

### 🐛 Résolution des Erreurs

Si vous voyez encore des erreurs d'index manquant :

1. Copier le lien d'erreur depuis les logs Flutter
2. Cliquer sur le lien pour créer automatiquement l'index
3. Attendre la création (peut prendre 5-10 minutes)
4. Relancer l'application

## 📱 Test de l'Application

Une fois tous les index créés, vous pouvez :

1. Relancer l'application Flutter
2. Naviguer vers le module **Conditionnement**
3. Vérifier que les données se chargent sans erreur
4. Tester les modules **Vente**, **Restitution** et **Perte**

## 🆘 Support

En cas de problème avec les index Firebase :

1. Vérifier les logs Firebase dans la console
2. S'assurer que tous les index sont "Enabled"
3. Redémarrer l'application Flutter
4. Contacter l'équipe de développement si le problème persiste
