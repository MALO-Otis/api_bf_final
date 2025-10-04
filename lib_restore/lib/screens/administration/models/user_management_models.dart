import '../../../utils/role_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour un utilisateur dans le système
class AppUser {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final List<String> roles;
  final String site;
  final bool isActive;
  final bool emailVerified;
  final DateTime dateCreation;
  final DateTime? dateLastLogin;
  final String? photoUrl;
  final Map<String, dynamic>? metadata;

  AppUser({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required List<String> roles,
    required this.site,
    this.isActive = true,
    this.emailVerified = false,
    required this.dateCreation,
    this.dateLastLogin,
    this.photoUrl,
    this.metadata,
  }) : roles = List<String>.unmodifiable(roles);

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: data['uid'] ?? doc.id, // Utiliser le champ uid du document
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      roles: extractNormalizedRoles(data['role']),
      site: data['site'] ?? '',
      isActive: data['isActive'] ?? true, // Par défaut true si pas spécifié
      emailVerified: data['emailVerified'] ?? false,
      dateCreation: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(), // createdAt au lieu de dateCreation
      dateLastLogin: (data['dateLastLogin'] as Timestamp?)?.toDate(),
      photoUrl: data['photoUrl'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': id, // Ajouter le champ uid
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'role': roles,
      'site': site,
      'isActive': isActive,
      'emailVerified': emailVerified,
      'createdAt':
          Timestamp.fromDate(dateCreation), // createdAt au lieu de dateCreation
      'dateLastLogin':
          dateLastLogin != null ? Timestamp.fromDate(dateLastLogin!) : null,
      'photoUrl': photoUrl,
      'metadata': metadata,
    };
  }

  String get nomComplet => '$prenom $nom';
  String get initiales =>
      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
          .toUpperCase();

  /// Rôle principal hérité (compatibilité avec l'ancien modèle mono-rôle)
  String get role => roles.isNotEmpty ? roles.first : '';

  String get primaryRole => role;

  List<String> get secondaryRoles =>
      roles.length > 1 ? roles.sublist(1) : const <String>[];

  bool get isOnline =>
      dateLastLogin != null &&
      DateTime.now().difference(dateLastLogin!).inMinutes < 30;

  AppUser copyWith({
    String? email,
    String? nom,
    String? prenom,
    String? telephone,
    List<String>? roles,
    String? role,
    String? site,
    bool? isActive,
    bool? emailVerified,
    DateTime? dateLastLogin,
    String? photoUrl,
    Map<String, dynamic>? metadata,
  }) {
    final List<String> resolvedRoles;
    if (roles != null) {
      resolvedRoles = List<String>.unmodifiable(roles);
    } else if (role != null) {
      resolvedRoles = List<String>.unmodifiable(
        extractNormalizedRoles(role),
      );
    } else {
      resolvedRoles = this.roles;
    }
    return AppUser(
      id: id,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      roles: resolvedRoles,
      site: site ?? this.site,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      dateCreation: dateCreation,
      dateLastLogin: dateLastLogin ?? this.dateLastLogin,
      photoUrl: photoUrl ?? this.photoUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Statistiques des utilisateurs
class UserStatistics {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int verifiedUsers;
  final int unverifiedUsers;
  final int onlineUsers;
  final Map<String, int> usersByRole;
  final Map<String, int> usersBySite;
  final Map<String, int> newUsersByMonth;
  final Map<String, int> loginsByMonth;

  UserStatistics({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.verifiedUsers,
    required this.unverifiedUsers,
    required this.onlineUsers,
    required this.usersByRole,
    required this.usersBySite,
    required this.newUsersByMonth,
    required this.loginsByMonth,
  });

  factory UserStatistics.empty() {
    return UserStatistics(
      totalUsers: 0,
      activeUsers: 0,
      inactiveUsers: 0,
      verifiedUsers: 0,
      unverifiedUsers: 0,
      onlineUsers: 0,
      usersByRole: {},
      usersBySite: {},
      newUsersByMonth: {},
      loginsByMonth: {},
    );
  }
}

/// Filtres pour la recherche d'utilisateurs
class UserFilters {
  final String? searchTerm;
  final String? role;
  final String? site;
  final bool? isActive;
  final bool? emailVerified;
  final DateTime? dateCreationStart;
  final DateTime? dateCreationEnd;
  final UserSortField sortField;
  final bool sortAscending;

  UserFilters({
    this.searchTerm,
    this.role,
    this.site,
    this.isActive,
    this.emailVerified,
    this.dateCreationStart,
    this.dateCreationEnd,
    this.sortField = UserSortField.dateCreation,
    this.sortAscending = false,
  });

  UserFilters copyWith({
    String? searchTerm,
    String? role,
    String? site,
    bool? isActive,
    bool? emailVerified,
    DateTime? dateCreationStart,
    DateTime? dateCreationEnd,
    UserSortField? sortField,
    bool? sortAscending,
  }) {
    return UserFilters(
      searchTerm: searchTerm ?? this.searchTerm,
      role: role ?? this.role,
      site: site ?? this.site,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      dateCreationStart: dateCreationStart ?? this.dateCreationStart,
      dateCreationEnd: dateCreationEnd ?? this.dateCreationEnd,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  bool get hasActiveFilters {
    return searchTerm != null && searchTerm!.isNotEmpty ||
        role != null ||
        site != null ||
        isActive != null ||
        emailVerified != null ||
        dateCreationStart != null ||
        dateCreationEnd != null;
  }

  UserFilters clearFilters() {
    return UserFilters(
      sortField: sortField,
      sortAscending: sortAscending,
    );
  }
}

/// Champs de tri disponibles
enum UserSortField {
  nom,
  prenom,
  email,
  role,
  site,
  dateCreation,
  dateLastLogin,
}

extension UserSortFieldExtension on UserSortField {
  String get displayName {
    switch (this) {
      case UserSortField.nom:
        return 'Nom';
      case UserSortField.prenom:
        return 'Prénom';
      case UserSortField.email:
        return 'Email';
      case UserSortField.role:
        return 'Rôle';
      case UserSortField.site:
        return 'Site';
      case UserSortField.dateCreation:
        return 'Date création';
      case UserSortField.dateLastLogin:
        return 'Dernière connexion';
    }
  }

  String get firestoreField {
    switch (this) {
      case UserSortField.nom:
        return 'nom';
      case UserSortField.prenom:
        return 'prenom';
      case UserSortField.email:
        return 'email';
      case UserSortField.role:
        return 'role';
      case UserSortField.site:
        return 'site';
      case UserSortField.dateCreation:
        return 'createdAt';
      case UserSortField.dateLastLogin:
        return 'dateLastLogin';
    }
  }
}

/// Action sur un utilisateur pour l'historique
class UserAction {
  final String id;
  final String userId;
  final String adminId;
  final String adminEmail;
  final UserActionType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;

  UserAction({
    required this.id,
    required this.userId,
    required this.adminId,
    required this.adminEmail,
    required this.type,
    required this.description,
    required this.timestamp,
    this.oldValues,
    this.newValues,
  });

  factory UserAction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserAction(
      id: doc.id,
      userId: data['userId'] ?? '',
      adminId: data['adminId'] ?? '',
      adminEmail: data['adminEmail'] ?? '',
      type: UserActionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => UserActionType.other,
      ),
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      oldValues: data['oldValues'],
      newValues: data['newValues'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'adminId': adminId,
      'adminEmail': adminEmail,
      'type': type.toString().split('.').last,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'oldValues': oldValues,
      'newValues': newValues,
    };
  }
}

/// Types d'actions possibles sur un utilisateur
enum UserActionType {
  created,
  updated,
  activated,
  deactivated,
  roleChanged,
  siteChanged,
  passwordReset,
  emailVerified,
  emailResent,
  passwordGenerated,
  accessGranted,
  accessRevoked,
  deleted,
  other,
}

extension UserActionTypeExtension on UserActionType {
  String get displayName {
    switch (this) {
      case UserActionType.created:
        return 'Créé';
      case UserActionType.updated:
        return 'Modifié';
      case UserActionType.activated:
        return 'Activé';
      case UserActionType.deactivated:
        return 'Désactivé';
      case UserActionType.roleChanged:
        return 'Rôle modifié';
      case UserActionType.siteChanged:
        return 'Site modifié';
      case UserActionType.passwordReset:
        return 'Mot de passe réinitialisé';
      case UserActionType.emailVerified:
        return 'Email vérifié';
      case UserActionType.emailResent:
        return 'Email de vérification renvoyé';
      case UserActionType.passwordGenerated:
        return 'Mot de passe temporaire généré';
      case UserActionType.accessGranted:
        return 'Accès accordé';
      case UserActionType.accessRevoked:
        return 'Accès révoqué';
      case UserActionType.deleted:
        return 'Supprimé';
      case UserActionType.other:
        return 'Autre';
    }
  }

  String get icon {
    switch (this) {
      case UserActionType.created:
        return '➕';
      case UserActionType.updated:
        return '✏️';
      case UserActionType.activated:
        return '✅';
      case UserActionType.deactivated:
        return '❌';
      case UserActionType.roleChanged:
        return '🔄';
      case UserActionType.siteChanged:
        return '📍';
      case UserActionType.passwordReset:
        return '🔑';
      case UserActionType.emailVerified:
        return '📧';
      case UserActionType.emailResent:
        return '📤';
      case UserActionType.passwordGenerated:
        return '🔐';
      case UserActionType.accessGranted:
        return '🟢';
      case UserActionType.accessRevoked:
        return '🔴';
      case UserActionType.deleted:
        return '🗑️';
      case UserActionType.other:
        return '📝';
    }
  }
}
