import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// 🟤 MODÈLES AMÉLIORÉS POUR LE TRAITEMENT DE CIRE
///
/// Ces modèles s'intègrent parfaitement avec le nouveau système
/// d'attribution unifié pour une gestion complète des traitements de cire

/// Statut d'un processus de traitement de cire
enum CireTraitementStatus {
  enAttente('En Attente', 'waiting'),
  enCours('En Cours', 'in_progress'),
  suspendu('Suspendu', 'suspended'),
  termine('Terminé', 'completed'),
  erreur('Erreur', 'error');

  const CireTraitementStatus(this.label, this.value);
  final String label;
  final String value;
}

/// Types de traitement de cire disponibles
enum TypeTraitementCire {
  purification('Purification', 'purification'),
  blanchiment('Blanchiment', 'bleaching'),
  moulage('Moulage', 'molding'),
  conditionnement('Conditionnement', 'packaging'),
  transformation('Transformation', 'transformation');

  const TypeTraitementCire(this.label, this.value);
  final String label;
  final String value;
}

/// Qualités de cire après traitement
enum QualiteCire {
  brute('Brute', 'raw'),
  purifiee('Purifiée', 'purified'),
  blanche('Blanche', 'white'),
  premium('Premium', 'premium'),
  industrielle('Industrielle', 'industrial');

  const QualiteCire(this.label, this.value);
  final String label;
  final String value;
}

/// Couleurs de cire
enum CouleurCire {
  naturelle('Naturelle', 'natural'),
  jauneDoree('Jaune Dorée', 'golden_yellow'),
  jauneClair('Jaune Clair', 'light_yellow'),
  blanche('Blanche', 'white'),
  beige('Beige', 'beige'),
  brune('Brune', 'brown');

  const CouleurCire(this.label, this.value);
  final String label;
  final String value;
}

/// Textures de cire
enum TextureCire {
  rugueuse('Rugueuse', 'rough'),
  lisse('Lisse', 'smooth'),
  granuleuse('Granuleuse', 'granular'),
  compacte('Compacte', 'compact'),
  friable('Friable', 'friable');

  const TextureCire(this.label, this.value);
  final String label;
  final String value;
}

/// Modèle pour un processus de traitement de cire en cours
class CireTraitementProcess {
  final String id;
  final ProductControle produit;
  final String operateur;
  final DateTime dateDebut;
  final CireTraitementStatus statut;
  final String typeTraitement;
  final Map<String, dynamic> parametres;
  final String? instructions;
  final String? observations;
  final DateTime? dateSuspension;
  final String site;
  final Map<String, dynamic>? metadata;

  const CireTraitementProcess({
    required this.id,
    required this.produit,
    required this.operateur,
    required this.dateDebut,
    required this.statut,
    required this.typeTraitement,
    required this.parametres,
    this.instructions,
    this.observations,
    this.dateSuspension,
    required this.site,
    this.metadata,
  });

  /// Durée écoulée depuis le début
  Duration get dureeEcoulee => DateTime.now().difference(dateDebut);

  /// Vérifie si le traitement est urgent (> 6h)
  bool get isUrgent => dureeEcoulee.inHours > 6;

  /// Estime le temps restant basé sur le type de traitement
  Duration get tempsEstimeRestant {
    switch (typeTraitement) {
      case 'Purification':
        return const Duration(hours: 4);
      case 'Blanchiment':
        return const Duration(hours: 6);
      case 'Moulage':
        return const Duration(hours: 2);
      case 'Conditionnement':
        return const Duration(hours: 1);
      case 'Transformation':
        return const Duration(hours: 8);
      default:
        return const Duration(hours: 4);
    }
  }

  /// Température recommandée pour le type de traitement
  int get temperatureRecommandee {
    switch (typeTraitement) {
      case 'Purification':
        return 65;
      case 'Blanchiment':
        return 70;
      case 'Moulage':
        return 60;
      case 'Conditionnement':
        return 25; // Température ambiante
      case 'Transformation':
        return 75;
      default:
        return 65;
    }
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produit': produit.toMap(),
      'operateur': operateur,
      'dateDebut': dateDebut.toIso8601String(),
      'statut': statut.value,
      'typeTraitement': typeTraitement,
      'parametres': parametres,
      'instructions': instructions,
      'observations': observations,
      'dateSuspension': dateSuspension?.toIso8601String(),
      'site': site,
      'metadata': metadata,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Création depuis Map Firestore
  factory CireTraitementProcess.fromMap(Map<String, dynamic> map) {
    return CireTraitementProcess(
      id: map['id'] ?? '',
      produit: ProductControle.fromMap(map['produit'] ?? {}),
      operateur: map['operateur'] ?? '',
      dateDebut:
          DateTime.parse(map['dateDebut'] ?? DateTime.now().toIso8601String()),
      statut: CireTraitementStatus.values.firstWhere(
        (s) => s.value == map['statut'],
        orElse: () => CireTraitementStatus.enAttente,
      ),
      typeTraitement: map['typeTraitement'] ?? '',
      parametres: Map<String, dynamic>.from(map['parametres'] ?? {}),
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
  CireTraitementProcess copyWith({
    String? id,
    ProductControle? produit,
    String? operateur,
    DateTime? dateDebut,
    CireTraitementStatus? statut,
    String? typeTraitement,
    Map<String, dynamic>? parametres,
    String? instructions,
    String? observations,
    DateTime? dateSuspension,
    String? site,
    Map<String, dynamic>? metadata,
  }) {
    return CireTraitementProcess(
      id: id ?? this.id,
      produit: produit ?? this.produit,
      operateur: operateur ?? this.operateur,
      dateDebut: dateDebut ?? this.dateDebut,
      statut: statut ?? this.statut,
      typeTraitement: typeTraitement ?? this.typeTraitement,
      parametres: parametres ?? this.parametres,
      instructions: instructions ?? this.instructions,
      observations: observations ?? this.observations,
      dateSuspension: dateSuspension ?? this.dateSuspension,
      site: site ?? this.site,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Modèle pour le résultat d'un traitement de cire terminé
class CireTraitementResult {
  final String id;
  final ProductControle produit;
  final String operateur;
  final DateTime dateDebut;
  final DateTime dateFin;
  final Duration duree;
  final double poidsInitial;
  final double poidsTraite;
  final double rendement; // Pourcentage
  final String typeTraitement;
  final String qualiteFinale;
  final String couleur;
  final String texture;
  final Map<String, dynamic> parametres;
  final String? observations;
  final String site;
  final Map<String, dynamic>? analyses;
  final bool isValidated;
  final double? pointDeFusion;
  final double? densite;

  const CireTraitementResult({
    required this.id,
    required this.produit,
    required this.operateur,
    required this.dateDebut,
    required this.dateFin,
    required this.duree,
    required this.poidsInitial,
    required this.poidsTraite,
    required this.rendement,
    required this.typeTraitement,
    required this.qualiteFinale,
    required this.couleur,
    required this.texture,
    required this.parametres,
    this.observations,
    required this.site,
    this.analyses,
    this.isValidated = false,
    this.pointDeFusion,
    this.densite,
  });

  /// Calcule le taux de perte
  double get tauxPerte => poidsInitial > 0
      ? ((poidsInitial - poidsTraite) / poidsInitial) * 100
      : 0.0;

  /// Évalue la qualité du rendement
  String get evaluationRendement {
    if (rendement >= 95) return 'Excellent';
    if (rendement >= 90) return 'Très Bon';
    if (rendement >= 85) return 'Bon';
    if (rendement >= 80) return 'Acceptable';
    return 'Faible';
  }

  /// Évalue l'efficacité globale du traitement
  String get efficaciteGlobale {
    final scoreRendement = rendement >= 90
        ? 3
        : rendement >= 85
            ? 2
            : 1;
    final scoreQualite = qualiteFinale == 'Excellent'
        ? 3
        : qualiteFinale == 'Très Bon'
            ? 2
            : 1;
    final scoreDuree = duree.inHours <= tempsEstimeOptimal.inHours
        ? 3
        : duree.inHours <= tempsEstimeOptimal.inHours * 1.2
            ? 2
            : 1;

    final scoreTotal = (scoreRendement + scoreQualite + scoreDuree) / 3;

    if (scoreTotal >= 2.5) return 'Excellente';
    if (scoreTotal >= 2.0) return 'Très Bonne';
    if (scoreTotal >= 1.5) return 'Bonne';
    return 'À Améliorer';
  }

  /// Temps estimé optimal pour ce type de traitement
  Duration get tempsEstimeOptimal {
    switch (typeTraitement) {
      case 'Purification':
        return const Duration(hours: 4);
      case 'Blanchiment':
        return const Duration(hours: 6);
      case 'Moulage':
        return const Duration(hours: 2);
      case 'Conditionnement':
        return const Duration(hours: 1);
      case 'Transformation':
        return const Duration(hours: 8);
      default:
        return const Duration(hours: 4);
    }
  }

  /// Calcule la valeur commerciale estimée
  double get valeurEstimee {
    double basePrice = 0;

    // Prix de base selon la qualité
    switch (qualiteFinale) {
      case 'Excellent':
        basePrice = 15000; // FCFA/kg
        break;
      case 'Très Bon':
        basePrice = 12000;
        break;
      case 'Bon':
        basePrice = 10000;
        break;
      default:
        basePrice = 8000;
    }

    // Bonus selon le type de traitement
    switch (typeTraitement) {
      case 'Blanchiment':
        basePrice *= 1.3;
        break;
      case 'Transformation':
        basePrice *= 1.5;
        break;
      case 'Purification':
        basePrice *= 1.2;
        break;
    }

    return basePrice * poidsTraite;
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produit': produit.toMap(),
      'operateur': operateur,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'dureeMinutes': duree.inMinutes,
      'poidsInitial': poidsInitial,
      'poidsTraite': poidsTraite,
      'rendement': rendement,
      'tauxPerte': tauxPerte,
      'typeTraitement': typeTraitement,
      'qualiteFinale': qualiteFinale,
      'couleur': couleur,
      'texture': texture,
      'parametres': parametres,
      'observations': observations,
      'site': site,
      'analyses': analyses,
      'isValidated': isValidated,
      'pointDeFusion': pointDeFusion,
      'densite': densite,
      'efficaciteGlobale': efficaciteGlobale,
      'valeurEstimee': valeurEstimee,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Création depuis Map Firestore
  factory CireTraitementResult.fromMap(Map<String, dynamic> map) {
    return CireTraitementResult(
      id: map['id'] ?? '',
      produit: ProductControle.fromMap(map['produit'] ?? {}),
      operateur: map['operateur'] ?? '',
      dateDebut:
          DateTime.parse(map['dateDebut'] ?? DateTime.now().toIso8601String()),
      dateFin:
          DateTime.parse(map['dateFin'] ?? DateTime.now().toIso8601String()),
      duree: Duration(minutes: map['dureeMinutes'] ?? 0),
      poidsInitial: (map['poidsInitial'] as num?)?.toDouble() ?? 0.0,
      poidsTraite: (map['poidsTraite'] as num?)?.toDouble() ?? 0.0,
      rendement: (map['rendement'] as num?)?.toDouble() ?? 0.0,
      typeTraitement: map['typeTraitement'] ?? '',
      qualiteFinale: map['qualiteFinale'] ?? '',
      couleur: map['couleur'] ?? '',
      texture: map['texture'] ?? '',
      parametres: Map<String, dynamic>.from(map['parametres'] ?? {}),
      observations: map['observations'],
      site: map['site'] ?? '',
      analyses: map['analyses'],
      isValidated: map['isValidated'] ?? false,
      pointDeFusion: (map['pointDeFusion'] as num?)?.toDouble(),
      densite: (map['densite'] as num?)?.toDouble(),
    );
  }

  /// Crée une copie avec des modifications
  CireTraitementResult copyWith({
    String? id,
    ProductControle? produit,
    String? operateur,
    DateTime? dateDebut,
    DateTime? dateFin,
    Duration? duree,
    double? poidsInitial,
    double? poidsTraite,
    double? rendement,
    String? typeTraitement,
    String? qualiteFinale,
    String? couleur,
    String? texture,
    Map<String, dynamic>? parametres,
    String? observations,
    String? site,
    Map<String, dynamic>? analyses,
    bool? isValidated,
    double? pointDeFusion,
    double? densite,
  }) {
    return CireTraitementResult(
      id: id ?? this.id,
      produit: produit ?? this.produit,
      operateur: operateur ?? this.operateur,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      duree: duree ?? this.duree,
      poidsInitial: poidsInitial ?? this.poidsInitial,
      poidsTraite: poidsTraite ?? this.poidsTraite,
      rendement: rendement ?? this.rendement,
      typeTraitement: typeTraitement ?? this.typeTraitement,
      qualiteFinale: qualiteFinale ?? this.qualiteFinale,
      couleur: couleur ?? this.couleur,
      texture: texture ?? this.texture,
      parametres: parametres ?? this.parametres,
      observations: observations ?? this.observations,
      site: site ?? this.site,
      analyses: analyses ?? this.analyses,
      isValidated: isValidated ?? this.isValidated,
      pointDeFusion: pointDeFusion ?? this.pointDeFusion,
      densite: densite ?? this.densite,
    );
  }
}

/// Modèle pour les statistiques de traitement de cire
class CireTraitementStats {
  final int totalAttribues;
  final int enCours;
  final int termines;
  final int suspendus;
  final double poidsTotal;
  final double poidsTraite;
  final double rendementMoyen;
  final Duration dureeMoyenne;
  final int urgents;
  final Map<String, int> parOperateur;
  final Map<String, int> parTypeTraitement;
  final Map<String, int> parQualite;
  final Map<String, int> parCouleur;
  final double valeurTotaleEstimee;

  const CireTraitementStats({
    required this.totalAttribues,
    required this.enCours,
    required this.termines,
    required this.suspendus,
    required this.poidsTotal,
    required this.poidsTraite,
    required this.rendementMoyen,
    required this.dureeMoyenne,
    required this.urgents,
    required this.parOperateur,
    required this.parTypeTraitement,
    required this.parQualite,
    required this.parCouleur,
    required this.valeurTotaleEstimee,
  });

  /// Taux de completion
  double get tauxCompletion =>
      totalAttribues > 0 ? (termines / totalAttribues) * 100 : 0.0;

  /// Efficacité globale du traitement
  String get efficaciteGlobale {
    if (tauxCompletion >= 95 && rendementMoyen >= 90) return 'Excellente';
    if (tauxCompletion >= 90 && rendementMoyen >= 85) return 'Très Bonne';
    if (tauxCompletion >= 80 && rendementMoyen >= 80) return 'Bonne';
    if (tauxCompletion >= 70 && rendementMoyen >= 75) return 'Acceptable';
    return 'À Améliorer';
  }

  /// Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'totalAttribues': totalAttribues,
      'enCours': enCours,
      'termines': termines,
      'suspendus': suspendus,
      'poidsTotal': poidsTotal,
      'poidsTraite': poidsTraite,
      'rendementMoyen': rendementMoyen,
      'dureeMoyenneMinutes': dureeMoyenne.inMinutes,
      'urgents': urgents,
      'tauxCompletion': tauxCompletion,
      'efficaciteGlobale': efficaciteGlobale,
      'valeurTotaleEstimee': valeurTotaleEstimee,
      'parOperateur': parOperateur,
      'parTypeTraitement': parTypeTraitement,
      'parQualite': parQualite,
      'parCouleur': parCouleur,
    };
  }
}

/// Filtres pour les traitements de cire
class CireTraitementFilters {
  final String? operateur;
  final CireTraitementStatus? statut;
  final String? typeTraitement;
  final String? qualiteFinale;
  final String? couleur;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final double? rendementMin;
  final double? rendementMax;
  final bool? urgentOnly;
  final String? searchQuery;

  const CireTraitementFilters({
    this.operateur,
    this.statut,
    this.typeTraitement,
    this.qualiteFinale,
    this.couleur,
    this.dateDebut,
    this.dateFin,
    this.rendementMin,
    this.rendementMax,
    this.urgentOnly,
    this.searchQuery,
  });

  /// Vérifie si un processus correspond aux filtres
  bool matchesProcess(CireTraitementProcess process) {
    if (operateur != null && process.operateur != operateur) return false;
    if (statut != null && process.statut != statut) return false;
    if (typeTraitement != null && process.typeTraitement != typeTraitement)
      return false;
    if (dateDebut != null && process.dateDebut.isBefore(dateDebut!))
      return false;
    if (urgentOnly == true && !process.isUrgent) return false;

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!process.produit.producteur.toLowerCase().contains(query) &&
          !process.produit.codeContenant.toLowerCase().contains(query) &&
          !process.operateur.toLowerCase().contains(query)) {
        return false;
      }
    }

    return true;
  }

  /// Vérifie si un résultat correspond aux filtres
  bool matchesResult(CireTraitementResult result) {
    if (operateur != null && result.operateur != operateur) return false;
    if (typeTraitement != null && result.typeTraitement != typeTraitement)
      return false;
    if (qualiteFinale != null && result.qualiteFinale != qualiteFinale)
      return false;
    if (couleur != null && result.couleur != couleur) return false;
    if (dateDebut != null && result.dateFin.isBefore(dateDebut!)) return false;
    if (dateFin != null && result.dateFin.isAfter(dateFin!)) return false;
    if (rendementMin != null && result.rendement < rendementMin!) return false;
    if (rendementMax != null && result.rendement > rendementMax!) return false;

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!result.produit.producteur.toLowerCase().contains(query) &&
          !result.produit.codeContenant.toLowerCase().contains(query) &&
          !result.operateur.toLowerCase().contains(query)) {
        return false;
      }
    }

    return true;
  }

  /// Compte le nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (operateur != null) count++;
    if (statut != null) count++;
    if (typeTraitement != null) count++;
    if (qualiteFinale != null) count++;
    if (couleur != null) count++;
    if (dateDebut != null) count++;
    if (dateFin != null) count++;
    if (rendementMin != null) count++;
    if (rendementMax != null) count++;
    if (urgentOnly == true) count++;
    if (searchQuery?.isNotEmpty == true) count++;
    return count;
  }

  /// Crée une copie avec des modifications
  CireTraitementFilters copyWith({
    String? operateur,
    CireTraitementStatus? statut,
    String? typeTraitement,
    String? qualiteFinale,
    String? couleur,
    DateTime? dateDebut,
    DateTime? dateFin,
    double? rendementMin,
    double? rendementMax,
    bool? urgentOnly,
    String? searchQuery,
  }) {
    return CireTraitementFilters(
      operateur: operateur ?? this.operateur,
      statut: statut ?? this.statut,
      typeTraitement: typeTraitement ?? this.typeTraitement,
      qualiteFinale: qualiteFinale ?? this.qualiteFinale,
      couleur: couleur ?? this.couleur,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      rendementMin: rendementMin ?? this.rendementMin,
      rendementMax: rendementMax ?? this.rendementMax,
      urgentOnly: urgentOnly ?? this.urgentOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
