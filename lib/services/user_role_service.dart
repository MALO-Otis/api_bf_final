import 'package:get/get.dart';
import '../authentication/user_session.dart';

/// Énumération des rôles utilisateurs avec leurs permissions
enum UserRole {
  admin('Admin'),
  collecteur('Collecteur'),
  controleur('Contrôleur'),
  extracteur('Extracteur'),
  filtreur('Filtreur'),
  conditionneur('Conditionneur'),
  magazinier('Magazinier'),
  gestionnaireCommercial('Gestionnaire Commercial'),
  commercial('Commercial'),
  caissier('Caissier'),
  caissiere('Caissière');

  const UserRole(this.label);
  final String label;
}

/// Groupes de rôles pour les interfaces partagées
enum RoleGroup {
  admin,
  controleur,
  extracteurFiltreur,
  conditionneur,
  commercial,
  caissier
}

/// Service de gestion des rôles utilisateurs
class UserRoleService extends GetxController {
  static UserRoleService get instance => Get.find();

  final UserSession _userSession = Get.find<UserSession>();

  /// Normalise une chaîne pour comparaison de rôles (minuscule, sans accents, sans espaces superflus)
  String _normalize(String s) {
    s = s.toLowerCase().trim();
    const replacements = {
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'á': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'ì': 'i',
      'í': 'i',
      'ô': 'o',
      'ö': 'o',
      'ò': 'o',
      'ó': 'o',
      'õ': 'o',
      'û': 'u',
      'ü': 'u',
      'ù': 'u',
      'ú': 'u',
      'ç': 'c',
      'ñ': 'n',
      'œ': 'oe',
      'æ': 'ae',
    };
    for (final entry in replacements.entries) {
      s = s.replaceAll(entry.key, entry.value);
    }
    // Unifier espaces multiples
    s = s.replaceAll(RegExp(r"\s+"), ' ');
    return s;
  }

  /// Obtient le rôle actuel de l'utilisateur
  UserRole? get currentUserRole {
    final roleString = _userSession.role;
    if (roleString == null) return null;

    final normalizedInput = _normalize(roleString);

    // 1) Correspondance directe (labels normalisés)
    for (final role in UserRole.values) {
      if (_normalize(role.label) == normalizedInput) {
        return role;
      }
    }

    // 2) Synonymes connus / corrections d'orthographe fréquentes
    // Map des synonymes normalisés -> UserRole
    final Map<String, UserRole> synonyms = {
      'administrateur': UserRole.admin,
      'admin': UserRole.admin,
      'controleur': UserRole.controleur,
      'controlleur': UserRole.controleur, // faute fréquente
      'controle': UserRole.controleur,
      'extraction': UserRole.extracteur,
      'extracteur': UserRole.extracteur,
      'filtreur': UserRole.filtreur,
      'conditionneur': UserRole.conditionneur,
      'magazinier': UserRole.magazinier,
      'magasinier': UserRole.magazinier, // variante orthographique
      'gestionnaire commercial': UserRole.gestionnaireCommercial,
      'gestionnairecommercial': UserRole.gestionnaireCommercial,
      'commercial': UserRole.commercial,
      'caisse': UserRole.caissier,
      'caissier': UserRole.caissier,
      'caissiere': UserRole.caissiere,
    };
    if (synonyms.containsKey(normalizedInput)) {
      return synonyms[normalizedInput];
    }

    // 3) Aucune correspondance trouvée
    return null;
  }

  /// Obtient le groupe de rôle pour l'interface
  RoleGroup get currentRoleGroup {
    switch (currentUserRole) {
      case UserRole.admin:
        return RoleGroup.admin;
      case UserRole.controleur:
        return RoleGroup.controleur;
      case UserRole.extracteur:
      case UserRole.filtreur:
        return RoleGroup.extracteurFiltreur;
      case UserRole.conditionneur:
        return RoleGroup.conditionneur;
      case UserRole.magazinier:
      case UserRole.gestionnaireCommercial:
      case UserRole.commercial:
        return RoleGroup.commercial;
      case UserRole.caissier:
      case UserRole.caissiere:
        return RoleGroup.caissier;
      default:
        // Fallback sécurisé: ne jamais promouvoir en admin par défaut
        return RoleGroup.commercial;
    }
  }

  /// Vérifie si l'utilisateur a accès à un module
  bool hasAccessTo(String module) {
    switch (currentRoleGroup) {
      case RoleGroup.admin:
        return true; // Admin a accès à tout
      case RoleGroup.controleur:
        return ['collecte', 'controle', 'attribution', 'stats_controle']
            .contains(module);
      case RoleGroup.extracteurFiltreur:
        return ['extraction', 'filtrage', 'attribution', 'stats_production']
            .contains(module);
      case RoleGroup.conditionneur:
        return ['conditionnement', 'filtrage_history', 'stats_conditionnement']
            .contains(module);
      case RoleGroup.commercial:
        return [
          'vente',
          'conditionnement_history',
          'clients',
          'stats_commercial'
        ].contains(module);
      case RoleGroup.caissier:
        return ['vente', 'caisse', 'stats_caisse'].contains(module);
    }
  }

  /// Obtient les modules accessibles pour le rôle actuel
  List<String> get accessibleModules {
    switch (currentRoleGroup) {
      case RoleGroup.admin:
        return [
          'collecte',
          'controle',
          'attribution',
          'extraction',
          'filtrage',
          'conditionnement',
          'vente',
          'stats_global'
        ];
      case RoleGroup.controleur:
        return ['collecte', 'controle', 'attribution', 'stats_controle'];
      case RoleGroup.extracteurFiltreur:
        return ['extraction', 'filtrage', 'attribution', 'stats_production'];
      case RoleGroup.conditionneur:
        return ['conditionnement', 'filtrage_history', 'stats_conditionnement'];
      case RoleGroup.commercial:
        return [
          'vente',
          'conditionnement_history',
          'clients',
          'stats_commercial'
        ];
      case RoleGroup.caissier:
        return ['vente', 'caisse', 'stats_caisse'];
    }
  }

  /// Obtient la couleur principale du rôle
  String get roleColor {
    switch (currentRoleGroup) {
      case RoleGroup.admin:
        return '#F49101'; // Orange ApiSavana
      case RoleGroup.controleur:
        return '#2196F3'; // Bleu
      case RoleGroup.extracteurFiltreur:
        return '#4CAF50'; // Vert
      case RoleGroup.conditionneur:
        return '#FF9800'; // Orange
      case RoleGroup.commercial:
        return '#9C27B0'; // Violet
      case RoleGroup.caissier:
        return '#607D8B'; // Bleu-gris
    }
  }

  /// Obtient le titre du dashboard selon le rôle
  String get dashboardTitle {
    switch (currentRoleGroup) {
      case RoleGroup.admin:
        return 'Dashboard Administrateur';
      case RoleGroup.controleur:
        return 'Dashboard Contrôleur Qualité';
      case RoleGroup.extracteurFiltreur:
        return 'Dashboard Production';
      case RoleGroup.conditionneur:
        return 'Dashboard Conditionnement';
      case RoleGroup.commercial:
        return 'Dashboard Commercial';
      case RoleGroup.caissier:
        return 'Dashboard Caisse';
    }
  }

  /// Obtient la description du dashboard selon le rôle
  String get dashboardSubtitle {
    switch (currentRoleGroup) {
      case RoleGroup.admin:
        return 'Plateforme de gestion Apisavana';
      case RoleGroup.controleur:
        return 'Contrôle qualité et attribution';
      case RoleGroup.extracteurFiltreur:
        return 'Extraction et filtrage du miel';
      case RoleGroup.conditionneur:
        return 'Conditionnement et emballage';
      case RoleGroup.commercial:
        return 'Ventes et gestion clientèle';
      case RoleGroup.caissier:
        return 'Gestion des encaissements';
    }
  }

  /// Obtient les KPI prioritaires selon le rôle
  List<String> get priorityKPIs {
    switch (currentRoleGroup) {
      case RoleGroup.admin:
        return ['ventes_mois', 'credits_attente', 'stock_total', 'ca_mensuel'];
      case RoleGroup.controleur:
        return [
          'produits_controles',
          'taux_conformite',
          'en_attente_controle',
          'rejets'
        ];
      case RoleGroup.extracteurFiltreur:
        return [
          'kg_extraits',
          'kg_filtres',
          'rendement_extraction',
          'lots_en_cours'
        ];
      case RoleGroup.conditionneur:
        return [
          'lots_conditionnes',
          'pots_produits',
          'stock_emballages',
          'commandes_urgentes'
        ];
      case RoleGroup.commercial:
        return ['ventes_jour', 'ca_commercial', 'clients_actifs', 'objectifs'];
      case RoleGroup.caissier:
        return [
          'encaissements_jour',
          'credits_accordes',
          'retards_paiement',
          'solde_caisse'
        ];
    }
  }
}
