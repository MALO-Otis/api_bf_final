/// 🟫 MODÈLES AMÉLIORÉS POUR L'EXTRACTION
///
/// Ces modèles s'intègrent parfaitement avec le nouveau système
/// d'attribution unifié pour une gestion complète des extractions

import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Statut d'un processus d'extraction
enum ExtractionStatus {
  enAttente('En Attente', 'waiting'),
  enCours('En Cours', 'in_progress'),
  suspendu('Suspendu', 'suspended'),
  termine('Terminé', 'completed'),
  erreur('Erreur', 'error');

  const ExtractionStatus(this.label, this.value);
  final String label;
  final String value;
}

/// Priorité d'extraction
enum ExtractionPriority {
  normale('Normale', 'normal'),
  urgente('Urgente', 'urgent'),
  critique('Critique', 'critical');

  const ExtractionPriority(this.label, this.value);
  final String label;
  final String value;
}

/// Modèle pour un processus d'extraction en cours
class ExtractionProcess {
  final String id;
  final ProductControle produit;
  final String extracteur;
  final DateTime dateDebut;
  final ExtractionStatus statut;
  final ExtractionPriority priorite;
  final String? instructions;
  final String? observations;
  final DateTime? dateSuspension;
  final String site;
  final Map<String, dynamic>? metadata;

  const ExtractionProcess({
    required this.id,
    required this.produit,
    required this.extracteur,
    required this.dateDebut,
    required this.statut,
    this.priorite = ExtractionPriority.normale,
    this.instructions,
    this.observations,
    this.dateSuspension,
    required this.site,
    this.metadata,
  });

  /// Durée écoulée depuis le début
  Duration get dureeEcoulee => DateTime.now().difference(dateDebut);

  /// Vérifie si l'extraction est urgente (> 4h)
  bool get isUrgent => dureeEcoulee.inHours > 4;

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produit': produit.toMap(),
      'extracteur': extracteur,
      'dateDebut': dateDebut.toIso8601String(),
      'statut': statut.value,
      'priorite': priorite.value,
      'instructions': instructions,
      'observations': observations,
      'dateSuspension': dateSuspension?.toIso8601String(),
      'site': site,
      'metadata': metadata,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Création depuis Map Firestore
  factory ExtractionProcess.fromMap(Map<String, dynamic> map) {
    return ExtractionProcess(
      id: map['id'] ?? '',
      produit: ProductControle.fromMap(map['produit'] ?? {}),
      extracteur: map['extracteur'] ?? '',
      dateDebut:
          DateTime.parse(map['dateDebut'] ?? DateTime.now().toIso8601String()),
      statut: ExtractionStatus.values.firstWhere(
        (s) => s.value == map['statut'],
        orElse: () => ExtractionStatus.enAttente,
      ),
      priorite: ExtractionPriority.values.firstWhere(
        (p) => p.value == map['priorite'],
        orElse: () => ExtractionPriority.normale,
      ),
      instructions: map['instructions'],
      observations: map['observations'],
      dateSuspension: map['dateSuspension'] != null
          ? DateTime.parse(map['dateSuspension'])
          : null,
      site: map['site'] ?? '',
      metadata: map['metadata'],
    );
  }

  /// Crée une copie avec des modifications
  ExtractionProcess copyWith({
    String? id,
    ProductControle? produit,
    String? extracteur,
    DateTime? dateDebut,
    ExtractionStatus? statut,
    ExtractionPriority? priorite,
    String? instructions,
    String? observations,
    DateTime? dateSuspension,
    String? site,
    Map<String, dynamic>? metadata,
  }) {
    return ExtractionProcess(
      id: id ?? this.id,
      produit: produit ?? this.produit,
      extracteur: extracteur ?? this.extracteur,
      dateDebut: dateDebut ?? this.dateDebut,
      statut: statut ?? this.statut,
      priorite: priorite ?? this.priorite,
      instructions: instructions ?? this.instructions,
      observations: observations ?? this.observations,
      dateSuspension: dateSuspension ?? this.dateSuspension,
      site: site ?? this.site,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Modèle pour le résultat d'une extraction terminée
class ExtractionResult {
  final String id;
  final ProductControle produit;
  final String extracteur;
  final DateTime dateDebut;
  final DateTime dateFin;
  final Duration duree;
  final double poidsInitial;
  final double poidsExtrait;
  final double rendement; // Pourcentage
  final String qualite;
  final String? observations;
  final String site;
  final Map<String, dynamic>? analyses;
  final bool isValidated;

  const ExtractionResult({
    required this.id,
    required this.produit,
    required this.extracteur,
    required this.dateDebut,
    required this.dateFin,
    required this.duree,
    required this.poidsInitial,
    required this.poidsExtrait,
    required this.rendement,
    required this.qualite,
    this.observations,
    required this.site,
    this.analyses,
    this.isValidated = false,
  });

  /// Calcule le taux de perte
  double get tauxPerte => poidsInitial > 0
      ? ((poidsInitial - poidsExtrait) / poidsInitial) * 100
      : 0.0;

  /// Évalue la qualité du rendement
  String get evaluationRendement {
    if (rendement >= 90) return 'Excellent';
    if (rendement >= 80) return 'Très Bon';
    if (rendement >= 70) return 'Bon';
    if (rendement >= 60) return 'Acceptable';
    return 'Faible';
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produit': produit.toMap(),
      'extracteur': extracteur,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'dureeMinutes': duree.inMinutes,
      'poidsInitial': poidsInitial,
      'poidsExtrait': poidsExtrait,
      'rendement': rendement,
      'tauxPerte': tauxPerte,
      'qualite': qualite,
      'observations': observations,
      'site': site,
      'analyses': analyses,
      'isValidated': isValidated,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Création depuis Map Firestore
  factory ExtractionResult.fromMap(Map<String, dynamic> map) {
    return ExtractionResult(
      id: map['id'] ?? '',
      produit: ProductControle.fromMap(map['produit'] ?? {}),
      extracteur: map['extracteur'] ?? '',
      dateDebut:
          DateTime.parse(map['dateDebut'] ?? DateTime.now().toIso8601String()),
      dateFin:
          DateTime.parse(map['dateFin'] ?? DateTime.now().toIso8601String()),
      duree: Duration(minutes: map['dureeMinutes'] ?? 0),
      poidsInitial: (map['poidsInitial'] as num?)?.toDouble() ?? 0.0,
      poidsExtrait: (map['poidsExtrait'] as num?)?.toDouble() ?? 0.0,
      rendement: (map['rendement'] as num?)?.toDouble() ?? 0.0,
      qualite: map['qualite'] ?? '',
      observations: map['observations'],
      site: map['site'] ?? '',
      analyses: map['analyses'],
      isValidated: map['isValidated'] ?? false,
    );
  }

  /// Crée une copie avec des modifications
  ExtractionResult copyWith({
    String? id,
    ProductControle? produit,
    String? extracteur,
    DateTime? dateDebut,
    DateTime? dateFin,
    Duration? duree,
    double? poidsInitial,
    double? poidsExtrait,
    double? rendement,
    String? qualite,
    String? observations,
    String? site,
    Map<String, dynamic>? analyses,
    bool? isValidated,
  }) {
    return ExtractionResult(
      id: id ?? this.id,
      produit: produit ?? this.produit,
      extracteur: extracteur ?? this.extracteur,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      duree: duree ?? this.duree,
      poidsInitial: poidsInitial ?? this.poidsInitial,
      poidsExtrait: poidsExtrait ?? this.poidsExtrait,
      rendement: rendement ?? this.rendement,
      qualite: qualite ?? this.qualite,
      observations: observations ?? this.observations,
      site: site ?? this.site,
      analyses: analyses ?? this.analyses,
      isValidated: isValidated ?? this.isValidated,
    );
  }
}

/// Modèle pour les statistiques d'extraction
class ExtractionStats {
  final int totalAttribues;
  final int enCours;
  final int terminees;
  final int suspendues;
  final double poidsTotal;
  final double poidsExtrait;
  final double rendementMoyen;
  final Duration dureeMoyenne;
  final int urgents;
  final Map<String, int> parExtracteur;
  final Map<String, double> parQualite;

  const ExtractionStats({
    required this.totalAttribues,
    required this.enCours,
    required this.terminees,
    required this.suspendues,
    required this.poidsTotal,
    required this.poidsExtrait,
    required this.rendementMoyen,
    required this.dureeMoyenne,
    required this.urgents,
    required this.parExtracteur,
    required this.parQualite,
  });

  /// Taux de completion
  double get tauxCompletion =>
      totalAttribues > 0 ? (terminees / totalAttribues) * 100 : 0.0;

  /// Efficacité globale
  String get efficaciteGlobale {
    if (tauxCompletion >= 95 && rendementMoyen >= 85) return 'Excellente';
    if (tauxCompletion >= 90 && rendementMoyen >= 80) return 'Très Bonne';
    if (tauxCompletion >= 80 && rendementMoyen >= 75) return 'Bonne';
    if (tauxCompletion >= 70 && rendementMoyen >= 70) return 'Acceptable';
    return 'À Améliorer';
  }

  /// Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'totalAttribues': totalAttribues,
      'enCours': enCours,
      'terminees': terminees,
      'suspendues': suspendues,
      'poidsTotal': poidsTotal,
      'poidsExtrait': poidsExtrait,
      'rendementMoyen': rendementMoyen,
      'dureeMoyenneMinutes': dureeMoyenne.inMinutes,
      'urgents': urgents,
      'tauxCompletion': tauxCompletion,
      'efficaciteGlobale': efficaciteGlobale,
      'parExtracteur': parExtracteur,
      'parQualite': parQualite,
    };
  }
}

/// Filtres pour les extractions
class ExtractionFilters {
  final String? extracteur;
  final ExtractionStatus? statut;
  final ExtractionPriority? priorite;
  final String? qualite;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final double? rendementMin;
  final double? rendementMax;
  final bool? urgentOnly;
  final String? searchQuery;

  const ExtractionFilters({
    this.extracteur,
    this.statut,
    this.priorite,
    this.qualite,
    this.dateDebut,
    this.dateFin,
    this.rendementMin,
    this.rendementMax,
    this.urgentOnly,
    this.searchQuery,
  });

  /// Vérifie si un processus correspond aux filtres
  bool matchesProcess(ExtractionProcess process) {
    if (extracteur != null && process.extracteur != extracteur) return false;
    if (statut != null && process.statut != statut) return false;
    if (priorite != null && process.priorite != priorite) return false;
    if (dateDebut != null && process.dateDebut.isBefore(dateDebut!))
      return false;
    if (urgentOnly == true && !process.isUrgent) return false;

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!process.produit.producteur.toLowerCase().contains(query) &&
          !process.produit.codeContenant.toLowerCase().contains(query) &&
          !process.extracteur.toLowerCase().contains(query)) {
        return false;
      }
    }

    return true;
  }

  /// Vérifie si un résultat correspond aux filtres
  bool matchesResult(ExtractionResult result) {
    if (extracteur != null && result.extracteur != extracteur) return false;
    if (qualite != null && result.qualite != qualite) return false;
    if (dateDebut != null && result.dateFin.isBefore(dateDebut!)) return false;
    if (dateFin != null && result.dateFin.isAfter(dateFin!)) return false;
    if (rendementMin != null && result.rendement < rendementMin!) return false;
    if (rendementMax != null && result.rendement > rendementMax!) return false;

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!result.produit.producteur.toLowerCase().contains(query) &&
          !result.produit.codeContenant.toLowerCase().contains(query) &&
          !result.extracteur.toLowerCase().contains(query)) {
        return false;
      }
    }

    return true;
  }

  /// Compte le nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (extracteur != null) count++;
    if (statut != null) count++;
    if (priorite != null) count++;
    if (qualite != null) count++;
    if (dateDebut != null) count++;
    if (dateFin != null) count++;
    if (rendementMin != null) count++;
    if (rendementMax != null) count++;
    if (urgentOnly == true) count++;
    if (searchQuery?.isNotEmpty == true) count++;
    return count;
  }

  /// Crée une copie avec des modifications
  ExtractionFilters copyWith({
    String? extracteur,
    ExtractionStatus? statut,
    ExtractionPriority? priorite,
    String? qualite,
    DateTime? dateDebut,
    DateTime? dateFin,
    double? rendementMin,
    double? rendementMax,
    bool? urgentOnly,
    String? searchQuery,
  }) {
    return ExtractionFilters(
      extracteur: extracteur ?? this.extracteur,
      statut: statut ?? this.statut,
      priorite: priorite ?? this.priorite,
      qualite: qualite ?? this.qualite,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      rendementMin: rendementMin ?? this.rendementMin,
      rendementMax: rendementMax ?? this.rendementMax,
      urgentOnly: urgentOnly ?? this.urgentOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
