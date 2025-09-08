/// Modèles pour les produits attribués au module d'extraction

import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Statut d'un prélèvement
enum PrelevementStatus {
  enAttente('En attente', 'waiting'),
  enCours('En cours', 'in_progress'),
  termine('Terminé', 'completed'),
  suspendu('Suspendu', 'suspended');

  const PrelevementStatus(this.label, this.value);
  final String label;
  final String value;
}

/// Type de prélèvement
enum PrelevementType {
  partiel('Partiel'),
  total('Total');

  const PrelevementType(this.label);
  final String label;
}

/// Modèle pour un produit attribué à l'extraction
class AttributedProduct {
  final String id;
  final String attributionId;
  final String codeContenant;
  final String typeCollecte;
  final String collecteId;
  final String producteur;
  final String village;
  final String siteOrigine;
  final ProductNature nature;
  final String typeContenant;
  final double poidsOriginal; // Poids initial du contenant
  final double poidsDisponible; // Poids restant disponible
  final double? teneurEau;
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
  final List<Prelevement> prelevements; // Historique des prélèvements
  final PrelevementStatus statut;

  const AttributedProduct({
    required this.id,
    required this.attributionId,
    required this.codeContenant,
    required this.typeCollecte,
    required this.collecteId,
    required this.producteur,
    required this.village,
    required this.siteOrigine,
    required this.nature,
    required this.typeContenant,
    required this.poidsOriginal,
    required this.poidsDisponible,
    this.teneurEau,
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
    this.prelevements = const [],
    this.statut = PrelevementStatus.enAttente,
  });

  /// Calcule le poids des residus
  double get poidsResidus => poidsOriginal - poidsDisponible;

  /// Calcule le pourcentage de prelevement
  double get pourcentagePrelevementTotal => poidsOriginal > 0
      ? ((poidsOriginal - poidsDisponible) / poidsOriginal) * 100
      : 0;

  /// Verifie si le produit est completement preleve
  bool get estCompletePreleve => poidsDisponible <= 0.01; // Tolerance de 10g

  /// Verifie si le produit a des prelevements en cours
  bool get aPrelevementEnCours =>
      prelevements.any((p) => p.statut == PrelevementStatus.enCours);

  /// Dernier prelevement effectue
  Prelevement? get dernierPrelevement =>
      prelevements.isNotEmpty ? prelevements.last : null;

  /// Code de localisation complet
  String get codeLocalisation => '${siteOrigine.toUpperCase()}-$village';

  /// Copie avec modifications
  AttributedProduct copyWith({
    String? id,
    String? attributionId,
    String? codeContenant,
    String? typeCollecte,
    String? collecteId,
    String? producteur,
    String? village,
    String? siteOrigine,
    ProductNature? nature,
    String? typeContenant,
    double? poidsOriginal,
    double? poidsDisponible,
    double? teneurEau,
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
    List<Prelevement>? prelevements,
    PrelevementStatus? statut,
  }) {
    return AttributedProduct(
      id: id ?? this.id,
      attributionId: attributionId ?? this.attributionId,
      codeContenant: codeContenant ?? this.codeContenant,
      typeCollecte: typeCollecte ?? this.typeCollecte,
      collecteId: collecteId ?? this.collecteId,
      producteur: producteur ?? this.producteur,
      village: village ?? this.village,
      siteOrigine: siteOrigine ?? this.siteOrigine,
      nature: nature ?? this.nature,
      typeContenant: typeContenant ?? this.typeContenant,
      poidsOriginal: poidsOriginal ?? this.poidsOriginal,
      poidsDisponible: poidsDisponible ?? this.poidsDisponible,
      teneurEau: teneurEau ?? this.teneurEau,
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
      prelevements: prelevements ?? this.prelevements,
      statut: statut ?? this.statut,
    );
  }

  /// Conversion vers Map
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
      'nature': nature.name,
      'type_contenant': typeContenant,
      'poids_original': poidsOriginal,
      'poids_disponible': poidsDisponible,
      'teneur_eau': teneurEau,
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
      'prelevements': prelevements.map((p) => p.toMap()).toList(),
      'statut': statut.value,
    };
  }

  /// Création depuis Map
  factory AttributedProduct.fromMap(Map<String, dynamic> map) {
    return AttributedProduct(
      id: map['id'] ?? '',
      attributionId: map['attribution_id'] ?? '',
      codeContenant: map['code_contenant'] ?? '',
      typeCollecte: map['type_collecte'] ?? '',
      collecteId: map['collecte_id'] ?? '',
      producteur: map['producteur'] ?? '',
      village: map['village'] ?? '',
      siteOrigine: map['site_origine'] ?? '',
      nature: ProductNature.values.firstWhere(
        (n) => n.name == map['nature'],
        orElse: () => ProductNature.brut,
      ),
      typeContenant: map['type_contenant'] ?? '',
      poidsOriginal: (map['poids_original'] ?? 0.0).toDouble(),
      poidsDisponible: (map['poids_disponible'] ?? 0.0).toDouble(),
      teneurEau: map['teneur_eau']?.toDouble(),
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
      prelevements: (map['prelevements'] as List<dynamic>?)
              ?.map((p) => Prelevement.fromMap(p))
              .toList() ??
          [],
      statut: PrelevementStatus.values.firstWhere(
        (s) => s.value == map['statut'],
        orElse: () => PrelevementStatus.enAttente,
      ),
    );
  }

  /// Conversion depuis ProductControle (système d'attribution)
  factory AttributedProduct.fromProductControle(
    ProductControle produit,
    String attributionId,
    String attributeur,
    DateTime dateAttribution,
    String? instructions,
  ) {
    return AttributedProduct(
      id: produit.id,
      attributionId: attributionId,
      codeContenant: produit.codeContenant,
      typeCollecte: produit.typeCollecte,
      collecteId: produit.collecteId,
      producteur: produit.producteur,
      village: produit.village,
      siteOrigine: produit.siteOrigine,
      nature: produit.nature,
      typeContenant: produit.typeContenant,
      poidsOriginal: produit.poidsTotal,
      poidsDisponible:
          produit.poidsTotal, // Initialement égal au poids original
      teneurEau: produit.teneurEau,
      predominanceFlorale: produit.predominanceFlorale,
      qualite: produit.qualite,
      dateReception: produit.dateReception,
      dateCollecte: produit.dateCollecte,
      dateAttribution: dateAttribution,
      collecteur: produit.controleur ?? 'Contrôleur Inconnu',
      attributeur: attributeur,
      estConforme: produit.estConforme,
      causeNonConformite: produit.causeNonConformite,
      instructions: instructions,
      observations: produit.observations,
      prelevements: [],
      statut: PrelevementStatus.enAttente,
    );
  }
}

/// Modele pour un prelevement effectue
class Prelevement {
  final String id;
  final String productId;
  final PrelevementType type;
  final double poidsPreleve;
  final DateTime datePrelevement;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String extracteur;
  final PrelevementStatus statut;
  final String? methodeExtraction;
  final double? temperatreExtraction;
  final double? humiditeRelative;
  final double? rendementCalcule;
  final String? observations;
  final String? problemes;
  final Map<String, dynamic> conditionsExtraction;
  final Map<String, dynamic> resultats;

  const Prelevement({
    required this.id,
    required this.productId,
    required this.type,
    required this.poidsPreleve,
    required this.datePrelevement,
    this.dateDebut,
    this.dateFin,
    required this.extracteur,
    this.statut = PrelevementStatus.enAttente,
    this.methodeExtraction,
    this.temperatreExtraction,
    this.humiditeRelative,
    this.rendementCalcule,
    this.observations,
    this.problemes,
    this.conditionsExtraction = const {},
    this.resultats = const {},
  });

  /// Duree du prelevement
  Duration? get dureePrelevement => dateDebut != null && dateFin != null
      ? dateFin!.difference(dateDebut!)
      : null;

  /// Copie avec modifications
  Prelevement copyWith({
    String? id,
    String? productId,
    PrelevementType? type,
    double? poidsPreleve,
    DateTime? datePrelevement,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? extracteur,
    PrelevementStatus? statut,
    String? methodeExtraction,
    double? temperatreExtraction,
    double? humiditeRelative,
    double? rendementCalcule,
    String? observations,
    String? problemes,
    Map<String, dynamic>? conditionsExtraction,
    Map<String, dynamic>? resultats,
  }) {
    return Prelevement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      type: type ?? this.type,
      poidsPreleve: poidsPreleve ?? this.poidsPreleve,
      datePrelevement: datePrelevement ?? this.datePrelevement,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      extracteur: extracteur ?? this.extracteur,
      statut: statut ?? this.statut,
      methodeExtraction: methodeExtraction ?? this.methodeExtraction,
      temperatreExtraction: temperatreExtraction ?? this.temperatreExtraction,
      humiditeRelative: humiditeRelative ?? this.humiditeRelative,
      rendementCalcule: rendementCalcule ?? this.rendementCalcule,
      observations: observations ?? this.observations,
      problemes: problemes ?? this.problemes,
      conditionsExtraction: conditionsExtraction ?? this.conditionsExtraction,
      resultats: resultats ?? this.resultats,
    );
  }

  /// Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'type': type.name,
      'poids_preleve': poidsPreleve,
      'date_prelevement': datePrelevement.toIso8601String(),
      'date_debut': dateDebut?.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'extracteur': extracteur,
      'statut': statut.value,
      'methode_extraction': methodeExtraction,
      'temperature_extraction': temperatreExtraction,
      'humidite_relative': humiditeRelative,
      'rendement_calcule': rendementCalcule,
      'observations': observations,
      'problemes': problemes,
      'conditions_extraction': conditionsExtraction,
      'resultats': resultats,
    };
  }

  /// Création depuis Map
  factory Prelevement.fromMap(Map<String, dynamic> map) {
    return Prelevement(
      id: map['id'] ?? '',
      productId: map['product_id'] ?? '',
      type: PrelevementType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => PrelevementType.partiel,
      ),
      poidsPreleve: (map['poids_preleve'] ?? 0.0).toDouble(),
      datePrelevement: DateTime.parse(map['date_prelevement']),
      dateDebut:
          map['date_debut'] != null ? DateTime.parse(map['date_debut']) : null,
      dateFin: map['date_fin'] != null ? DateTime.parse(map['date_fin']) : null,
      extracteur: map['extracteur'] ?? '',
      statut: PrelevementStatus.values.firstWhere(
        (s) => s.value == map['statut'],
        orElse: () => PrelevementStatus.enAttente,
      ),
      methodeExtraction: map['methode_extraction'],
      temperatreExtraction: map['temperature_extraction']?.toDouble(),
      humiditeRelative: map['humidite_relative']?.toDouble(),
      rendementCalcule: map['rendement_calcule']?.toDouble(),
      observations: map['observations'],
      problemes: map['problemes'],
      conditionsExtraction:
          Map<String, dynamic>.from(map['conditions_extraction'] ?? {}),
      resultats: Map<String, dynamic>.from(map['resultats'] ?? {}),
    );
  }
}

/// Filtres pour les produits attribués
class AttributedProductFilters {
  final List<ProductNature> natures;
  final List<String> sitesOrigine;
  final List<String> villages;
  final List<String> attributeurs;
  final List<PrelevementStatus> statuts;
  final DateTime? dateAttributionFrom;
  final DateTime? dateAttributionTo;
  final DateTime? dateReceptionFrom;
  final DateTime? dateReceptionTo;
  final double? poidsMin;
  final double? poidsMax;
  final bool? seulementDisponibles;
  final String searchQuery;

  const AttributedProductFilters({
    this.natures = const [],
    this.sitesOrigine = const [],
    this.villages = const [],
    this.attributeurs = const [],
    this.statuts = const [],
    this.dateAttributionFrom,
    this.dateAttributionTo,
    this.dateReceptionFrom,
    this.dateReceptionTo,
    this.poidsMin,
    this.poidsMax,
    this.seulementDisponibles,
    this.searchQuery = '',
  });

  /// Copie avec modifications
  AttributedProductFilters copyWith({
    List<ProductNature>? natures,
    List<String>? sitesOrigine,
    List<String>? villages,
    List<String>? attributeurs,
    List<PrelevementStatus>? statuts,
    DateTime? dateAttributionFrom,
    DateTime? dateAttributionTo,
    DateTime? dateReceptionFrom,
    DateTime? dateReceptionTo,
    double? poidsMin,
    double? poidsMax,
    bool? seulementDisponibles,
    String? searchQuery,
  }) {
    return AttributedProductFilters(
      natures: natures ?? this.natures,
      sitesOrigine: sitesOrigine ?? this.sitesOrigine,
      villages: villages ?? this.villages,
      attributeurs: attributeurs ?? this.attributeurs,
      statuts: statuts ?? this.statuts,
      dateAttributionFrom: dateAttributionFrom ?? this.dateAttributionFrom,
      dateAttributionTo: dateAttributionTo ?? this.dateAttributionTo,
      dateReceptionFrom: dateReceptionFrom ?? this.dateReceptionFrom,
      dateReceptionTo: dateReceptionTo ?? this.dateReceptionTo,
      poidsMin: poidsMin ?? this.poidsMin,
      poidsMax: poidsMax ?? this.poidsMax,
      seulementDisponibles: seulementDisponibles ?? this.seulementDisponibles,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Réinitialiser tous les filtres
  AttributedProductFilters clear() {
    return const AttributedProductFilters();
  }

  /// Compte le nombre de filtres actifs
  int getActiveFiltersCount() {
    int count = 0;
    if (natures.isNotEmpty) count++;
    if (sitesOrigine.isNotEmpty) count++;
    if (villages.isNotEmpty) count++;
    if (attributeurs.isNotEmpty) count++;
    if (statuts.isNotEmpty) count++;
    if (dateAttributionFrom != null || dateAttributionTo != null) count++;
    if (dateReceptionFrom != null || dateReceptionTo != null) count++;
    if (poidsMin != null || poidsMax != null) count++;
    if (seulementDisponibles != null) count++;
    if (searchQuery.isNotEmpty) count++;
    return count;
  }

  /// Vérifie si des filtres sont appliqués
  bool get hasActiveFilters => getActiveFiltersCount() > 0;
}

/// Statistiques des produits attribués
class AttributedProductStats {
  final int totalProduits;
  final int enAttente;
  final int enCours;
  final int termines;
  final int suspendus;
  final double poidsTotal;
  final double poidsDisponible;
  final double poidsPreleve;
  final double pourcentagePrelevementMoyen;
  final int produitsComplets;
  final int produitsPartiels;
  final Map<String, int> parProvenance;
  final Map<ProductNature, int> parNature;

  const AttributedProductStats({
    required this.totalProduits,
    required this.enAttente,
    required this.enCours,
    required this.termines,
    required this.suspendus,
    required this.poidsTotal,
    required this.poidsDisponible,
    required this.poidsPreleve,
    required this.pourcentagePrelevementMoyen,
    required this.produitsComplets,
    required this.produitsPartiels,
    required this.parProvenance,
    required this.parNature,
  });

  /// Calcule les statistiques à partir d'une liste de produits
  factory AttributedProductStats.fromProducts(
      List<AttributedProduct> products) {
    final total = products.length;
    final enAttente =
        products.where((p) => p.statut == PrelevementStatus.enAttente).length;
    final enCours =
        products.where((p) => p.statut == PrelevementStatus.enCours).length;
    final termines =
        products.where((p) => p.statut == PrelevementStatus.termine).length;
    final suspendus =
        products.where((p) => p.statut == PrelevementStatus.suspendu).length;

    final poidsTotal = products.fold(0.0, (sum, p) => sum + p.poidsOriginal);
    final poidsDisponible =
        products.fold(0.0, (sum, p) => sum + p.poidsDisponible);
    final poidsPreleve = poidsTotal - poidsDisponible;

    final pourcentagePrelevementMoyen =
        poidsTotal > 0 ? (poidsPreleve / poidsTotal) * 100 : 0.0;

    final produitsComplets = products.where((p) => p.estCompletePreleve).length;
    final produitsPartiels = products
        .where(
            (p) => p.poidsDisponible < p.poidsOriginal && !p.estCompletePreleve)
        .length;

    // Grouper par provenance
    final Map<String, int> parProvenance = {};
    for (final product in products) {
      final key = product.codeLocalisation;
      parProvenance[key] = (parProvenance[key] ?? 0) + 1;
    }

    // Grouper par nature
    final Map<ProductNature, int> parNature = {};
    for (final product in products) {
      parNature[product.nature] = (parNature[product.nature] ?? 0) + 1;
    }

    return AttributedProductStats(
      totalProduits: total,
      enAttente: enAttente,
      enCours: enCours,
      termines: termines,
      suspendus: suspendus,
      poidsTotal: poidsTotal,
      poidsDisponible: poidsDisponible,
      poidsPreleve: poidsPreleve,
      pourcentagePrelevementMoyen: pourcentagePrelevementMoyen,
      produitsComplets: produitsComplets,
      produitsPartiels: produitsPartiels,
      parProvenance: parProvenance,
      parNature: parNature,
    );
  }
}
