import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_management_models.dart';
import '../../../authentication/user_session.dart';

class UserManagementService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserSession _userSession = Get.find<UserSession>();

  /// Collection des utilisateurs
  CollectionReference get _usersCollection => _firestore.collection('utilisateurs');
  
  /// Collection des actions sur les utilisateurs
  CollectionReference get _userActionsCollection => _firestore.collection('user_actions');

  /// Sites disponibles
  final List<String> availableSites = [
    'Ouaga', 'Koudougou', 'Bobo', 'Mangodara', 'Bagre', 'Pô'
  ];

  /// Rôles disponibles
  final List<String> availableRoles = [
    'Admin', 'Collecteur', 'Contrôleur', 'Filtreur', 'Extracteur',
    'Conditionneur', 'Magazinier', 'Gestionnaire Commercial', 'Commercial', 'Caissier'
  ];

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
        query = query.orderBy('dateCreation', descending: true);
      }

      final snapshot = await query.get();
      List<AppUser> users = snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();

      // Filtres côté client (pour les champs complexes)
      if (filters?.searchTerm != null && filters!.searchTerm!.isNotEmpty) {
        final searchLower = filters.searchTerm!.toLowerCase();
        users = users.where((user) =>
          user.nom.toLowerCase().contains(searchLower) ||
          user.prenom.toLowerCase().contains(searchLower) ||
          user.email.toLowerCase().contains(searchLower) ||
          user.telephone.contains(searchLower)
        ).toList();
      }

      if (filters?.dateCreationStart != null) {
        users = users.where((user) => 
          user.dateCreation.isAfter(filters!.dateCreationStart!)
        ).toList();
      }

      if (filters?.dateCreationEnd != null) {
        users = users.where((user) => 
          user.dateCreation.isBefore(filters!.dateCreationEnd!.add(Duration(days: 1)))
        ).toList();
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

  /// Créer un nouvel utilisateur
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
      // Créer l'utilisateur dans Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return false;

      // Créer le document utilisateur dans Firestore
      final appUser = AppUser(
        id: user.uid,
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
      await _usersCollection.doc(user.uid).set(appUser.toFirestore());

      // Envoyer l'email de vérification
      await user.sendEmailVerification();

      // Enregistrer l'action
      await _logUserAction(
        userId: user.uid,
        type: UserActionType.created,
        description: 'Utilisateur créé par ${_userSession.email}',
        newValues: appUser.toFirestore(),
      );

      return true;
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur: $e');
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
      await _usersCollection.doc(userId).update({'isActive': isActive});

      await _logUserAction(
        userId: userId,
        type: isActive ? UserActionType.activated : UserActionType.deactivated,
        description: 'Utilisateur ${isActive ? 'activé' : 'désactivé'} par ${_userSession.email}',
        newValues: {'isActive': isActive},
      );

      return true;
    } catch (e) {
      print('Erreur lors du changement de statut: $e');
      return false;
    }
  }

  /// Changer le rôle d'un utilisateur
  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      final oldUser = await getUserById(userId);
      if (oldUser == null) return false;

      await _usersCollection.doc(userId).update({'role': newRole});

      await _logUserAction(
        userId: userId,
        type: UserActionType.roleChanged,
        description: 'Rôle changé de ${oldUser.role} vers $newRole par ${_userSession.email}',
        oldValues: {'role': oldUser.role},
        newValues: {'role': newRole},
      );

      return true;
    } catch (e) {
      print('Erreur lors du changement de rôle: $e');
      return false;
    }
  }

  /// Changer le site d'un utilisateur
  Future<bool> changeUserSite(String userId, String newSite) async {
    try {
      final oldUser = await getUserById(userId);
      if (oldUser == null) return false;

      await _usersCollection.doc(userId).update({'site': newSite});

      await _logUserAction(
        userId: userId,
        type: UserActionType.siteChanged,
        description: 'Site changé de ${oldUser.site} vers $newSite par ${_userSession.email}',
        oldValues: {'site': oldUser.site},
        newValues: {'site': newSite},
      );

      return true;
    } catch (e) {
      print('Erreur lors du changement de site: $e');
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

  /// Supprimer un utilisateur (soft delete)
  Future<bool> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'isActive': false,
        'deletedAt': Timestamp.now(),
        'deletedBy': _userSession.email,
      });

      await _logUserAction(
        userId: userId,
        type: UserActionType.deleted,
        description: 'Utilisateur supprimé par ${_userSession.email}',
      );

      return true;
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Récupérer les statistiques des utilisateurs
  Future<UserStatistics> getUserStatistics() async {
    try {
      final users = await getUsers();
      
      final totalUsers = users.length;
      final activeUsers = users.where((u) => u.isActive).length;
      final inactiveUsers = totalUsers - activeUsers;
      final verifiedUsers = users.where((u) => u.emailVerified).length;
      final unverifiedUsers = totalUsers - verifiedUsers;
      final onlineUsers = users.where((u) => u.isOnline).length;

      // Statistiques par rôle
      final Map<String, int> usersByRole = {};
      for (final role in availableRoles) {
        usersByRole[role] = users.where((u) => u.role == role).length;
      }

      // Statistiques par site
      final Map<String, int> usersBySite = {};
      for (final site in availableSites) {
        usersBySite[site] = users.where((u) => u.site == site).length;
      }

      // Nouveaux utilisateurs par mois (12 derniers mois)
      final Map<String, int> newUsersByMonth = {};
      final now = DateTime.now();
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        final nextMonth = DateTime(month.year, month.month + 1, 1);
        
        newUsersByMonth[monthKey] = users.where((u) => 
          u.dateCreation.isAfter(month) && u.dateCreation.isBefore(nextMonth)
        ).length;
      }

      // Connexions par mois (simulé - dans un vrai système, vous auriez des logs de connexion)
      final Map<String, int> loginsByMonth = {};
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        // Simulation basée sur les utilisateurs actifs
        loginsByMonth[monthKey] = (activeUsers * 0.7).round() + (i * 2);
      }

      return UserStatistics(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        inactiveUsers: inactiveUsers,
        verifiedUsers: verifiedUsers,
        unverifiedUsers: unverifiedUsers,
        onlineUsers: onlineUsers,
        usersByRole: usersByRole,
        usersBySite: usersBySite,
        newUsersByMonth: newUsersByMonth,
        loginsByMonth: loginsByMonth,
      );
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return UserStatistics.empty();
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

      return snapshot.docs
          .map((doc) => UserAction.fromFirestore(doc))
          .toList();
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

      return snapshot.docs
          .map((doc) => UserAction.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des actions récentes: $e');
      return [];
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
      return users.map((user) => {
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
        'Dernière connexion': user.dateLastLogin?.toIso8601String() ?? 'Jamais',
      }).toList();
    } catch (e) {
      print('Erreur lors de l\'export: $e');
      return [];
    }
  }
}
