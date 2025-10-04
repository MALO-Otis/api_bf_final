/// Statut d'attribution
enum AttributionStatus {
  attribueExtraction('Attribué Extraction', 'attribue_extraction'),
  enCoursExtraction('En cours d\'extraction', 'en_cours_extraction'),
  extraitEnAttente('Extrait - En attente', 'extrait_en_attente'),
  attribueMaturation('Attribué Maturation', 'attribue_maturation'),
  enCoursMaturation('En cours de maturation', 'en_cours_maturation'),
  termineMaturation('Terminé - Maturation', 'termine_maturation'),
  annule('Annulé', 'annule');

  const AttributionStatus(this.label, this.value);
  final String label;
  final String value;

  /// Couleur associée au statut
  String get colorName {
    switch (this) {
      case AttributionStatus.attribueExtraction:
        return 'blue';
      case AttributionStatus.enCoursExtraction:
        return 'orange';
      case AttributionStatus.extraitEnAttente:
        return 'purple';
      case AttributionStatus.attribueMaturation:
        return 'teal';
      case AttributionStatus.enCoursMaturation:
        return 'indigo';
      case AttributionStatus.termineMaturation:
        return 'green';
      case AttributionStatus.annule:
        return 'red';
    }
  }
}

/// Modèle pour une attribution d'extraction/maturation
class AttributionExtraction {
  final String id;
  final DateTime dateAttribution;
  final String utilisateur;
  final String lotId;
  final List<String> listeContenants; // IDs des ExtractionProduct
  final AttributionStatus statut;
  final String? commentaires;
  final DateTime? dateModification;
  final String? utilisateurModification;
  final Map<String, dynamic> metadata; // Données supplémentaires

  AttributionExtraction({
    required this.id,
    required this.dateAttribution,
    required this.utilisateur,
    required this.lotId,
    required this.listeContenants,
    this.statut = AttributionStatus.attribueExtraction,
    this.commentaires,
    this.dateModification,
    this.utilisateurModification,
    this.metadata = const {},
  });

  /// Copie avec modifications
  AttributionExtraction copyWith({
    String? id,
    DateTime? dateAttribution,
    String? utilisateur,
    String? lotId,
    List<String>? listeContenants,
    AttributionStatus? statut,
    String? commentaires,
    DateTime? dateModification,
    String? utilisateurModification,
    Map<String, dynamic>? metadata,
  }) {
    return AttributionExtraction(
      id: id ?? this.id,
      dateAttribution: dateAttribution ?? this.dateAttribution,
      utilisateur: utilisateur ?? this.utilisateur,
      lotId: lotId ?? this.lotId,
      listeContenants: listeContenants ?? this.listeContenants,
      statut: statut ?? this.statut,
      commentaires: commentaires ?? this.commentaires,
      dateModification: dateModification ?? this.dateModification,
      utilisateurModification:
          utilisateurModification ?? this.utilisateurModification,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Conversion vers Map pour serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateAttribution': dateAttribution.toIso8601String(),
      'utilisateur': utilisateur,
      'lotId': lotId,
      'listeContenants': listeContenants,
      'statut': statut.value,
      'commentaires': commentaires,
      'dateModification': dateModification?.toIso8601String(),
      'utilisateurModification': utilisateurModification,
      'metadata': metadata,
    };
  }

  /// Création depuis Map
  factory AttributionExtraction.fromMap(Map<String, dynamic> map) {
    return AttributionExtraction(
      id: map['id'] ?? '',
      dateAttribution: DateTime.parse(map['dateAttribution']),
      utilisateur: map['utilisateur'] ?? '',
      lotId: map['lotId'] ?? '',
      listeContenants: List<String>.from(map['listeContenants'] ?? []),
      statut: AttributionStatus.values.firstWhere(
        (s) => s.value == map['statut'],
        orElse: () => AttributionStatus.attribueExtraction,
      ),
      commentaires: map['commentaires'],
      dateModification: map['dateModification'] != null
          ? DateTime.parse(map['dateModification'])
          : null,
      utilisateurModification: map['utilisateurModification'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  /// Génère un résumé pour l'affichage
  String get resume {
    return 'Lot $lotId - ${listeContenants.length} contenant(s) - ${statut.label}';
  }

  /// Vérifie si l'attribution peut être modifiée
  bool get peutEtreModifiee {
    return statut != AttributionStatus.termineMaturation &&
        statut != AttributionStatus.annule;
  }

  /// Vérifie si l'attribution peut être annulée
  bool get peutEtreAnnulee {
    return statut != AttributionStatus.termineMaturation &&
        statut != AttributionStatus.annule;
  }
}

/// Filtres pour les attributions
class AttributionFilters {
  final List<AttributionStatus> statuts;
  final List<String> utilisateurs;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? rechercheLot;

  AttributionFilters({
    this.statuts = const [],
    this.utilisateurs = const [],
    this.dateDebut,
    this.dateFin,
    this.rechercheLot,
  });

  AttributionFilters copyWith({
    List<AttributionStatus>? statuts,
    List<String>? utilisateurs,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? rechercheLot,
  }) {
    return AttributionFilters(
      statuts: statuts ?? this.statuts,
      utilisateurs: utilisateurs ?? this.utilisateurs,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      rechercheLot: rechercheLot ?? this.rechercheLot,
    );
  }

  bool get isActive {
    return statuts.isNotEmpty ||
        utilisateurs.isNotEmpty ||
        dateDebut != null ||
        dateFin != null ||
        (rechercheLot?.isNotEmpty ?? false);
  }
}

/// Statistiques des attributions
class AttributionStats {
  final int totalAttributions;
  final int enCours;
  final int terminees;
  final int annulees;
  final Map<String, int> parStatut;
  final Map<String, int> parUtilisateur;

  AttributionStats({
    required this.totalAttributions,
    required this.enCours,
    required this.terminees,
    required this.annulees,
    required this.parStatut,
    required this.parUtilisateur,
  });

  factory AttributionStats.fromAttributions(
      List<AttributionExtraction> attributions) {
    final Map<String, int> parStatut = {};
    final Map<String, int> parUtilisateur = {};

    int enCours = 0;
    int terminees = 0;
    int annulees = 0;

    for (final attribution in attributions) {
      // Compter par statut
      parStatut[attribution.statut.label] =
          (parStatut[attribution.statut.label] ?? 0) + 1;

      // Compter par utilisateur
      parUtilisateur[attribution.utilisateur] =
          (parUtilisateur[attribution.utilisateur] ?? 0) + 1;

      // Catégoriser
      switch (attribution.statut) {
        case AttributionStatus.attribueExtraction:
        case AttributionStatus.enCoursExtraction:
        case AttributionStatus.extraitEnAttente:
        case AttributionStatus.attribueMaturation:
        case AttributionStatus.enCoursMaturation:
          enCours++;
          break;
        case AttributionStatus.termineMaturation:
          terminees++;
          break;
        case AttributionStatus.annule:
          annulees++;
          break;
      }
    }

    return AttributionStats(
      totalAttributions: attributions.length,
      enCours: enCours,
      terminees: terminees,
      annulees: annulees,
      parStatut: parStatut,
      parUtilisateur: parUtilisateur,
    );
  }
}
