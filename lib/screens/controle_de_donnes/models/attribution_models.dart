/// Types d'attribution
enum AttributionType {
  extraction('extraction', 'Extraction'),
  filtration('filtration', 'Filtration');

  const AttributionType(this.value, this.label);
  final String value;
  final String label;
}

/// Statuts d'attribution
enum AttributionStatus {
  attribueExtraction('attribué_extraction', 'Attribué à l\'Extraction'),
  attribueFiltration('attribué_filtration', 'Attribué à la Filtration'),
  enCoursTraitement('en_cours_traitement', 'En cours de traitement'),
  traiteEnAttente('traité_en_attente', 'Traité - En attente'),
  termine('terminé', 'Terminé'),
  annule('annulé', 'Annulé');

  const AttributionStatus(this.value, this.label);
  final String value;
  final String label;

  /// Couleur associée au statut
  String get colorName {
    switch (this) {
      case AttributionStatus.attribueExtraction:
        return 'blue';
      case AttributionStatus.attribueFiltration:
        return 'purple';
      case AttributionStatus.enCoursTraitement:
        return 'orange';
      case AttributionStatus.traiteEnAttente:
        return 'teal';
      case AttributionStatus.termine:
        return 'green';
      case AttributionStatus.annule:
        return 'red';
    }
  }
}

/// Type de produit pour classification
enum ProductNature {
  brut('brut', 'Produits Bruts', 'Miel brut, cire brute, propolis brute'),
  liquide('liquide', 'Produits Liquides/Filtrés',
      'Miel liquide, miel filtré, extraits');

  const ProductNature(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;
}

/// Modèle pour une attribution depuis le module Contrôle
class ControlAttribution {
  final String id;
  final AttributionType type;
  final DateTime dateAttribution;
  final String utilisateur;
  final List<String> listeContenants;
  final AttributionStatus statut;
  final String? commentaires;
  final DateTime? dateModification;
  final String? utilisateurModification;
  final Map<String, dynamic> metadata;

  // Informations sur la source (provenant du Contrôle)
  final String sourceCollecteId;
  final String sourceType; // 'recoltes', 'scoop', 'individuel'
  final String site;
  final DateTime dateCollecte;

  // Classification des produits
  final ProductNature natureProduitsAttribues;

  ControlAttribution({
    required this.id,
    required this.type,
    required this.dateAttribution,
    required this.utilisateur,
    required this.listeContenants,
    this.statut = AttributionStatus.attribueExtraction,
    this.commentaires,
    this.dateModification,
    this.utilisateurModification,
    this.metadata = const {},
    required this.sourceCollecteId,
    required this.sourceType,
    required this.site,
    required this.dateCollecte,
    required this.natureProduitsAttribues,
  });

  /// Copie avec modifications
  ControlAttribution copyWith({
    String? id,
    AttributionType? type,
    DateTime? dateAttribution,
    String? utilisateur,
    List<String>? listeContenants,
    AttributionStatus? statut,
    String? commentaires,
    DateTime? dateModification,
    String? utilisateurModification,
    Map<String, dynamic>? metadata,
    String? sourceCollecteId,
    String? sourceType,
    String? site,
    DateTime? dateCollecte,
    ProductNature? natureProduitsAttribues,
  }) {
    return ControlAttribution(
      id: id ?? this.id,
      type: type ?? this.type,
      dateAttribution: dateAttribution ?? this.dateAttribution,
      utilisateur: utilisateur ?? this.utilisateur,
      listeContenants: listeContenants ?? this.listeContenants,
      statut: statut ?? this.statut,
      commentaires: commentaires ?? this.commentaires,
      dateModification: dateModification ?? this.dateModification,
      utilisateurModification:
          utilisateurModification ?? this.utilisateurModification,
      metadata: metadata ?? this.metadata,
      sourceCollecteId: sourceCollecteId ?? this.sourceCollecteId,
      sourceType: sourceType ?? this.sourceType,
      site: site ?? this.site,
      dateCollecte: dateCollecte ?? this.dateCollecte,
      natureProduitsAttribues:
          natureProduitsAttribues ?? this.natureProduitsAttribues,
    );
  }

  /// Conversion vers Map pour serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'dateAttribution': dateAttribution.toIso8601String(),
      'utilisateur': utilisateur,
      'listeContenants': listeContenants,
      'statut': statut.value,
      'commentaires': commentaires,
      'dateModification': dateModification?.toIso8601String(),
      'utilisateurModification': utilisateurModification,
      'metadata': metadata,
      'sourceCollecteId': sourceCollecteId,
      'sourceType': sourceType,
      'site': site,
      'dateCollecte': dateCollecte.toIso8601String(),
      'natureProduitsAttribues': natureProduitsAttribues.value,
    };
  }

  /// Création depuis Map
  factory ControlAttribution.fromMap(Map<String, dynamic> map) {
    return ControlAttribution(
      id: map['id'] ?? '',
      type: AttributionType.values.firstWhere(
        (t) => t.value == map['type'],
        orElse: () => AttributionType.extraction,
      ),
      dateAttribution: DateTime.parse(map['dateAttribution']),
      utilisateur: map['utilisateur'] ?? '',
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
      sourceCollecteId: map['sourceCollecteId'] ?? '',
      sourceType: map['sourceType'] ?? '',
      site: map['site'] ?? '',
      dateCollecte: DateTime.parse(map['dateCollecte']),
      natureProduitsAttribues: ProductNature.values.firstWhere(
        (n) => n.value == map['natureProduitsAttribues'],
        orElse: () => ProductNature.brut,
      ),
    );
  }

  /// Génère un résumé pour l'affichage
  String get resume {
    return '${type.label} - ${natureProduitsAttribues.label} - ${listeContenants.length} contenant(s)';
  }

  /// Vérifie si l'attribution peut être modifiée
  bool get peutEtreModifiee {
    return statut != AttributionStatus.termine &&
        statut != AttributionStatus.annule;
  }

  /// Vérifie si l'attribution peut être annulée
  bool get peutEtreAnnulee {
    return statut != AttributionStatus.termine &&
        statut != AttributionStatus.annule;
  }

  /// Détermine le statut par défaut selon le type
  static AttributionStatus getDefaultStatus(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return AttributionStatus.attribueExtraction;
      case AttributionType.filtration:
        return AttributionStatus.attribueFiltration;
    }
  }
}

/// Filtres pour les attributions du contrôle
class ControlAttributionFilters {
  final List<AttributionType> types;
  final List<AttributionStatus> statuts;
  final List<String> utilisateurs;
  final List<String> sites;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? rechercheLot;

  ControlAttributionFilters({
    this.types = const [],
    this.statuts = const [],
    this.utilisateurs = const [],
    this.sites = const [],
    this.dateDebut,
    this.dateFin,
    this.rechercheLot,
  });

  ControlAttributionFilters copyWith({
    List<AttributionType>? types,
    List<AttributionStatus>? statuts,
    List<String>? utilisateurs,
    List<String>? sites,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? rechercheLot,
  }) {
    return ControlAttributionFilters(
      types: types ?? this.types,
      statuts: statuts ?? this.statuts,
      utilisateurs: utilisateurs ?? this.utilisateurs,
      sites: sites ?? this.sites,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      rechercheLot: rechercheLot ?? this.rechercheLot,
    );
  }

  bool get isActive {
    return types.isNotEmpty ||
        statuts.isNotEmpty ||
        utilisateurs.isNotEmpty ||
        sites.isNotEmpty ||
        dateDebut != null ||
        dateFin != null ||
        (rechercheLot?.isNotEmpty ?? false);
  }
}

/// Statistiques des attributions du contrôle
class ControlAttributionStats {
  final int totalAttributions;
  final int extractions;
  final int filtrations;
  final int enCours;
  final int terminees;
  final int annulees;
  final Map<String, int> parType;
  final Map<String, int> parStatut;
  final Map<String, int> parSite;
  final Map<String, int> parUtilisateur;

  ControlAttributionStats({
    required this.totalAttributions,
    required this.extractions,
    required this.filtrations,
    required this.enCours,
    required this.terminees,
    required this.annulees,
    required this.parType,
    required this.parStatut,
    required this.parSite,
    required this.parUtilisateur,
  });

  factory ControlAttributionStats.fromAttributions(
      List<ControlAttribution> attributions) {
    final Map<String, int> parType = {};
    final Map<String, int> parStatut = {};
    final Map<String, int> parSite = {};
    final Map<String, int> parUtilisateur = {};

    int extractions = 0;
    int filtrations = 0;
    int enCours = 0;
    int terminees = 0;
    int annulees = 0;

    for (final attribution in attributions) {
      // Compter par type
      parType[attribution.type.label] =
          (parType[attribution.type.label] ?? 0) + 1;

      // Compter par statut
      parStatut[attribution.statut.label] =
          (parStatut[attribution.statut.label] ?? 0) + 1;

      // Compter par site
      parSite[attribution.site] = (parSite[attribution.site] ?? 0) + 1;

      // Compter par utilisateur
      parUtilisateur[attribution.utilisateur] =
          (parUtilisateur[attribution.utilisateur] ?? 0) + 1;

      // Catégoriser par type
      switch (attribution.type) {
        case AttributionType.extraction:
          extractions++;
          break;
        case AttributionType.filtration:
          filtrations++;
          break;
      }

      // Catégoriser par statut
      switch (attribution.statut) {
        case AttributionStatus.attribueExtraction:
        case AttributionStatus.attribueFiltration:
        case AttributionStatus.enCoursTraitement:
        case AttributionStatus.traiteEnAttente:
          enCours++;
          break;
        case AttributionStatus.termine:
          terminees++;
          break;
        case AttributionStatus.annule:
          annulees++;
          break;
      }
    }

    return ControlAttributionStats(
      totalAttributions: attributions.length,
      extractions: extractions,
      filtrations: filtrations,
      enCours: enCours,
      terminees: terminees,
      annulees: annulees,
      parType: parType,
      parStatut: parStatut,
      parSite: parSite,
      parUtilisateur: parUtilisateur,
    );
  }
}
