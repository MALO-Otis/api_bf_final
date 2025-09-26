import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
/// 🏪 MODÈLES POUR LA GESTION COMMERCIALE OPTIMISÉE
///
/// Gestion des lots, attributions avec calculs ultra-rapides et cache intelligent


// ============================================================================
// 👤 GESTION DES RÔLES ET PERMISSIONS ADMINISTRATEUR
// ============================================================================

/// Énumération des rôles utilisateur dans le système commercial
enum RoleUtilisateur {
  admin,
  gestionnaire,
  commercial,
  superviseur,
}

/// Permissions administrateur pour la gestion commerciale
class PermissionsAdmin {
  final bool peutVoirTousLesCommerciaux;
  final bool peutModifierAttributions;
  final bool peutCreerAttributions;
  final bool peutSupprimerAttributions;
  final bool peutGererCommerciaux;
  final bool peutAccederStatistiques;
  final bool peutImpersonifierCommercial;

  const PermissionsAdmin({
    required this.peutVoirTousLesCommerciaux,
    required this.peutModifierAttributions,
    required this.peutCreerAttributions,
    required this.peutSupprimerAttributions,
    required this.peutGererCommerciaux,
    required this.peutAccederStatistiques,
    required this.peutImpersonifierCommercial,
  });

  factory PermissionsAdmin.fromRole(RoleUtilisateur role) {
    switch (role) {
      case RoleUtilisateur.admin:
        return const PermissionsAdmin(
          peutVoirTousLesCommerciaux: true,
          peutModifierAttributions: true,
          peutCreerAttributions: true,
          peutSupprimerAttributions: true,
          peutGererCommerciaux: true,
          peutAccederStatistiques: true,
          peutImpersonifierCommercial: true,
        );
      case RoleUtilisateur.superviseur:
        return const PermissionsAdmin(
          peutVoirTousLesCommerciaux: true,
          peutModifierAttributions: true,
          peutCreerAttributions: true,
          peutSupprimerAttributions: false,
          peutGererCommerciaux: false,
          peutAccederStatistiques: true,
          peutImpersonifierCommercial: true,
        );
      case RoleUtilisateur.gestionnaire:
        return const PermissionsAdmin(
          peutVoirTousLesCommerciaux: true,
          peutModifierAttributions: true,
          peutCreerAttributions: true,
          peutSupprimerAttributions: false,
          peutGererCommerciaux: false,
          peutAccederStatistiques: true,
          peutImpersonifierCommercial: false,
        );
      case RoleUtilisateur.commercial:
        return const PermissionsAdmin(
          peutVoirTousLesCommerciaux: false,
          peutModifierAttributions: false,
          peutCreerAttributions: false,
          peutSupprimerAttributions: false,
          peutGererCommerciaux: false,
          peutAccederStatistiques: false,
          peutImpersonifierCommercial: false,
        );
    }
  }
}

/// Contexte d'impersonification d'un commercial
class ContexteImpersonification {
  final String commercialId;
  final String commercialNom;
  final String adminId;
  final String adminNom;
  final DateTime dateDebut;
  final bool estActif;

  const ContexteImpersonification({
    required this.commercialId,
    required this.commercialNom,
    required this.adminId,
    required this.adminNom,
    required this.dateDebut,
    required this.estActif,
  });

  Map<String, dynamic> toMap() {
    return {
      'commercialId': commercialId,
      'commercialNom': commercialNom,
      'adminId': adminId,
      'adminNom': adminNom,
      'dateDebut': Timestamp.fromDate(dateDebut),
      'estActif': estActif,
    };
  }

  factory ContexteImpersonification.fromMap(Map<String, dynamic> map) {
    return ContexteImpersonification(
      commercialId: map['commercialId'] ?? '',
      commercialNom: map['commercialNom'] ?? '',
      adminId: map['adminId'] ?? '',
      adminNom: map['adminNom'] ?? '',
      dateDebut: (map['dateDebut'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estActif: map['estActif'] ?? false,
    );
  }
}

// ============================================================================
// 📦 LOT DE PRODUITS POUR ATTRIBUTION
// ============================================================================

/// Représente un lot de produits pouvant être attribués partiellement ou totalement
class LotProduit {
  final String id;
  final String numeroLot;
  final String siteOrigine;
  final String typeEmballage;
  final String predominanceFlorale;
  final double contenanceKg;
  final double prixUnitaire;
  final int quantiteInitiale;
  final int quantiteRestante;
  final int quantiteAttribuee;
  final DateTime dateConditionnement;
  final DateTime dateExpiration;
  final StatutLot statut;
  final List<AttributionPartielle> attributions;
  final String? observations;

  const LotProduit({
    required this.id,
    required this.numeroLot,
    required this.siteOrigine,
    required this.typeEmballage,
    required this.predominanceFlorale,
    required this.contenanceKg,
    required this.prixUnitaire,
    required this.quantiteInitiale,
    required this.quantiteRestante,
    required this.quantiteAttribuee,
    required this.dateConditionnement,
    required this.dateExpiration,
    required this.statut,
    required this.attributions,
    this.observations,
  });

  factory LotProduit.fromMap(Map<String, dynamic> map) {
    return LotProduit(
      id: map['id'] ?? '',
      numeroLot: map['numeroLot'] ?? '',
      siteOrigine: map['siteOrigine'] ?? '',
      typeEmballage: map['typeEmballage'] ?? '',
      predominanceFlorale: map['predominanceFlorale'] ?? '',
      contenanceKg: (map['contenanceKg'] ?? 0.0).toDouble(),
      prixUnitaire: (map['prixUnitaire'] ?? 0.0).toDouble(),
      quantiteInitiale: map['quantiteInitiale'] ?? 0,
      quantiteRestante: map['quantiteRestante'] ?? 0,
      quantiteAttribuee: map['quantiteAttribuee'] ?? 0,
      dateConditionnement:
          (map['dateConditionnement'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      dateExpiration:
          (map['dateExpiration'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: StatutLot.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => StatutLot.disponible,
      ),
      attributions: (map['attributions'] as List<dynamic>? ?? [])
          .map((a) => AttributionPartielle.fromMap(a as Map<String, dynamic>))
          .toList(),
      observations: map['observations'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeroLot': numeroLot,
      'siteOrigine': siteOrigine,
      'typeEmballage': typeEmballage,
      'predominanceFlorale': predominanceFlorale,
      'contenanceKg': contenanceKg,
      'prixUnitaire': prixUnitaire,
      'quantiteInitiale': quantiteInitiale,
      'quantiteRestante': quantiteRestante,
      'quantiteAttribuee': quantiteAttribuee,
      'dateConditionnement': Timestamp.fromDate(dateConditionnement),
      'dateExpiration': Timestamp.fromDate(dateExpiration),
      'statut': statut.name,
      'attributions': attributions.map((a) => a.toMap()).toList(),
      'observations': observations,
      'lastUpdate': FieldValue.serverTimestamp(),
      'searchableText': _generateSearchableText(),
    };
  }

  /// Génère du texte recherchable pour l'indexation
  String _generateSearchableText() {
    return '$numeroLot $siteOrigine $typeEmballage $predominanceFlorale'
        .toLowerCase();
  }

  /// Calcule la valeur totale restante
  double get valeurRestante => quantiteRestante * prixUnitaire;

  /// Calcule la valeur totale attribuée
  double get valeurAttribuee => quantiteAttribuee * prixUnitaire;

  /// Calcule le pourcentage d'attribution
  double get pourcentageAttribution =>
      quantiteInitiale > 0 ? (quantiteAttribuee / quantiteInitiale) * 100 : 0.0;

  /// Vérifie si le lot est complètement attribué
  bool get estCompletementAttribue => quantiteRestante <= 0;

  /// Vérifie si le lot est partiellement attribué
  bool get estPartiellementAttribue =>
      quantiteAttribuee > 0 && quantiteRestante > 0;

  /// Vérifie si le lot est proche de l'expiration (moins de 3 mois)
  bool get estProcheExpiration {
    final maintenant = DateTime.now();
    final diffJours = dateExpiration.difference(maintenant).inDays;
    return diffJours <= 90 && diffJours > 0;
  }

  /// Crée une copie avec des modifications
  LotProduit copyWith({
    String? id,
    String? numeroLot,
    String? siteOrigine,
    String? typeEmballage,
    String? predominanceFlorale,
    double? contenanceKg,
    double? prixUnitaire,
    int? quantiteInitiale,
    int? quantiteRestante,
    int? quantiteAttribuee,
    DateTime? dateConditionnement,
    DateTime? dateExpiration,
    StatutLot? statut,
    List<AttributionPartielle>? attributions,
    String? observations,
  }) {
    return LotProduit(
      id: id ?? this.id,
      numeroLot: numeroLot ?? this.numeroLot,
      siteOrigine: siteOrigine ?? this.siteOrigine,
      typeEmballage: typeEmballage ?? this.typeEmballage,
      predominanceFlorale: predominanceFlorale ?? this.predominanceFlorale,
      contenanceKg: contenanceKg ?? this.contenanceKg,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      quantiteInitiale: quantiteInitiale ?? this.quantiteInitiale,
      quantiteRestante: quantiteRestante ?? this.quantiteRestante,
      quantiteAttribuee: quantiteAttribuee ?? this.quantiteAttribuee,
      dateConditionnement: dateConditionnement ?? this.dateConditionnement,
      dateExpiration: dateExpiration ?? this.dateExpiration,
      statut: statut ?? this.statut,
      attributions: attributions ?? this.attributions,
      observations: observations ?? this.observations,
    );
  }
}

// ============================================================================
// 🏷️ ATTRIBUTION PARTIELLE D'UN LOT
// ============================================================================

/// Représente l'attribution d'une partie d'un lot à un commercial
class AttributionPartielle {
  final String id;
  final String lotId;
  final String commercialId;
  final String commercialNom;
  final int quantiteAttribuee;
  final double valeurUnitaire;
  final double valeurTotale;
  final DateTime dateAttribution;
  final String gestionnaire;
  final String? motifModification;
  final DateTime? dateDerniereModification;

  // Nouveaux champs selon les spécifications
  final double contenanceKg;
  final DateTime dateConditionnement;
  final String numeroLot;
  final String predominanceFlorale;
  final double prixUnitaire;
  final int quantiteInitiale;
  final int quantiteRestante;
  final String searchableText;
  final String siteOrigine;
  final String statut;
  final String typeEmballage;
  final String? observations;
  final DateTime lastUpdate;

  const AttributionPartielle({
    required this.id,
    required this.lotId,
    required this.commercialId,
    required this.commercialNom,
    required this.quantiteAttribuee,
    required this.valeurUnitaire,
    required this.valeurTotale,
    required this.dateAttribution,
    required this.gestionnaire,
    this.motifModification,
    this.dateDerniereModification,
    // Nouveaux champs
    required this.contenanceKg,
    required this.dateConditionnement,
    required this.numeroLot,
    required this.predominanceFlorale,
    required this.prixUnitaire,
    required this.quantiteInitiale,
    required this.quantiteRestante,
    required this.searchableText,
    required this.siteOrigine,
    required this.statut,
    required this.typeEmballage,
    this.observations,
    required this.lastUpdate,
  });

  factory AttributionPartielle.fromMap(Map<String, dynamic> map) {
    return AttributionPartielle(
      id: map['id'] ?? '',
      lotId: map['lotId'] ?? '',
      commercialId: map['commercialId'] ?? '',
      commercialNom: map['commercialNom'] ?? '',
      quantiteAttribuee: map['quantiteAttribuee'] ?? 0,
      valeurUnitaire: (map['valeurUnitaire'] ?? 0.0).toDouble(),
      valeurTotale: (map['valeurTotale'] ?? 0.0).toDouble(),
      dateAttribution:
          (map['dateAttribution'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gestionnaire: map['gestionnaire'] ?? '',
      motifModification: map['motifModification'],
      dateDerniereModification:
          (map['dateDerniereModification'] as Timestamp?)?.toDate(),
      // Nouveaux champs
      contenanceKg: (map['contenanceKg'] ?? 0.0).toDouble(),
      dateConditionnement:
          (map['dateConditionnement'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      numeroLot: map['numeroLot'] ?? '',
      predominanceFlorale: map['predominanceFlorale'] ?? '',
      prixUnitaire: (map['prixUnitaire'] ?? 0.0).toDouble(),
      quantiteInitiale: map['quantiteInitiale'] ?? 0,
      quantiteRestante: map['quantiteRestante'] ?? 0,
      searchableText: map['searchableText'] ?? '',
      siteOrigine: map['siteOrigine'] ?? '',
      statut: map['statut'] ?? '',
      typeEmballage: map['typeEmballage'] ?? '',
      observations: map['observations'],
      lastUpdate: (map['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lotId': lotId,
      'commercialId': commercialId,
      'commercialNom': commercialNom,
      'quantiteAttribuee': quantiteAttribuee,
      'valeurUnitaire': valeurUnitaire,
      'valeurTotale': valeurTotale,
      'dateAttribution': Timestamp.fromDate(dateAttribution),
      'gestionnaire': gestionnaire,
      'motifModification': motifModification,
      'dateDerniereModification': dateDerniereModification != null
          ? Timestamp.fromDate(dateDerniereModification!)
          : null,
      // Nouveaux champs
      'contenanceKg': contenanceKg,
      'dateConditionnement': Timestamp.fromDate(dateConditionnement),
      'numeroLot': numeroLot,
      'predominanceFlorale': predominanceFlorale,
      'prixUnitaire': prixUnitaire,
      'quantiteInitiale': quantiteInitiale,
      'quantiteRestante': quantiteRestante,
      'searchableText': searchableText,
      'siteOrigine': siteOrigine,
      'statut': statut,
      'typeEmballage': typeEmballage,
      'observations': observations,
      'lastUpdate': Timestamp.fromDate(lastUpdate),
    };
  }
}

// ============================================================================
// 📊 STATISTIQUES COMMERCIALES AVANCÉES
// ============================================================================

/// Statistiques détaillées pour l'analyse commerciale
class StatistiquesCommerciales {
  final DateTime periodeDebut;
  final DateTime periodeFin;
  final int nombreLots;
  final int nombreAttributions;
  final double valeurTotaleStock;
  final double valeurTotaleAttribuee;
  final double valeurTotaleRestante;
  final double tauxAttribution; // En pourcentage
  final Map<String, StatistiquesCommercial> performancesCommerciaux;
  final Map<String, StatistiquesSite> repartitionSites;
  final Map<String, StatistiquesEmballage> repartitionEmballages;
  final Map<String, StatistiquesFlorale> repartitionFlorale;
  final List<TendanceMensuelle> tendancesMensuelles;
  final DateTime derniereMAJ;

  const StatistiquesCommerciales({
    required this.periodeDebut,
    required this.periodeFin,
    required this.nombreLots,
    required this.nombreAttributions,
    required this.valeurTotaleStock,
    required this.valeurTotaleAttribuee,
    required this.valeurTotaleRestante,
    required this.tauxAttribution,
    required this.performancesCommerciaux,
    required this.repartitionSites,
    required this.repartitionEmballages,
    required this.repartitionFlorale,
    required this.tendancesMensuelles,
    required this.derniereMAJ,
  });

  factory StatistiquesCommerciales.fromMap(Map<String, dynamic> map) {
    return StatistiquesCommerciales(
      periodeDebut: (map['periodeDebut'] as Timestamp).toDate(),
      periodeFin: (map['periodeFin'] as Timestamp).toDate(),
      nombreLots: map['nombreLots'] ?? 0,
      nombreAttributions: map['nombreAttributions'] ?? 0,
      valeurTotaleStock: (map['valeurTotaleStock'] ?? 0.0).toDouble(),
      valeurTotaleAttribuee: (map['valeurTotaleAttribuee'] ?? 0.0).toDouble(),
      valeurTotaleRestante: (map['valeurTotaleRestante'] ?? 0.0).toDouble(),
      tauxAttribution: (map['tauxAttribution'] ?? 0.0).toDouble(),
      performancesCommerciaux: Map<String, StatistiquesCommercial>.from(
          (map['performancesCommerciaux'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, StatistiquesCommercial.fromMap(v)))),
      repartitionSites: Map<String, StatistiquesSite>.from(
          (map['repartitionSites'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, StatistiquesSite.fromMap(v)))),
      repartitionEmballages: Map<String, StatistiquesEmballage>.from(
          (map['repartitionEmballages'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, StatistiquesEmballage.fromMap(v)))),
      repartitionFlorale: Map<String, StatistiquesFlorale>.from(
          (map['repartitionFlorale'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, StatistiquesFlorale.fromMap(v)))),
      tendancesMensuelles: (map['tendancesMensuelles'] as List<dynamic>? ?? [])
          .map((t) => TendanceMensuelle.fromMap(t))
          .toList(),
      derniereMAJ: (map['derniereMAJ'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'periodeDebut': Timestamp.fromDate(periodeDebut),
      'periodeFin': Timestamp.fromDate(periodeFin),
      'nombreLots': nombreLots,
      'nombreAttributions': nombreAttributions,
      'valeurTotaleStock': valeurTotaleStock,
      'valeurTotaleAttribuee': valeurTotaleAttribuee,
      'valeurTotaleRestante': valeurTotaleRestante,
      'tauxAttribution': tauxAttribution,
      'performancesCommerciaux':
          performancesCommerciaux.map((k, v) => MapEntry(k, v.toMap())),
      'repartitionSites':
          repartitionSites.map((k, v) => MapEntry(k, v.toMap())),
      'repartitionEmballages':
          repartitionEmballages.map((k, v) => MapEntry(k, v.toMap())),
      'repartitionFlorale':
          repartitionFlorale.map((k, v) => MapEntry(k, v.toMap())),
      'tendancesMensuelles': tendancesMensuelles.map((t) => t.toMap()).toList(),
      'derniereMAJ': Timestamp.fromDate(derniereMAJ),
    };
  }
}

/// Statistiques par commercial
class StatistiquesCommercial {
  final String commercialId;
  final String commercialNom;
  final int nombreAttributions;
  final double valeurTotaleAttribuee;
  final int nombreVentes;
  final double chiffreAffaires;
  final double tauxConversion;
  final double moyenneVenteParAttribution;

  const StatistiquesCommercial({
    required this.commercialId,
    required this.commercialNom,
    required this.nombreAttributions,
    required this.valeurTotaleAttribuee,
    required this.nombreVentes,
    required this.chiffreAffaires,
    required this.tauxConversion,
    required this.moyenneVenteParAttribution,
  });

  factory StatistiquesCommercial.fromMap(Map<String, dynamic> map) {
    return StatistiquesCommercial(
      commercialId: map['commercialId'] ?? '',
      commercialNom: map['commercialNom'] ?? '',
      nombreAttributions: map['nombreAttributions'] ?? 0,
      valeurTotaleAttribuee: (map['valeurTotaleAttribuee'] ?? 0.0).toDouble(),
      nombreVentes: map['nombreVentes'] ?? 0,
      chiffreAffaires: (map['chiffreAffaires'] ?? 0.0).toDouble(),
      tauxConversion: (map['tauxConversion'] ?? 0.0).toDouble(),
      moyenneVenteParAttribution:
          (map['moyenneVenteParAttribution'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commercialId': commercialId,
      'commercialNom': commercialNom,
      'nombreAttributions': nombreAttributions,
      'valeurTotaleAttribuee': valeurTotaleAttribuee,
      'nombreVentes': nombreVentes,
      'chiffreAffaires': chiffreAffaires,
      'tauxConversion': tauxConversion,
      'moyenneVenteParAttribution': moyenneVenteParAttribution,
    };
  }
}

/// Statistiques par site
class StatistiquesSite {
  final String site;
  final int nombreLots;
  final double valeurStock;
  final double valeurAttribuee;
  final double tauxAttribution;

  const StatistiquesSite({
    required this.site,
    required this.nombreLots,
    required this.valeurStock,
    required this.valeurAttribuee,
    required this.tauxAttribution,
  });

  factory StatistiquesSite.fromMap(Map<String, dynamic> map) {
    return StatistiquesSite(
      site: map['site'] ?? '',
      nombreLots: map['nombreLots'] ?? 0,
      valeurStock: (map['valeurStock'] ?? 0.0).toDouble(),
      valeurAttribuee: (map['valeurAttribuee'] ?? 0.0).toDouble(),
      tauxAttribution: (map['tauxAttribution'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'site': site,
      'nombreLots': nombreLots,
      'valeurStock': valeurStock,
      'valeurAttribuee': valeurAttribuee,
      'tauxAttribution': tauxAttribution,
    };
  }
}

/// Statistiques par type d'emballage
class StatistiquesEmballage {
  final String typeEmballage;
  final int nombreLots;
  final int quantiteStock;
  final int quantiteAttribuee;
  final double valeurStock;
  final double valeurAttribuee;

  const StatistiquesEmballage({
    required this.typeEmballage,
    required this.nombreLots,
    required this.quantiteStock,
    required this.quantiteAttribuee,
    required this.valeurStock,
    required this.valeurAttribuee,
  });

  factory StatistiquesEmballage.fromMap(Map<String, dynamic> map) {
    return StatistiquesEmballage(
      typeEmballage: map['typeEmballage'] ?? '',
      nombreLots: map['nombreLots'] ?? 0,
      quantiteStock: map['quantiteStock'] ?? 0,
      quantiteAttribuee: map['quantiteAttribuee'] ?? 0,
      valeurStock: (map['valeurStock'] ?? 0.0).toDouble(),
      valeurAttribuee: (map['valeurAttribuee'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'typeEmballage': typeEmballage,
      'nombreLots': nombreLots,
      'quantiteStock': quantiteStock,
      'quantiteAttribuee': quantiteAttribuee,
      'valeurStock': valeurStock,
      'valeurAttribuee': valeurAttribuee,
    };
  }
}

/// Statistiques par prédominance florale
class StatistiquesFlorale {
  final String predominance;
  final int nombreLots;
  final double valeurStock;
  final double valeurAttribuee;
  final double prixMoyenUnitaire;

  const StatistiquesFlorale({
    required this.predominance,
    required this.nombreLots,
    required this.valeurStock,
    required this.valeurAttribuee,
    required this.prixMoyenUnitaire,
  });

  factory StatistiquesFlorale.fromMap(Map<String, dynamic> map) {
    return StatistiquesFlorale(
      predominance: map['predominance'] ?? '',
      nombreLots: map['nombreLots'] ?? 0,
      valeurStock: (map['valeurStock'] ?? 0.0).toDouble(),
      valeurAttribuee: (map['valeurAttribuee'] ?? 0.0).toDouble(),
      prixMoyenUnitaire: (map['prixMoyenUnitaire'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'predominance': predominance,
      'nombreLots': nombreLots,
      'valeurStock': valeurStock,
      'valeurAttribuee': valeurAttribuee,
      'prixMoyenUnitaire': prixMoyenUnitaire,
    };
  }
}

/// Tendance mensuelle pour les graphiques
class TendanceMensuelle {
  final int annee;
  final int mois;
  final int nombreAttributions;
  final double valeurAttribuee;
  final int nombreVentes;
  final double chiffreAffaires;

  const TendanceMensuelle({
    required this.annee,
    required this.mois,
    required this.nombreAttributions,
    required this.valeurAttribuee,
    required this.nombreVentes,
    required this.chiffreAffaires,
  });

  factory TendanceMensuelle.fromMap(Map<String, dynamic> map) {
    return TendanceMensuelle(
      annee: map['annee'] ?? 0,
      mois: map['mois'] ?? 0,
      nombreAttributions: map['nombreAttributions'] ?? 0,
      valeurAttribuee: (map['valeurAttribuee'] ?? 0.0).toDouble(),
      nombreVentes: map['nombreVentes'] ?? 0,
      chiffreAffaires: (map['chiffreAffaires'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'annee': annee,
      'mois': mois,
      'nombreAttributions': nombreAttributions,
      'valeurAttribuee': valeurAttribuee,
      'nombreVentes': nombreVentes,
      'chiffreAffaires': chiffreAffaires,
    };
  }

  String get libelleMois {
    const moisLabels = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return moisLabels[mois];
  }
}

// ============================================================================
// 🎯 FILTRES ET CRITÈRES DE RECHERCHE
// ============================================================================

/// Critères de filtrage pour la recherche de lots
class CriteresFiltrage {
  final String? site;
  final String? typeEmballage;
  final String? predominanceFlorale;
  final StatutLot? statut;
  final String? commercial;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final double? prixMin;
  final double? prixMax;
  final int? quantiteMin;
  final int? quantiteMax;
  final bool? seulementsRestes;
  final bool? seulementsExpires;
  final String? texteRecherche;

  const CriteresFiltrage({
    this.site,
    this.typeEmballage,
    this.predominanceFlorale,
    this.statut,
    this.commercial,
    this.dateDebut,
    this.dateFin,
    this.prixMin,
    this.prixMax,
    this.quantiteMin,
    this.quantiteMax,
    this.seulementsRestes,
    this.seulementsExpires,
    this.texteRecherche,
  });

  CriteresFiltrage copyWith({
    String? site,
    String? typeEmballage,
    String? predominanceFlorale,
    StatutLot? statut,
    String? commercial,
    DateTime? dateDebut,
    DateTime? dateFin,
    double? prixMin,
    double? prixMax,
    int? quantiteMin,
    int? quantiteMax,
    bool? seulementsRestes,
    bool? seulementsExpires,
    String? texteRecherche,
  }) {
    return CriteresFiltrage(
      site: site ?? this.site,
      typeEmballage: typeEmballage ?? this.typeEmballage,
      predominanceFlorale: predominanceFlorale ?? this.predominanceFlorale,
      statut: statut ?? this.statut,
      commercial: commercial ?? this.commercial,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      prixMin: prixMin ?? this.prixMin,
      prixMax: prixMax ?? this.prixMax,
      quantiteMin: quantiteMin ?? this.quantiteMin,
      quantiteMax: quantiteMax ?? this.quantiteMax,
      seulementsRestes: seulementsRestes ?? this.seulementsRestes,
      seulementsExpires: seulementsExpires ?? this.seulementsExpires,
      texteRecherche: texteRecherche ?? this.texteRecherche,
    );
  }

  bool get hasFilters {
    return site != null ||
        typeEmballage != null ||
        predominanceFlorale != null ||
        statut != null ||
        commercial != null ||
        dateDebut != null ||
        dateFin != null ||
        prixMin != null ||
        prixMax != null ||
        quantiteMin != null ||
        quantiteMax != null ||
        seulementsRestes != null ||
        seulementsExpires != null ||
        (texteRecherche?.isNotEmpty ?? false);
  }
}

// ============================================================================
// 📱 CACHE POUR PERFORMANCES ULTRA
// ============================================================================

/// Cache intelligent pour optimiser les performances
class CacheCommercial {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  static T? get<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheDuration) {
      return _cache[key] as T?;
    }

    // Cache expiré
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    return null;
  }

  static void set<T>(String key, T value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  static void clear([String? key]) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  static void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) >= _cacheDuration)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
}

// ============================================================================
// 📋 ENUMS ET UTILITAIRES
// ============================================================================

enum StatutLot {
  disponible,
  partielAttribue,
  completAttribue,
  expire,
  suspendu,
}

enum TypeAttributionModification {
  creation,
  augmentation,
  diminution,
  suppression,
  transfert,
}

// ============================================================================
// 👤 MODÈLES CLIENTS
// ============================================================================

class Client {
  final String id;
  final String nom;
  final String? prenom;
  final String telephone;
  final String? email;
  final String adresse;
  final String ville;
  final String? quartier;
  final String typeClient; // particulier, entreprise, revendeur
  final DateTime dateCreation;
  final String site;
  final bool actif;
  final String? notes;
  // 📍 Localisation (optionnelle)
  final double? latitude;
  final double? longitude;
  final double? altitude; // Peut être null selon la plateforme
  final double? precision; // horizontal accuracy en mètres

  const Client({
    required this.id,
    required this.nom,
    this.prenom,
    required this.telephone,
    this.email,
    required this.adresse,
    required this.ville,
    this.quartier,
    required this.typeClient,
    required this.dateCreation,
    required this.site,
    this.actif = true,
    this.notes,
    this.latitude,
    this.longitude,
    this.altitude,
    this.precision,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'],
      telephone: map['telephone'] ?? '',
      email: map['email'],
      adresse: map['adresse'] ?? '',
      ville: map['ville'] ?? '',
      quartier: map['quartier'],
      typeClient: map['typeClient'] ?? 'particulier',
      dateCreation:
          (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      site: map['site'] ?? '',
      actif: map['actif'] ?? true,
      notes: map['notes'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      precision: (map['precision'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'ville': ville,
      'quartier': quartier,
      'typeClient': typeClient,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'site': site,
      'actif': actif,
      'notes': notes,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      if (precision != null) 'precision': precision,
    };
  }

  String get nomComplet => prenom != null ? '$prenom $nom' : nom;

  String get searchableText =>
      '${nomComplet.toLowerCase()} ${telephone.toLowerCase()} ${adresse.toLowerCase()}'
          .toLowerCase();
}

class VenteClient {
  final String id;
  final String clientId;
  final String commercialId;
  final String commercialNom;
  final List<ProduitVente> produits;
  final double montantTotal;
  final double montantPaye;
  final double montantDu;
  final String modePaiement;
  final String statut; // en_cours, paye, annule
  final DateTime dateVente;
  final String site;
  final String? notes;
  final String gestionnaire;

  const VenteClient({
    required this.id,
    required this.clientId,
    required this.commercialId,
    required this.commercialNom,
    required this.produits,
    required this.montantTotal,
    required this.montantPaye,
    required this.montantDu,
    required this.modePaiement,
    required this.statut,
    required this.dateVente,
    required this.site,
    this.notes,
    required this.gestionnaire,
  });

  factory VenteClient.fromMap(Map<String, dynamic> map) {
    return VenteClient(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      commercialId: map['commercialId'] ?? '',
      commercialNom: map['commercialNom'] ?? '',
      produits: (map['produits'] as List<dynamic>? ?? [])
          .map((p) => ProduitVente.fromMap(p))
          .toList(),
      montantTotal: (map['montantTotal'] ?? 0.0).toDouble(),
      montantPaye: (map['montantPaye'] ?? 0.0).toDouble(),
      montantDu: (map['montantDu'] ?? 0.0).toDouble(),
      modePaiement: map['modePaiement'] ?? '',
      statut: map['statut'] ?? '',
      dateVente: (map['dateVente'] as Timestamp?)?.toDate() ?? DateTime.now(),
      site: map['site'] ?? '',
      notes: map['notes'],
      gestionnaire: map['gestionnaire'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'commercialId': commercialId,
      'commercialNom': commercialNom,
      'produits': produits.map((p) => p.toMap()).toList(),
      'montantTotal': montantTotal,
      'montantPaye': montantPaye,
      'montantDu': montantDu,
      'modePaiement': modePaiement,
      'statut': statut,
      'dateVente': Timestamp.fromDate(dateVente),
      'site': site,
      'notes': notes,
      'gestionnaire': gestionnaire,
    };
  }
}

class ProduitVente {
  final String lotId;
  final String typeEmballage;
  final String numeroLot;
  final int quantite;
  final double prixUnitaire;
  final double montantTotal;

  const ProduitVente({
    required this.lotId,
    required this.typeEmballage,
    required this.numeroLot,
    required this.quantite,
    required this.prixUnitaire,
    required this.montantTotal,
  });

  factory ProduitVente.fromMap(Map<String, dynamic> map) {
    return ProduitVente(
      lotId: map['lotId'] ?? '',
      typeEmballage: map['typeEmballage'] ?? '',
      numeroLot: map['numeroLot'] ?? '',
      quantite: map['quantite'] ?? 0,
      prixUnitaire: (map['prixUnitaire'] ?? 0.0).toDouble(),
      montantTotal: (map['montantTotal'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lotId': lotId,
      'typeEmballage': typeEmballage,
      'numeroLot': numeroLot,
      'quantite': quantite,
      'prixUnitaire': prixUnitaire,
      'montantTotal': montantTotal,
    };
  }
}

// ============================================================================
// 🔧 UTILITAIRES
// ============================================================================

/// Utilitaires pour la gestion commerciale
class CommercialUtils {
  /// Formate un prix avec séparateurs de milliers
  static String formatPrix(double prix) {
    return '${prix.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]} ',
        )} FCFA';
  }

  /// Formate un pourcentage avec une décimale
  static String formatPourcentage(double pourcentage) {
    return '${pourcentage.toStringAsFixed(1)}%';
  }

  /// Retourne la couleur selon le statut du lot
  static Color getCouleurStatut(StatutLot statut) {
    switch (statut) {
      case StatutLot.disponible:
        return const Color(0xFF4CAF50);
      case StatutLot.partielAttribue:
        return const Color(0xFF2196F3);
      case StatutLot.completAttribue:
        return const Color(0xFF9C27B0);
      case StatutLot.expire:
        return const Color(0xFFF44336);
      case StatutLot.suspendu:
        return const Color(0xFF795548);
    }
  }

  /// Retourne le libellé du statut
  static String getLibelleStatut(StatutLot statut) {
    switch (statut) {
      case StatutLot.disponible:
        return 'Disponible';
      case StatutLot.partielAttribue:
        return 'Partiellement attribué';
      case StatutLot.completAttribue:
        return 'Complètement attribué';
      case StatutLot.expire:
        return 'Expiré';
      case StatutLot.suspendu:
        return 'Suspendu';
    }
  }

  /// Génère un ID unique pour les attributions
  static String genererIdAttribution() {
    return 'ATTR_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Génère un ID unique pour les lots
  static String genererIdLot(String site, String typeEmballage,
      [String? numeroLot]) {
    final siteCode = site.substring(0, 3).toUpperCase();
    final typeCode = _getCodeEmballage(typeEmballage);
    final lotCode =
        numeroLot?.replaceAll('-', '_').replaceAll(' ', '_') ?? 'UNKNOWN';
    return 'LOT_${siteCode}_${typeCode}_$lotCode';
  }

  static String _getCodeEmballage(String typeEmballage) {
    final Map<String, String> codes = {
      'Pot 1kg': 'P1K',
      '1Kg': 'P1K',
      'Pot 1.5kg': 'P15',
      'Pot 720g': '720',
      'Pot 500g': '500',
      '500g': '500',
      'Pot 250g': '250',
      'Pot alvéoles 30g': 'A30',
      'Stick 20g': 'S20',
      '7kg': '7KG',
    };
    return codes[typeEmballage] ?? 'UNK';
  }

  /// Calcule le score de performance d'un commercial
  static double calculerScorePerformance(StatistiquesCommercial stats) {
    // Score basé sur le taux de conversion et le chiffre d'affaires
    final scoreConversion = stats.tauxConversion * 0.6;
    final scoreChiffre =
        (stats.chiffreAffaires / 1000000) * 0.4; // Par million de FCFA
    return (scoreConversion + scoreChiffre).clamp(0.0, 100.0);
  }

  /// Détermine la couleur de performance
  static Color getCouleurPerformance(double score) {
    if (score >= 80) return const Color(0xFF4CAF50); // Vert - Excellente
    if (score >= 60) return const Color(0xFF2196F3); // Bleu - Bonne
    if (score >= 40) return const Color(0xFFFF9800); // Orange - Moyenne
    return const Color(0xFFF44336); // Rouge - Faible
  }

  /// Retourne l'emoji selon le type d'emballage
  static String getEmojiEmballage(String typeEmballage) {
    final Map<String, String> emojis = {
      'Pot 1kg': '🍯',
      'Pot 1.5kg': '🍯',
      'Pot 720g': '🫙',
      'Pot 500g': '🫙',
      'Pot 250g': '🫙',
      'Pot alvéoles 30g': '🥣',
      'Stick 20g': '🥢',
      '7kg': '🪣',
    };
    return emojis[typeEmballage] ?? '📦';
  }
}
