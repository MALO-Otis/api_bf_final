/// Modèles pour le traitement de la cire
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Statut du traitement de la cire
enum CireTraitementStatus {
  enAttente('En Attente', 'waiting'),
  enCours('En Cours', 'in_progress'),
  termine('Terminé', 'completed'),
  suspendu('Suspendu', 'suspended');

  const CireTraitementStatus(this.label, this.value);
  final String label;
  final String value;
}

/// Modèle pour un produit cire en traitement
class CireProduct {
  final String id;
  final String attributionId;
  final String codeContenant;
  final String typeCollecte;
  final String collecteId;
  final String producteur;
  final String village;
  final String siteOrigine;
  final String typeContenant;
  final double poidsOriginal;
  final double poidsDisponible;
  final String predominanceFlorale;
  final String qualite;
  final DateTime dateReception;
  final DateTime dateCollecte;
  final DateTime dateAttribution;
  final String collecteur;
  final String attributeur;
  final bool estConforme;
  final String? causeNonConformite;
  final String? instructions;
  final String? observations;
  final CireTraitementStatus statut;
  final DateTime? dateDebutTraitement;
  final DateTime? dateFinTraitement;
  final double? poidsTraite;
  final String? typeTraitement; // 'purification', 'moulage', 'conditionnement'
  final Map<String, dynamic>? conditionsTraitement;
  final Map<String, dynamic>? resultats;

  const CireProduct({
    required this.id,
    required this.attributionId,
    required this.codeContenant,
    required this.typeCollecte,
    required this.collecteId,
    required this.producteur,
    required this.village,
    required this.siteOrigine,
    required this.typeContenant,
    required this.poidsOriginal,
    required this.poidsDisponible,
    required this.predominanceFlorale,
    required this.qualite,
    required this.dateReception,
    required this.dateCollecte,
    required this.dateAttribution,
    required this.collecteur,
    required this.attributeur,
    required this.estConforme,
    this.causeNonConformite,
    this.instructions,
    this.observations,
    this.statut = CireTraitementStatus.enAttente,
    this.dateDebutTraitement,
    this.dateFinTraitement,
    this.poidsTraite,
    this.typeTraitement,
    this.conditionsTraitement,
    this.resultats,
  });

  CireProduct copyWith({
    String? id,
    String? attributionId,
    String? codeContenant,
    String? typeCollecte,
    String? collecteId,
    String? producteur,
    String? village,
    String? siteOrigine,
    String? typeContenant,
    double? poidsOriginal,
    double? poidsDisponible,
    String? predominanceFlorale,
    String? qualite,
    DateTime? dateReception,
    DateTime? dateCollecte,
    DateTime? dateAttribution,
    String? collecteur,
    String? attributeur,
    bool? estConforme,
    String? causeNonConformite,
    String? instructions,
    String? observations,
    CireTraitementStatus? statut,
    DateTime? dateDebutTraitement,
    DateTime? dateFinTraitement,
    double? poidsTraite,
    String? typeTraitement,
    Map<String, dynamic>? conditionsTraitement,
    Map<String, dynamic>? resultats,
  }) {
    return CireProduct(
      id: id ?? this.id,
      attributionId: attributionId ?? this.attributionId,
      codeContenant: codeContenant ?? this.codeContenant,
      typeCollecte: typeCollecte ?? this.typeCollecte,
      collecteId: collecteId ?? this.collecteId,
      producteur: producteur ?? this.producteur,
      village: village ?? this.village,
      siteOrigine: siteOrigine ?? this.siteOrigine,
      typeContenant: typeContenant ?? this.typeContenant,
      poidsOriginal: poidsOriginal ?? this.poidsOriginal,
      poidsDisponible: poidsDisponible ?? this.poidsDisponible,
      predominanceFlorale: predominanceFlorale ?? this.predominanceFlorale,
      qualite: qualite ?? this.qualite,
      dateReception: dateReception ?? this.dateReception,
      dateCollecte: dateCollecte ?? this.dateCollecte,
      dateAttribution: dateAttribution ?? this.dateAttribution,
      collecteur: collecteur ?? this.collecteur,
      attributeur: attributeur ?? this.attributeur,
      estConforme: estConforme ?? this.estConforme,
      causeNonConformite: causeNonConformite ?? this.causeNonConformite,
      instructions: instructions ?? this.instructions,
      observations: observations ?? this.observations,
      statut: statut ?? this.statut,
      dateDebutTraitement: dateDebutTraitement ?? this.dateDebutTraitement,
      dateFinTraitement: dateFinTraitement ?? this.dateFinTraitement,
      poidsTraite: poidsTraite ?? this.poidsTraite,
      typeTraitement: typeTraitement ?? this.typeTraitement,
      conditionsTraitement: conditionsTraitement ?? this.conditionsTraitement,
      resultats: resultats ?? this.resultats,
    );
  }

  /// Convertit un ProductControle en CireProduct
  factory CireProduct.fromProductControle(
    ProductControle produit,
    String attributionId,
    String attributeur,
    DateTime dateAttribution,
  ) {
    return CireProduct(
      id: produit.id,
      attributionId: attributionId,
      codeContenant: produit.codeContenant,
      typeCollecte: produit.typeCollecte,
      collecteId: produit.collecteId,
      producteur: produit.producteur,
      village: produit.village,
      siteOrigine: produit.siteOrigine,
      typeContenant: produit.typeContenant,
      poidsOriginal: produit.poidsTotal,
      poidsDisponible: produit.poidsTotal,
      predominanceFlorale: produit.predominanceFlorale,
      qualite: produit.qualite,
      dateReception: produit.dateReception,
      dateCollecte: produit.dateCollecte,
      dateAttribution: dateAttribution,
      collecteur: produit.controleur ?? '',
      attributeur: attributeur,
      estConforme: produit.estConforme,
      causeNonConformite: produit.causeNonConformite,
      observations: produit.observations,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attribution_id': attributionId,
      'code_contenant': codeContenant,
      'type_collecte': typeCollecte,
      'collecte_id': collecteId,
      'producteur': producteur,
      'village': village,
      'site_origine': siteOrigine,
      'type_contenant': typeContenant,
      'poids_original': poidsOriginal,
      'poids_disponible': poidsDisponible,
      'predominance_florale': predominanceFlorale,
      'qualite': qualite,
      'date_reception': dateReception.toIso8601String(),
      'date_collecte': dateCollecte.toIso8601String(),
      'date_attribution': dateAttribution.toIso8601String(),
      'collecteur': collecteur,
      'attributeur': attributeur,
      'est_conforme': estConforme,
      'cause_non_conformite': causeNonConformite,
      'instructions': instructions,
      'observations': observations,
      'statut': statut.value,
      'date_debut_traitement': dateDebutTraitement?.toIso8601String(),
      'date_fin_traitement': dateFinTraitement?.toIso8601String(),
      'poids_traite': poidsTraite,
      'type_traitement': typeTraitement,
      'conditions_traitement': conditionsTraitement,
      'resultats': resultats,
    };
  }

  factory CireProduct.fromMap(Map<String, dynamic> map) {
    return CireProduct(
      id: map['id'] ?? '',
      attributionId: map['attribution_id'] ?? '',
      codeContenant: map['code_contenant'] ?? '',
      typeCollecte: map['type_collecte'] ?? '',
      collecteId: map['collecte_id'] ?? '',
      producteur: map['producteur'] ?? '',
      village: map['village'] ?? '',
      siteOrigine: map['site_origine'] ?? '',
      typeContenant: map['type_contenant'] ?? '',
      poidsOriginal: (map['poids_original'] ?? 0.0).toDouble(),
      poidsDisponible: (map['poids_disponible'] ?? 0.0).toDouble(),
      predominanceFlorale: map['predominance_florale'] ?? '',
      qualite: map['qualite'] ?? '',
      dateReception: DateTime.parse(map['date_reception']),
      dateCollecte: DateTime.parse(map['date_collecte']),
      dateAttribution: DateTime.parse(map['date_attribution']),
      collecteur: map['collecteur'] ?? '',
      attributeur: map['attributeur'] ?? '',
      estConforme: map['est_conforme'] ?? true,
      causeNonConformite: map['cause_non_conformite'],
      instructions: map['instructions'],
      observations: map['observations'],
      statut: CireTraitementStatus.values.firstWhere(
        (s) => s.value == map['statut'],
        orElse: () => CireTraitementStatus.enAttente,
      ),
      dateDebutTraitement: map['date_debut_traitement'] != null
          ? DateTime.parse(map['date_debut_traitement'])
          : null,
      dateFinTraitement: map['date_fin_traitement'] != null
          ? DateTime.parse(map['date_fin_traitement'])
          : null,
      poidsTraite: map['poids_traite']?.toDouble(),
      typeTraitement: map['type_traitement'],
      conditionsTraitement: map['conditions_traitement'],
      resultats: map['resultats'],
    );
  }

  /// Calcule le rendement du traitement
  double? get rendementTraitement {
    if (poidsTraite == null || poidsOriginal <= 0) return null;
    return (poidsTraite! / poidsOriginal) * 100;
  }

  /// Vérifie si le produit a un traitement en cours
  bool get aTraitementEnCours => statut == CireTraitementStatus.enCours;

  /// Vérifie si le produit est disponible pour traitement
  bool get estDisponiblePourTraitement =>
      statut == CireTraitementStatus.enAttente && estConforme;
}

/// Filtres pour les produits cire
class CireProductFilters {
  final List<CireTraitementStatus> statuts;
  final List<String> sitesOrigine;
  final List<String> villages;
  final List<String> attributeurs;
  final List<String> typesTraitement;
  final DateTime? dateAttributionFrom;
  final DateTime? dateAttributionTo;
  final DateTime? dateReceptionFrom;
  final DateTime? dateReceptionTo;
  final double? poidsMin;
  final double? poidsMax;
  final bool? seulementDisponibles;
  final String searchQuery;

  const CireProductFilters({
    this.statuts = const [],
    this.sitesOrigine = const [],
    this.villages = const [],
    this.attributeurs = const [],
    this.typesTraitement = const [],
    this.dateAttributionFrom,
    this.dateAttributionTo,
    this.dateReceptionFrom,
    this.dateReceptionTo,
    this.poidsMin,
    this.poidsMax,
    this.seulementDisponibles,
    this.searchQuery = '',
  });

  bool matches(CireProduct product) {
    // Filtre par statut
    if (statuts.isNotEmpty && !statuts.contains(product.statut)) {
      return false;
    }

    // Filtre par site d'origine
    if (sitesOrigine.isNotEmpty &&
        !sitesOrigine.contains(product.siteOrigine)) {
      return false;
    }

    // Filtre par village
    if (villages.isNotEmpty && !villages.contains(product.village)) {
      return false;
    }

    // Filtre par attributeur
    if (attributeurs.isNotEmpty &&
        !attributeurs.contains(product.attributeur)) {
      return false;
    }

    // Filtre par type de traitement
    if (typesTraitement.isNotEmpty &&
        (product.typeTraitement == null ||
            !typesTraitement.contains(product.typeTraitement!))) {
      return false;
    }

    // Filtres par dates
    if (dateAttributionFrom != null &&
        product.dateAttribution.isBefore(dateAttributionFrom!)) {
      return false;
    }
    if (dateAttributionTo != null &&
        product.dateAttribution.isAfter(dateAttributionTo!)) {
      return false;
    }

    if (dateReceptionFrom != null &&
        product.dateReception.isBefore(dateReceptionFrom!)) {
      return false;
    }
    if (dateReceptionTo != null &&
        product.dateReception.isAfter(dateReceptionTo!)) {
      return false;
    }

    // Filtres par poids
    if (poidsMin != null && product.poidsOriginal < poidsMin!) {
      return false;
    }
    if (poidsMax != null && product.poidsOriginal > poidsMax!) {
      return false;
    }

    // Filtre seulement disponibles
    if (seulementDisponibles == true && !product.estDisponiblePourTraitement) {
      return false;
    }

    // Filtre par recherche textuelle
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final searchFields = [
        product.codeContenant,
        product.producteur,
        product.village,
        product.siteOrigine,
        product.collecteur,
        product.attributeur,
        product.predominanceFlorale,
        product.qualite,
      ].join(' ').toLowerCase();

      if (!searchFields.contains(query)) {
        return false;
      }
    }

    return true;
  }
}

/// Statistiques des produits cire
class CireProductStats {
  final int total;
  final int enAttente;
  final int enCours;
  final int termines;
  final int suspendus;
  final double poidsTotal;
  final double poidsTraite;
  final double rendementMoyen;
  final Map<String, int> parSite;
  final Map<String, int> parTypeTraitement;

  const CireProductStats({
    required this.total,
    required this.enAttente,
    required this.enCours,
    required this.termines,
    required this.suspendus,
    required this.poidsTotal,
    required this.poidsTraite,
    required this.rendementMoyen,
    required this.parSite,
    required this.parTypeTraitement,
  });

  factory CireProductStats.fromProducts(List<CireProduct> products) {
    final enAttente = products
        .where((p) => p.statut == CireTraitementStatus.enAttente)
        .length;
    final enCours =
        products.where((p) => p.statut == CireTraitementStatus.enCours).length;
    final termines =
        products.where((p) => p.statut == CireTraitementStatus.termine).length;
    final suspendus =
        products.where((p) => p.statut == CireTraitementStatus.suspendu).length;

    final poidsTotal = products.fold(0.0, (sum, p) => sum + p.poidsOriginal);
    final poidsTraite =
        products.fold(0.0, (sum, p) => sum + (p.poidsTraite ?? 0.0));

    final rendements = products
        .where((p) => p.rendementTraitement != null)
        .map((p) => p.rendementTraitement!)
        .toList();
    final rendementMoyen = rendements.isNotEmpty
        ? rendements.reduce((a, b) => a + b) / rendements.length
        : 0.0;

    final Map<String, int> parSite = {};
    final Map<String, int> parTypeTraitement = {};

    for (final product in products) {
      parSite[product.siteOrigine] = (parSite[product.siteOrigine] ?? 0) + 1;
      if (product.typeTraitement != null) {
        parTypeTraitement[product.typeTraitement!] =
            (parTypeTraitement[product.typeTraitement!] ?? 0) + 1;
      }
    }

    return CireProductStats(
      total: products.length,
      enAttente: enAttente,
      enCours: enCours,
      termines: termines,
      suspendus: suspendus,
      poidsTotal: poidsTotal,
      poidsTraite: poidsTraite,
      rendementMoyen: rendementMoyen,
      parSite: parSite,
      parTypeTraitement: parTypeTraitement,
    );
  }
}
