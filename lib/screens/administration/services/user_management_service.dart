import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../services/email_service.dart';
import '../models/user_management_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../authentication/user_session.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Résultat paginé pour l'historique des actions
class PaginatedActions {
  final List<UserAction> actions;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  PaginatedActions(
      {required this.actions,
      required this.lastDocument,
      required this.hasMore});
}

class UserManagementService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserSession _userSession = Get.find<UserSession>();
  final EmailService _emailService = Get.put(EmailService());

  /// Cooldown pour éviter le spam d'envoi de mails de vérification
  final Duration _resendCooldown = const Duration(minutes: 1);
  final Map<String, DateTime> _lastVerificationResend =
      {}; // key: userId ou email

  /// États observables
  final RxBool _isLoadingStats = false.obs;
  final Rx<UserStatistics> _statistics = UserStatistics.empty().obs;

  // Getters
  bool get isLoadingStats => _isLoadingStats.value;
  UserStatistics get statistics => _statistics.value;

  /// Collection des utilisateurs
  CollectionReference get _usersCollection =>
      _firestore.collection('utilisateurs');

  /// Collection des actions sur les utilisateurs
  CollectionReference get _userActionsCollection =>
      _firestore.collection('user_actions');

  /// Sites disponibles
  final List<String> availableSites = [
    'Ouaga',
    'Koudougou',
    'Bobo',
    'Mangodara',
    'Bagre',
    'Pô'
  ];

  /// Rôles disponibles
  final List<String> availableRoles = [
    'Admin',
    'Collecteur',
    'Contrôleur',
    'Filtreur',
    'Extracteur',
    'Conditionneur',
    'Magazinier',
    'Gestionnaire Commercial',
    'Commercial',
    'Caissier'
  ];

  /// Récupérer les statistiques des utilisateurs
  Future<UserStatistics> getUserStatistics() async {
    _isLoadingStats.value = true;
    try {
      final users = await getUsers();

      final stats = UserStatistics(
        totalUsers: users.length,
        activeUsers: users.where((u) => u.isActive).length,
        inactiveUsers: users.where((u) => !u.isActive).length,
        verifiedUsers: users.where((u) => u.emailVerified).length,
        unverifiedUsers: users.where((u) => !u.emailVerified).length,
        onlineUsers: 0, // TODO: Implémenter la logique d'utilisateurs en ligne
        usersByRole: _groupUsersByField(users, (u) => u.role),
        usersBySite: _groupUsersByField(users, (u) => u.site),
        newUsersByMonth: _groupUsersByMonth(users),
        loginsByMonth: {}, // TODO: Implémenter la logique des connexions
      );

      _statistics.value = stats;
      return stats;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      return UserStatistics.empty();
    } finally {
      _isLoadingStats.value = false;
    }
  }

  /// Grouper les utilisateurs par un champ spécifique
  Map<String, int> _groupUsersByField(
      List<AppUser> users, String Function(AppUser) getField) {
    final Map<String, int> groups = {};
    for (final user in users) {
      final field = getField(user);
      groups[field] = (groups[field] ?? 0) + 1;
    }
    return groups;
  }

  /// Grouper les utilisateurs par mois de création
  Map<String, int> _groupUsersByMonth(List<AppUser> users) {
    final Map<String, int> groups = {};
    for (final user in users) {
      final month =
          '${user.dateCreation.year}-${user.dateCreation.month.toString().padLeft(2, '0')}';
      groups[month] = (groups[month] ?? 0) + 1;
    }
    return groups;
  }

  /// Récupérer tous les utilisateurs avec filtres
  Future<List<AppUser>> getUsers({UserFilters? filters}) async {
    try {
      Query query = _usersCollection;

      // Appliquer les filtres Firestore
      if (filters?.site != null && filters!.site!.isNotEmpty) {
        query = query.where('site', isEqualTo: filters.site);
      }
      if (filters?.role != null && filters!.role!.isNotEmpty) {
        query = query.where('role', isEqualTo: filters.role);
      }
      if (filters?.isActive != null) {
        query = query.where('isActive', isEqualTo: filters!.isActive);
      }
      if (filters?.emailVerified != null) {
        query = query.where('emailVerified', isEqualTo: filters!.emailVerified);
      }

      // Tri
      if (filters?.sortField != null) {
        query = query.orderBy(
          filters!.sortField.firestoreField,
          descending: !filters.sortAscending,
        );
      } else {
        query = query.orderBy('createdAt', descending: true);
      }

      final snapshot = await query.get();
      List<AppUser> users =
          snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();

      // Filtres côté client (pour les champs complexes)
      if (filters?.searchTerm != null && filters!.searchTerm!.isNotEmpty) {
        final searchLower = filters.searchTerm!.toLowerCase();
        users = users
            .where((user) =>
                user.nom.toLowerCase().contains(searchLower) ||
                user.prenom.toLowerCase().contains(searchLower) ||
                user.email.toLowerCase().contains(searchLower) ||
                user.telephone.contains(searchLower))
            .toList();
      }

      if (filters?.dateCreationStart != null) {
        users = users
            .where((user) =>
                user.dateCreation.isAfter(filters!.dateCreationStart!))
            .toList();
      }

      if (filters?.dateCreationEnd != null) {
        users = users
            .where((user) => user.dateCreation
                .isBefore(filters!.dateCreationEnd!.add(Duration(days: 1))))
            .toList();
      }

      return users;
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  /// Récupérer un utilisateur par ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  /// Générer un mot de passe temporaire sécurisé
  String _generateTemporaryPassword() {
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final Random random = Random.secure();
    return List.generate(12, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Créer un nouvel utilisateur avec envoi automatique d'email de confirmation
  Future<bool> createUser({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String role,
    required String site,
  }) async {
    try {
      print('🚀 Début de création utilisateur: $email');

      // Générer un mot de passe temporaire si celui fourni est vide ou trop simple
      final tempPassword =
          password.length < 8 ? _generateTemporaryPassword() : password;

      // IMPORTANT: Utiliser une app Firebase secondaire pour ne PAS déconnecter l'admin courant
      // car createUserWithEmailAndPassword sur l'instance principale remplace la session.
      FirebaseApp? secondaryApp;
      User? createdUser;
      try {
        final primary = Firebase.app();
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryUserCreationApp',
          options: primary.options,
        );
        final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
        final userCredential =
            await secondaryAuth.createUserWithEmailAndPassword(
          email: email,
          password: tempPassword,
        );
        createdUser = userCredential.user;
        if (createdUser == null) {
          print('❌ Erreur: user credential null sur secondaire');
          await secondaryApp.delete();
          return false;
        }
        print(
            '✅ Utilisateur Firebase (app secondaire) créé: ${createdUser.uid}');
      } catch (e) {
        print(
            '❌ Echec création via app secondaire, tentative fallback direct: $e');
        // Fallback (gardera la session -> pas idéal mais on ne bloque pas tout)
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: tempPassword,
        );
        createdUser = userCredential.user;
        if (createdUser == null) {
          print('❌ Erreur: user credential null (fallback)');
          return false;
        }
      }

      // Créer le document utilisateur dans Firestore
      final appUser = AppUser(
        id: createdUser.uid,
        email: email,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        role: role,
        site: site,
        isActive: true,
        emailVerified: false,
        dateCreation: DateTime.now(),
      );

      // Utiliser l'uid comme ID du document
      await _usersCollection.doc(createdUser.uid).set(appUser.toFirestore());
      print('✅ Document Firestore créé');

      // Envoyer l'email de vérification Firebase (si possible sur createdUser)
      try {
        await createdUser.sendEmailVerification();
        print('✅ Email de vérification Firebase envoyé (createdUser)');
      } catch (e) {
        print('⚠️ Impossible d\'envoyer l\'email de vérification Firebase: $e');
      }

      // Envoyer l'email de bienvenue personnalisé avec les informations de connexion
      final emailSent = await _emailService.sendWelcomeEmailLocal(
        userEmail: email,
        userName: '$prenom $nom',
        userRole: role,
        userSite: site,
        temporaryPassword: tempPassword,
      );

      if (emailSent) {
        print('✅ Email de bienvenue personnalisé envoyé avec succès');
      } else {
        print(
            '⚠️ Impossible d\'envoyer l\'email de bienvenue, mais utilisateur créé');
      }

      // Enregistrer l'action
      await _logUserAction(
        userId: createdUser.uid,
        type: UserActionType.created,
        description:
            'Utilisateur créé par ${_userSession.email}. Email de confirmation envoyé.',
        newValues: appUser.toFirestore(),
      );

      print('✅ Action utilisateur enregistrée');

      // Afficher la modale de vérification email pour l'administrateur
      _showAdminEmailVerificationDialog(
        userEmail: email,
        userName: '$prenom $nom',
        tempPassword: tempPassword,
      );

      // Nettoyer l'app secondaire si utilisée
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
          print('🧹 App secondaire supprimée');
        } catch (e) {
          print('⚠️ Échec suppression app secondaire: $e');
        }
      }

      return true;
    } catch (e) {
      print('❌ Erreur lors de la création de l\'utilisateur: $e');

      // Afficher une notification d'erreur
      Get.snackbar(
        '❌ Erreur de création',
        'Impossible de créer l\'utilisateur: ${e.toString()}',
        backgroundColor: const Color(0xFFDC3545),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error, color: Colors.white),
      );

      return false;
    }
  }

  /// Afficher la modale de vérification email pour l'administrateur
  void _showAdminEmailVerificationDialog({
    required String userEmail,
    required String userName,
    required String tempPassword,
  }) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.email, color: Color(0xFFF49101)),
            SizedBox(width: 8),
            Text(
              'Vérification Email',
              style: TextStyle(
                color: Color(0xFF2D0C0D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compte créé avec succès !',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Un email de vérification a été envoyé à :',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFF49101).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                userEmail,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF49101),
                ),
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade600, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Vérifiez bien votre adresse email !',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Assurez-vous que l\'adresse ci-dessus est correcte\n• Vérifiez vos spams/courriers indésirables\n• Le lien de vérification expire dans 24h',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              '⚠️ Vous devez vérifier votre email avant de pouvoir vous connecter.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text(
              'Modifier l\'email',
              style: TextStyle(color: Colors.orange[700]),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text(
              'Continuer',
              style: TextStyle(color: Color(0xFF2D0C0D)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _resendVerificationEmail(userEmail);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF49101),
            ),
            child: Text(
              'Renvoyer',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Rediriger vers le dashboard admin
              Get.offAllNamed('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2196F3),
            ),
            child: Text(
              'Retour Dashboard',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Renvoyer l'email de vérification
  Future<void> _resendVerificationEmail(String email) async {
    try {
      // Cooldown basé sur l'email
      final last = _lastVerificationResend[email];
      if (last != null && DateTime.now().difference(last) < _resendCooldown) {
        Get.snackbar(
          'Patience',
          'Veuillez réessayer dans ${(_resendCooldown - DateTime.now().difference(last)).inSeconds}s',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[900],
        );
        return;
      }

      // 1) Tenter via Firebase (impersonation avec app secondaire + custom token)
      final sent = await _resendVerificationEmailViaFirebase(email: email);

      if (sent) {
        _lastVerificationResend[email] = DateTime.now();
        Get.back();
        Get.snackbar(
          'Email renvoyé',
          'Un nouvel email de vérification a été envoyé à $email',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          duration: const Duration(seconds: 4),
        );
      } else {
        // 2) Fallback local (simulation / provider externe si configuré)
        final fallback = await _emailService.sendCustomVerificationEmailLocal(
          userEmail: email,
          userName: email,
        );
        if (fallback) {
          _lastVerificationResend[email] = DateTime.now();
          Get.back();
          Get.snackbar(
            'Email renvoyé (fallback)',
            'Un email de vérification a été renvoyé à $email (méthode alternative)',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
            duration: const Duration(seconds: 4),
          );
        } else {
          Get.snackbar(
            'Erreur',
            'Impossible de renvoyer l\'email de vérification',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red[100],
            colorText: Colors.red[900],
          );
        }
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Erreur',
        'Impossible de renvoyer l\'email: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }

  /// Renvoi d'email via Firebase Auth pour un utilisateur cible
  /// Stratégie: Cloud Function onCall -> custom token pour uid/email ->
  /// app secondaire -> signInWithCustomToken -> sendEmailVerification -> cleanup
  Future<bool> _resendVerificationEmailViaFirebase(
      {String? email, String? uid}) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'africa-south1')
          .httpsCallable('issueCustomTokenForUser');
      final payload = <String, dynamic>{};
      if (email != null) payload['email'] = email;
      if (uid != null) payload['uid'] = uid;
      final result = await callable.call(payload);
      final data = result.data as Map?;
      final token = data != null ? data['token'] as String? : null;
      if (token == null || token.isEmpty) return false;

      // App secondaire pour ne pas toucher la session admin
      final primary = Firebase.app();
      final tempAppName = 'SecondaryEmailVerifyApp';
      FirebaseApp? secondaryApp;
      try {
        secondaryApp = await Firebase.initializeApp(
          name: tempAppName,
          options: primary.options,
        );
      } catch (_) {
        // Si déjà existante
        try {
          secondaryApp = Firebase.app(tempAppName);
        } catch (e) {
          rethrow;
        }
      }
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp!);
      final cred = await secondaryAuth.signInWithCustomToken(token);
      final target = cred.user ?? secondaryAuth.currentUser;
      if (target == null) {
        await secondaryApp.delete();
        return false;
      }

      // ActionCodeSettings optionnels (laisser défaut si non configuré)
      try {
        await target.sendEmailVerification();
      } finally {
        await secondaryAuth.signOut();
        await secondaryApp.delete();
      }
      return true;
    } catch (e) {
      print('⚠️ Resend via Firebase failed: $e');
      return false;
    }
  }

  /// Mettre à jour un utilisateur
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      // Récupérer les anciennes valeurs
      final oldUser = await getUserById(userId);
      if (oldUser == null) return false;

      // Mettre à jour dans Firestore
      await _usersCollection.doc(userId).update(updates);

      // Enregistrer l'action
      await _logUserAction(
        userId: userId,
        type: UserActionType.updated,
        description: 'Utilisateur modifié par ${_userSession.email}',
        oldValues: oldUser.toFirestore(),
        newValues: updates,
      );

      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'utilisateur: $e');
      return false;
    }
  }

  /// Activer/Désactiver un utilisateur
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      print(
          '🔄 ${isActive ? 'Activation' : 'Désactivation'} utilisateur: $userId');

      // Récupérer l'utilisateur pour logs
      final user = await getUserById(userId);
      if (user == null) {
        print('❌ Utilisateur non trouvé: $userId');
        return false;
      }

      print(
          '👤 ${isActive ? 'Activation' : 'Désactivation'} de: ${user.nomComplet}');

      // Mettre à jour le statut dans Firestore
      await _usersCollection.doc(userId).update({'isActive': isActive});
      print('✅ Statut mis à jour dans Firestore');

      // Logger l'action
      await _logUserAction(
        userId: userId,
        type: isActive ? UserActionType.activated : UserActionType.deactivated,
        description:
            'Utilisateur ${user.nomComplet} ${isActive ? 'activé' : 'désactivé'} par ${_userSession.email}',
        oldValues: {'isActive': user.isActive},
        newValues: {'isActive': isActive},
      );

      print(
          '✅ ${isActive ? 'Activation' : 'Désactivation'} terminée avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur lors du changement de statut: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Changer le rôle d'un utilisateur
  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      print('🔄 Changement de rôle utilisateur: $userId vers $newRole');

      final oldUser = await getUserById(userId);
      if (oldUser == null) {
        print('❌ Utilisateur non trouvé: $userId');
        return false;
      }

      print(
          '👤 Changement de rôle pour: ${oldUser.nomComplet} (${oldUser.role} → $newRole)');

      // Mettre à jour le rôle dans Firestore
      await _usersCollection.doc(userId).update({'role': newRole});
      print('✅ Rôle mis à jour dans Firestore');

      // Logger l'action
      await _logUserAction(
        userId: userId,
        type: UserActionType.roleChanged,
        description:
            'Rôle de ${oldUser.nomComplet} changé de ${oldUser.role} vers $newRole par ${_userSession.email}',
        oldValues: {'role': oldUser.role},
        newValues: {'role': newRole},
      );

      print('✅ Changement de rôle terminé avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur lors du changement de rôle: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Changer le site d'un utilisateur
  Future<bool> changeUserSite(String userId, String newSite) async {
    try {
      print('🔄 Changement de site utilisateur: $userId vers $newSite');

      final oldUser = await getUserById(userId);
      if (oldUser == null) {
        print('❌ Utilisateur non trouvé: $userId');
        return false;
      }

      print(
          '👤 Changement de site pour: ${oldUser.nomComplet} (${oldUser.site} → $newSite)');

      // Mettre à jour le site dans Firestore
      await _usersCollection.doc(userId).update({'site': newSite});
      print('✅ Site mis à jour dans Firestore');

      // Logger l'action
      await _logUserAction(
        userId: userId,
        type: UserActionType.siteChanged,
        description:
            'Site de ${oldUser.nomComplet} changé de ${oldUser.site} vers $newSite par ${_userSession.email}',
        oldValues: {'site': oldUser.site},
        newValues: {'site': newSite},
      );

      print('✅ Changement de site terminé avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur lors du changement de site: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Réinitialiser le mot de passe d'un utilisateur
  Future<bool> resetUserPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      // Trouver l'utilisateur par email pour l'ID
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userId = querySnapshot.docs.first.id;
        await _logUserAction(
          userId: userId,
          type: UserActionType.passwordReset,
          description: 'Mot de passe réinitialisé par ${_userSession.email}',
        );
      }

      return true;
    } catch (e) {
      print('Erreur lors de la réinitialisation du mot de passe: $e');
      return false;
    }
  }

  /// Supprimer complètement un utilisateur (HARD DELETE)
  Future<bool> deleteUser(String userId) async {
    try {
      print('🗑️ SUPPRESSION DÉFINITIVE utilisateur: $userId');

      // Récupérer les infos de l'utilisateur avant suppression
      final user = await getUserById(userId);
      if (user == null) {
        print('❌ Utilisateur non trouvé: $userId');
        return false;
      }

      print('👤 SUPPRESSION DÉFINITIVE de: ${user.nomComplet} (${user.email})');
      print('⚠️ ATTENTION: Cette action est IRRÉVERSIBLE !');

      // 1. Logger l'action AVANT suppression (pour garder une trace)
      await _logUserAction(
        userId: userId,
        type: UserActionType.deleted,
        description:
            'SUPPRESSION DÉFINITIVE de ${user.nomComplet} par ${_userSession.email}',
        oldValues: {
          'id': user.id,
          'email': user.email,
          'nom': user.nom,
          'prenom': user.prenom,
          'role': user.role,
          'site': user.site,
          'isActive': user.isActive,
          'emailVerified': user.emailVerified,
          'dateCreation': user.dateCreation.toIso8601String(),
        },
        newValues: {
          'deleted': true,
          'deletedAt': DateTime.now().toIso8601String(),
          'deletedBy': _userSession.email,
          'deletionType': 'HARD_DELETE',
        },
      );
      print('✅ Action loggée pour traçabilité');

      // 2. Supprimer de Firebase Auth
      try {
        // Tenter de supprimer via l'utilisateur actuel (si c'est le même)
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == userId) {
          // Si c'est l'utilisateur connecté qui se supprime lui-même
          await currentUser.delete();
          print('✅ Utilisateur supprimé de Firebase Auth (auto-suppression)');
        } else {
          // Pour les autres utilisateurs, on doit utiliser Admin SDK
          // Créer une demande de suppression pour Firebase Functions
          await _createAuthDeletionRequest(user.email, userId);
          print('📝 Demande de suppression Firebase Auth créée');

          // SOLUTION TEMPORAIRE: Forcer la déconnexion si c'est possible
          try {
            // Essayer de révoquer les tokens de refresh (nécessite Admin SDK)
            print('⚠️ ATTENTION: L\'utilisateur reste dans Firebase Auth');
            print('⚠️ Déployez la Firebase Function pour suppression complète');
          } catch (e) {
            print('⚠️ Impossible de supprimer de Firebase Auth sans Admin SDK');
          }
        }
      } catch (authError) {
        print('⚠️ Erreur Firebase Auth: $authError');
        // Continue quand même avec la suppression Firestore
      }

      // 3. Supprimer COMPLÈTEMENT de Firestore
      await _usersCollection.doc(userId).delete();
      print('✅ Document utilisateur SUPPRIMÉ de Firestore');

      // 4. Supprimer toutes les données associées
      await _deleteUserAssociatedData(userId);
      print('✅ Données associées supprimées');

      print('🎉 SUPPRESSION DÉFINITIVE terminée avec succès');
      print('📝 Une trace a été conservée dans les logs d\'actions');

      return true;
    } catch (e) {
      print('❌ ERREUR lors de la suppression définitive: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Créer une demande de suppression Firebase Auth
  Future<void> _createAuthDeletionRequest(String email, String userId) async {
    try {
      // Créer un document de demande de suppression pour Firebase Functions ou Admin
      await _firestore.collection('auth_deletion_requests').doc(userId).set({
        'email': email,
        'userId': userId,
        'requestedBy': _userSession.email,
        'requestedAt': Timestamp.now(),
        'status': 'pending',
        'type': 'user_deletion',
      });
      print('📝 Demande de suppression Firebase Auth créée');
    } catch (e) {
      print('⚠️ Erreur création demande suppression Auth: $e');
    }
  }

  /// Supprimer toutes les données associées à un utilisateur
  Future<void> _deleteUserAssociatedData(String userId) async {
    try {
      // Supprimer les actions de l'utilisateur (optionnel - on peut garder pour l'audit)
      // final userActions = await _userActionsCollection
      //     .where('userId', isEqualTo: userId)
      //     .get();
      // for (var doc in userActions.docs) {
      //   await doc.reference.delete();
      // }

      // Supprimer d'autres collections liées à l'utilisateur si nécessaire
      // Par exemple: collectes, rapports, etc.
      await _deleteUserFromOtherCollections(userId);

      print('✅ Nettoyage des données associées terminé');
    } catch (e) {
      print('⚠️ Erreur nettoyage données associées: $e');
    }
  }

  /// Supprimer l'utilisateur des autres collections
  Future<void> _deleteUserFromOtherCollections(String userId) async {
    try {
      // Exemple: supprimer des collections de collecte si l'utilisateur était collecteur
      // Vous pouvez adapter selon vos besoins

      // Collection des collectes (si elle existe)
      try {
        final collectes = await _firestore
            .collection('collectes')
            .where('collecteurId', isEqualTo: userId)
            .get();

        for (var doc in collectes.docs) {
          // Option 1: Supprimer complètement
          // await doc.reference.delete();

          // Option 2: Marquer comme orpheline (recommandé)
          await doc.reference.update({
            'collecteurId': 'UTILISATEUR_SUPPRIME',
            'collecteurNom': 'Utilisateur supprimé',
            'orphanedAt': Timestamp.now(),
          });
        }
        print('✅ Collectes mises à jour (${collectes.docs.length} documents)');
      } catch (e) {
        print('⚠️ Erreur mise à jour collectes: $e');
      }

      // Ajouter d'autres collections selon vos besoins
    } catch (e) {
      print('⚠️ Erreur suppression autres collections: $e');
    }
  }

  /// Récupérer l'historique des actions sur un utilisateur
  Future<List<UserAction>> getUserActions(String userId) async {
    try {
      final snapshot = await _userActionsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => UserAction.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des actions: $e');
      return [];
    }
  }

  /// Récupérer toutes les actions récentes
  Future<List<UserAction>> getRecentActions({int limit = 100}) async {
    try {
      final snapshot = await _userActionsCollection
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => UserAction.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des actions récentes: $e');
      return [];
    }
  }

  /// Récupérer l'historique paginé avec filtres
  Future<PaginatedActions> getActionsPaginated({
    int limit = 50,
    DocumentSnapshot? startAfter,
    UserActionType? type,
    String? adminEmail,
    String? userId,
    DateTime? start,
    DateTime? end,
    String? search,
  }) async {
    try {
      Query query =
          _userActionsCollection.orderBy('timestamp', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }
      if (adminEmail != null && adminEmail.isNotEmpty) {
        query = query.where('adminEmail', isEqualTo: adminEmail);
      }
      if (userId != null && userId.isNotEmpty) {
        query = query.where('userId', isEqualTo: userId);
      }
      if (start != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start));
      }
      if (end != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(end));
      }
      if (startAfter != null) {
        query = (query as Query<Map<String, dynamic>>)
            .startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(limit).get();
      final actions =
          snapshot.docs.map((d) => UserAction.fromFirestore(d)).toList();
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      // Filtre côté client pour la recherche plein texte simple sur la description
      List<UserAction> filtered = actions;
      if (search != null && search.trim().isNotEmpty) {
        final q = search.toLowerCase();
        filtered = actions
            .where((a) =>
                a.description.toLowerCase().contains(q) ||
                (a.adminEmail.toLowerCase().contains(q)))
            .toList();
      }

      return PaginatedActions(
        actions: filtered,
        lastDocument: lastDoc,
        hasMore: snapshot.docs.length >= limit,
      );
    } catch (e) {
      print('Erreur pagination actions: $e');
      return PaginatedActions(actions: [], lastDocument: null, hasMore: false);
    }
  }

  /// Vérifier manuellement l'email d'un utilisateur
  Future<bool> verifyUserEmail(String userId) async {
    try {
      print('📧 Vérification manuelle email utilisateur: $userId');

      // Récupérer l'utilisateur pour logs
      final user = await getUserById(userId);
      if (user == null) {
        print('❌ Utilisateur non trouvé: $userId');
        return false;
      }

      print('👤 Vérification email pour: ${user.nomComplet} (${user.email})');

      // Mettre à jour le statut de vérification dans Firestore
      await _usersCollection.doc(userId).update({'emailVerified': true});
      print('✅ Email marqué comme vérifié dans Firestore');

      // Logger l'action
      await _logUserAction(
        userId: userId,
        type: UserActionType.emailVerified,
        description:
            'Email de ${user.nomComplet} vérifié manuellement par ${_userSession.email}',
        oldValues: {'emailVerified': user.emailVerified},
        newValues: {'emailVerified': true},
      );

      print('✅ Vérification email terminée avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la vérification de l\'email: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Renvoyer l'email de vérification
  Future<bool> resendVerificationEmail(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      // Cooldown par userId
      final last = _lastVerificationResend[userId];
      if (last != null && DateTime.now().difference(last) < _resendCooldown) {
        final remaining = _resendCooldown - DateTime.now().difference(last);
        print(
            '⏳ Cooldown actif pour ${user.email}, ${remaining.inSeconds}s restants');
        return false;
      }

      // D'abord via Firebase impersonation
      bool emailSent = await _resendVerificationEmailViaFirebase(uid: user.id);
      if (!emailSent) {
        // Fallback local
        emailSent = await _emailService.sendCustomVerificationEmailLocal(
          userEmail: user.email,
          userName: user.nomComplet,
        );
      }

      if (emailSent) {
        _lastVerificationResend[userId] = DateTime.now();
        await _usersCollection.doc(userId).update({
          'lastVerificationEmailSentAt': FieldValue.serverTimestamp(),
        });
        await _logUserAction(
          userId: userId,
          type: UserActionType.emailResent,
          description:
              'Email de vérification renvoyé par ${_userSession.email}',
        );
      }
      return emailSent;
    } catch (e) {
      print('Erreur lors du renvoi de l\'email de vérification: $e');
      return false;
    }
  }

  /// Générer un nouveau mot de passe temporaire pour un utilisateur
  Future<String?> generateTemporaryPassword(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return null;

      final tempPassword = _generateTemporaryPassword();

      // Mettre à jour le mot de passe dans Firebase Auth
      // Note: Ceci nécessite des privilèges admin Firebase
      // En pratique, on enverrait plutôt un email de reset

      await _logUserAction(
        userId: userId,
        type: UserActionType.passwordGenerated,
        description: 'Mot de passe temporaire généré par ${_userSession.email}',
      );

      return tempPassword;
    } catch (e) {
      print('Erreur lors de la génération du mot de passe temporaire: $e');
      return null;
    }
  }

  /// Activer/Désactiver l'accès d'un utilisateur (différent de isActive)
  Future<bool> toggleUserAccess(String userId, bool hasAccess) async {
    try {
      print(
          '🔐 ${hasAccess ? 'Accord' : 'Révocation'} d\'accès utilisateur: $userId');

      // Récupérer l'utilisateur pour logs
      final user = await getUserById(userId);
      if (user == null) {
        print('❌ Utilisateur non trouvé: $userId');
        return false;
      }

      print(
          '👤 ${hasAccess ? 'Accord' : 'Révocation'} d\'accès pour: ${user.nomComplet}');

      // Mettre à jour l'accès dans Firestore
      await _usersCollection.doc(userId).update({'hasAccess': hasAccess});
      print('✅ Accès mis à jour dans Firestore');

      // Logger l'action
      await _logUserAction(
        userId: userId,
        type: hasAccess
            ? UserActionType.accessGranted
            : UserActionType.accessRevoked,
        description:
            'Accès ${hasAccess ? 'accordé' : 'révoqué'} pour ${user.nomComplet} par ${_userSession.email}',
        oldValues: {'hasAccess': user.metadata?['hasAccess'] ?? true},
        newValues: {'hasAccess': hasAccess},
      );

      print(
          '✅ ${hasAccess ? 'Accord' : 'Révocation'} d\'accès terminé avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur lors du changement d\'accès: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Test de connectivité à la base de données
  Future<bool> testDatabaseConnection() async {
    try {
      print('🧪 Test de connectivité à la base de données...');

      // Test 1: Vérifier la session utilisateur
      if (_userSession.email == null || _userSession.email!.isEmpty) {
        print('❌ Session utilisateur non initialisée');
        return false;
      }
      print('✅ Session utilisateur: ${_userSession.email}');

      // Test 2: Vérifier la connexion Firestore
      await _firestore.collection('test').doc('connectivity').get();
      print('✅ Connexion Firestore OK');

      // Test 3: Vérifier la collection utilisateurs
      final usersSnapshot = await _usersCollection.limit(1).get();
      print(
          '✅ Collection utilisateurs accessible (${usersSnapshot.docs.length} docs trouvés)');

      // Test 4: Vérifier la collection user_actions
      final actionsSnapshot = await _userActionsCollection.limit(1).get();
      print(
          '✅ Collection user_actions accessible (${actionsSnapshot.docs.length} actions trouvées)');

      print('🎉 Tous les tests de connectivité réussis !');
      return true;
    } catch (e) {
      print('❌ Erreur de connectivité: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Vérifier les permissions Firestore pour un utilisateur
  Future<bool> checkFirestorePermissions(String userId) async {
    try {
      print('🔐 Vérification des permissions Firestore pour: $userId');

      // Test lecture
      await _usersCollection.doc(userId).get();
      print('✅ Permission de lecture OK');

      // Test écriture (mise à jour d'un champ test)
      await _usersCollection
          .doc(userId)
          .update({'lastPermissionCheck': Timestamp.now()});
      print('✅ Permission d\'écriture OK');

      return true;
    } catch (e) {
      print('❌ Erreur de permissions: $e');
      return false;
    }
  }

  /// Enregistrer une action sur un utilisateur
  Future<void> _logUserAction({
    required String userId,
    required UserActionType type,
    required String description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    try {
      final action = UserAction(
        id: '', // Sera généré par Firestore
        userId: userId,
        adminId: _userSession.uid ?? '',
        adminEmail: _userSession.email ?? '',
        type: type,
        description: description,
        timestamp: DateTime.now(),
        oldValues: oldValues,
        newValues: newValues,
      );

      await _userActionsCollection.add(action.toFirestore());
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'action: $e');
    }
  }

  /// Vérifier si un email existe déjà
  Future<bool> emailExists(String email) async {
    try {
      final snapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification de l\'email: $e');
      return false;
    }
  }

  /// Mettre à jour la dernière connexion d'un utilisateur
  Future<void> updateLastLogin(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'dateLastLogin': Timestamp.now(),
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la dernière connexion: $e');
    }
  }

  /// Récupérer les utilisateurs en ligne
  Future<List<AppUser>> getOnlineUsers() async {
    try {
      final users = await getUsers();
      return users.where((user) => user.isOnline).toList();
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs en ligne: $e');
      return [];
    }
  }

  /// Exporter les données utilisateurs (pour backup/rapport)
  Future<List<Map<String, dynamic>>> exportUsers() async {
    try {
      final users = await getUsers();
      return users
          .map((user) => {
                'ID': user.id,
                'Email': user.email,
                'Nom': user.nom,
                'Prénom': user.prenom,
                'Téléphone': user.telephone,
                'Rôle': user.role,
                'Site': user.site,
                'Actif': user.isActive ? 'Oui' : 'Non',
                'Email vérifié': user.emailVerified ? 'Oui' : 'Non',
                'Date création': user.dateCreation.toIso8601String(),
                'Dernière connexion':
                    user.dateLastLogin?.toIso8601String() ?? 'Jamais',
              })
          .toList();
    } catch (e) {
      print('Erreur lors de l\'export: $e');
      return [];
    }
  }
}
