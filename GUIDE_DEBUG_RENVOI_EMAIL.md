# 🔧 Guide de Débogage - Renvoi d'Email

## 🚨 Problème Identifié
**Symptôme** : Clic sur "Renvoyer l'email" → Rien ne se passe, aucun email reçu

## 🔍 Corrections Apportées

### ✅ **1. Logs de Débogage Ajoutés**
Des messages de débogage ont été ajoutés pour tracer exactement ce qui se passe :

```dart
// Dans sign_up.dart
print('🔄 Tentative de renvoi d\'email...');
print('📧 Renvoi d\'email à: ${currentUser.email}');
print('✅ Email de vérification renvoyé avec succès');

// Dans login.dart  
print('🔄 [LOGIN] Tentative de renvoi d\'email...');
print('📧 [LOGIN] Email utilisateur: ${user.email}');
print('✅ [LOGIN] Email de vérification renvoyé avec succès');
```

### ✅ **2. Vérification de l'Utilisateur Connecté**
Ajout d'une vérification pour s'assurer qu'un utilisateur est connecté :

```dart
final currentUser = FirebaseAuth.instance.currentUser;
if (currentUser == null) {
  print('❌ Aucun utilisateur connecté pour renvoyer l\'email');
  // Message d'erreur à l'utilisateur
  return;
}
```

### ✅ **3. Gestion d'Erreurs Améliorée**
Messages d'erreur plus détaillés avec l'erreur exacte :

```dart
} catch (e) {
  print('❌ Erreur lors du renvoi d\'email: $e');
  Get.snackbar('Erreur', 'Impossible de renvoyer l\'email: ${e.toString()}');
}
```

## 🧪 Tests à Effectuer

### **Test 1 : Vérifier les Logs Console**

1. **Ouvrir la console** de votre IDE/navigateur
2. **Créer un compte** → Regarder les logs lors de la création
3. **Cliquer "Renvoyer"** → Observer les messages qui s'affichent

**Messages attendus** :
```
📧 Email de vérification envoyé à: user@example.com
🔄 Tentative de renvoi d'email...
📧 Renvoi d'email à: user@example.com
✅ Email de vérification renvoyé avec succès
```

**Si vous voyez** :
- `❌ Aucun utilisateur connecté` → **Problème d'authentification**
- `❌ Erreur lors du renvoi d'email: [erreur]` → **Problème Firebase**

### **Test 2 : Vérifier la Configuration Firebase**

1. **Console Firebase** → Aller sur console.firebase.google.com
2. **Authentication** → Templates d'email
3. **Vérifier** que l'email de vérification est activé
4. **Tester** l'envoi depuis la console Firebase

### **Test 3 : Vérifier les Limitations**

Firebase impose des **limitations sur l'envoi d'emails** :
- **1 email par minute** par utilisateur
- **Limite quotidienne** par projet
- **Domaines autorisés** seulement

## 🔧 Solutions Possibles

### **Solution 1 : Problème d'Utilisateur Déconnecté**

Si les logs montrent "Aucun utilisateur connecté" :

```dart
// Le problème : l'utilisateur est déconnecté après création
// Solution : Maintenir la connexion ou re-authentifier
```

**Test** : Essayez de vous reconnecter puis cliquer "Renvoyer"

### **Solution 2 : Problème de Configuration Firebase**

Vérifiez dans Firebase Console :
1. **Authentication** → Settings → Authorized domains
2. **Authentication** → Templates → Email verification
3. **Project Settings** → General → Support email

### **Solution 3 : Problème de Limite de Débit**

Firebase limite l'envoi d'emails :
- **Attendre 1 minute** entre chaque renvoi
- **Vérifier les quotas** dans la console Firebase

### **Solution 4 : Problème de Boîte Mail**

- **Vérifier les spams** / courriers indésirables
- **Whitelist Firebase** : `noreply@[votre-projet].firebaseapp.com`
- **Tester avec un autre email** (Gmail, Yahoo)

## 🚀 Solution Alternative : Renvoi Manuel

Si le problème persiste, voici une solution alternative :

```dart
// Bouton alternatif pour renvoi manuel
ElevatedButton(
  onPressed: () async {
    try {
      // Forcer la reconnexion
      await FirebaseAuth.instance.signOut();
      
      // Se reconnecter avec les mêmes identifiants
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userEmail,
        password: 'mot-de-passe-temporaire', // À adapter
      );
      
      // Renvoyer l'email
      await userCred.user!.sendEmailVerification();
      
      // Déconnecter à nouveau
      await FirebaseAuth.instance.signOut();
      
      Get.snackbar('Succès', 'Email renvoyé avec succès');
    } catch (e) {
      Get.snackbar('Erreur', 'Problème: $e');
    }
  },
  child: Text('Renvoi forcé'),
)
```

## 📋 Checklist de Débogage

### Étape 1 : Logs
- [ ] **Console ouverte** et visible
- [ ] **Messages de débogage** s'affichent lors du clic
- [ ] **Pas d'erreurs** dans la console

### Étape 2 : Firebase
- [ ] **Configuration correcte** dans Firebase Console
- [ ] **Email verification activé** dans Authentication
- [ ] **Domaine autorisé** ajouté
- [ ] **Support email configuré**

### Étape 3 : Tests
- [ ] **Attendre 1 minute** entre chaque tentative
- [ ] **Tester avec différents emails** (Gmail, Yahoo, etc.)
- [ ] **Vérifier les spams** systématiquement
- [ ] **Tester depuis un autre appareil/navigateur**

### Étape 4 : Alternative
- [ ] **Solution de renvoi manuel** testée
- [ ] **Re-authentification** avant renvoi
- [ ] **Vérification du statut utilisateur**

## 🆘 Si Rien ne Fonctionne

1. **Créer un nouveau projet Firebase** pour tester
2. **Utiliser un service d'email externe** (SendGrid, Mailgun)
3. **Implémenter un système de renvoi côté serveur**
4. **Contacter le support Firebase** pour vérifier les quotas

## 📞 Prochaines Étapes

1. **Testez avec les logs** activés
2. **Partagez les messages** de la console
3. **Vérifiez la configuration** Firebase
4. **Essayez la solution alternative** si nécessaire

---

*Guide de débogage - ApiSavana Gestion*
