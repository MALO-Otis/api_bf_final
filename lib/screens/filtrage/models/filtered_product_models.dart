import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Statut du produit à filtrer
enum FilteredProductStatus {
  enAttente(
      'en_attente', 'En Attente', 'Produit attribué mais pas encore traité'),
  enCoursTraitement('en_cours', 'En Cours', 'Filtrage en cours'),
  termine('termine', 'Terminé', 'Filtrage terminé'),
  suspendu('suspendu', 'Suspendu', 'Filtrage suspendu');

  const FilteredProductStatus(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;
}

/// Modèle pour un produit attribué au filtrage
class FilteredProduct {
  final String id;
  final String attributionId;
  final String codeContenant;
  final String typeCollecte;
  final String collecteId;
  final String producteur;
  final String village;
  final String siteOrigine;
  final ProductNature nature; // LIQUIDE ou produits extraits non filtrés
  final String typeContenant;
  final double poidsOriginal;
  final double poidsDisponible;
  final double? teneurEau;
  final String predominanceFlorale;
  final String qualite;
  final DateTime dateAttribution;
  final DateTime dateReception;
  final String attributeur; // Extracteur qui a attribué
  final String? instructions;
  final FilteredProductStatus statut;
  final DateTime? dateDebutFiltrage;
  final DateTime? dateFinFiltrage;
  final double? poidsFiltre; // Poids du produit après filtrage
  final String? observations;
  final bool
      estOrigineDuControle; // Si vient directement du contrôle (produit liquide contrôlé)
  final bool
      estOrigineDeLExtraction; // Si vient de l'extraction (produit extrait non filtré)

  const FilteredProduct({
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
    required this.dateAttribution,
    required this.dateReception,
    required this.attributeur,
    this.instructions,
    this.statut = FilteredProductStatus.enAttente,
    this.dateDebutFiltrage,
    this.dateFinFiltrage,
    this.poidsFiltre,
    this.observations,
    this.estOrigineDuControle = false,
    this.estOrigineDeLExtraction = false,
  });

  /// Factory pour créer depuis un produit contrôlé (origine contrôle)
  factory FilteredProduct.fromProductControle(
    ProductControle produit,
    String attributionId,
    String attributeurNom,
    DateTime dateAttribution,
  ) {
    return FilteredProduct(
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
      poidsOriginal: produit.poids,
      poidsDisponible: produit.poids,
      teneurEau: produit.teneurEau,
      predominanceFlorale: produit.predominanceFlorale,
      qualite: produit.qualite,
      dateAttribution: dateAttribution,
      dateReception: produit.dateReception,
      attributeur: attributeurNom,
      estOrigineDuControle: true,
      estOrigineDeLExtraction: false,
    );
  }

  /// Factory pour créer depuis un produit extrait (origine extraction)
  factory FilteredProduct.fromExtractedProduct(
    Map<String, dynamic> produitExtrait,
    String attributionId,
    String extracteurNom,
    DateTime dateAttribution,
  ) {
    return FilteredProduct(
      id: produitExtrait['id'],
      attributionId: attributionId,
      codeContenant: produitExtrait['codeContenant'],
      typeCollecte: produitExtrait['typeCollecte'],
      collecteId: produitExtrait['collecteId'],
      producteur: produitExtrait['producteur'],
      village: produitExtrait['village'],
      siteOrigine: produitExtrait['siteOrigine'],
      nature: ProductNature.filtre, // Produit extrait = liquide non filtré
      typeContenant: produitExtrait['typeContenant'],
      poidsOriginal: produitExtrait['poidsExtrait'],
      poidsDisponible: produitExtrait['poidsExtrait'],
      teneurEau: produitExtrait['teneurEau'],
      predominanceFlorale: produitExtrait['predominanceFlorale'],
      qualite: produitExtrait['qualite'],
      dateAttribution: dateAttribution,
      dateReception: DateTime.parse(produitExtrait['dateExtraction']),
      attributeur: extracteurNom,
      estOrigineDuControle: false,
      estOrigineDeLExtraction: true,
    );
  }

  /// Copie avec modifications
  FilteredProduct copyWith({
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
    DateTime? dateAttribution,
    DateTime? dateReception,
    String? attributeur,
    String? instructions,
    FilteredProductStatus? statut,
    DateTime? dateDebutFiltrage,
    DateTime? dateFinFiltrage,
    double? poidsFiltre,
    String? observations,
    bool? estOrigineDuControle,
    bool? estOrigineDeLExtraction,
  }) {
    return FilteredProduct(
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
      dateAttribution: dateAttribution ?? this.dateAttribution,
      dateReception: dateReception ?? this.dateReception,
      attributeur: attributeur ?? this.attributeur,
      instructions: instructions ?? this.instructions,
      statut: statut ?? this.statut,
      dateDebutFiltrage: dateDebutFiltrage ?? this.dateDebutFiltrage,
      dateFinFiltrage: dateFinFiltrage ?? this.dateFinFiltrage,
      poidsFiltre: poidsFiltre ?? this.poidsFiltre,
      observations: observations ?? this.observations,
      estOrigineDuControle: estOrigineDuControle ?? this.estOrigineDuControle,
      estOrigineDeLExtraction:
          estOrigineDeLExtraction ?? this.estOrigineDeLExtraction,
    );
  }

  /// Convertit en Map pour sauvegarde
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
      'date_attribution': dateAttribution.toIso8601String(),
      'date_reception': dateReception.toIso8601String(),
      'attributeur': attributeur,
      'instructions': instructions,
      'statut': statut.value,
      'date_debut_filtrage': dateDebutFiltrage?.toIso8601String(),
      'date_fin_filtrage': dateFinFiltrage?.toIso8601String(),
      'poids_filtre': poidsFiltre,
      'observations': observations,
      'est_origine_du_controle': estOrigineDuControle,
      'est_origine_de_lextraction': estOrigineDeLExtraction,
    };
  }

  /// Origine du produit en format lisible
  String get origineDescription {
    if (estOrigineDuControle) {
      return 'Produit Liquide Contrôlé';
    } else if (estOrigineDeLExtraction) {
      return 'Produit Extrait (Non Filtré)';
    } else {
      return 'Origine Inconnue';
    }
  }

  /// Durée de filtrage si terminé
  Duration? get dureeFiltrage {
    if (dateDebutFiltrage != null && dateFinFiltrage != null) {
      return dateFinFiltrage!.difference(dateDebutFiltrage!);
    }
    return null;
  }

  /// Rendement de filtrage si terminé
  double? get rendementFiltrage {
    if (poidsFiltre != null && poidsOriginal > 0) {
      return (poidsFiltre! / poidsOriginal) * 100;
    }
    return null;
  }

  @override
  String toString() {
    return 'FilteredProduct{id: $id, producteur: $producteur, nature: ${nature.label}, statut: ${statut.label}, origine: $origineDescription}';
  }
}

/// Filtres pour les produits filtrés
class FilteredProductFilters {
  final String? siteFiltreur;
  final FilteredProductStatus? statut;
  final ProductNature? nature;
  final String? producteur;
  final String? village;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final bool? origineControle;
  final bool? origineExtraction;
  final String? attributeur;

  const FilteredProductFilters({
    this.siteFiltreur,
    this.statut,
    this.nature,
    this.producteur,
    this.village,
    this.dateDebut,
    this.dateFin,
    this.origineControle,
    this.origineExtraction,
    this.attributeur,
  });

  /// Vérifie si un produit correspond aux filtres
  bool matches(FilteredProduct product) {
    if (siteFiltreur != null &&
        !product.siteOrigine
            .toLowerCase()
            .contains(siteFiltreur!.toLowerCase())) {
      return false;
    }
    if (statut != null && product.statut != statut) {
      return false;
    }
    if (nature != null && product.nature != nature) {
      return false;
    }
    if (producteur != null &&
        !product.producteur.toLowerCase().contains(producteur!.toLowerCase())) {
      return false;
    }
    if (village != null &&
        !product.village.toLowerCase().contains(village!.toLowerCase())) {
      return false;
    }
    if (dateDebut != null && product.dateAttribution.isBefore(dateDebut!)) {
      return false;
    }
    if (dateFin != null && product.dateAttribution.isAfter(dateFin!)) {
      return false;
    }
    if (origineControle != null &&
        product.estOrigineDuControle != origineControle) {
      return false;
    }
    if (origineExtraction != null &&
        product.estOrigineDeLExtraction != origineExtraction) {
      return false;
    }
    if (attributeur != null &&
        !product.attributeur
            .toLowerCase()
            .contains(attributeur!.toLowerCase())) {
      return false;
    }
    return true;
  }
}

/// Statistiques pour les produits filtrés
class FilteredProductStats {
  final int totalProduits;
  final int enAttente;
  final int enCours;
  final int termines;
  final int suspendus;
  final double poidsTotal;
  final double poidsFiltre;
  final int origineDuControle;
  final int origineDeLExtraction;

  const FilteredProductStats({
    required this.totalProduits,
    required this.enAttente,
    required this.enCours,
    required this.termines,
    required this.suspendus,
    required this.poidsTotal,
    required this.poidsFiltre,
    required this.origineDuControle,
    required this.origineDeLExtraction,
  });

  factory FilteredProductStats.fromProducts(List<FilteredProduct> products) {
    var totalProduits = products.length;
    var enAttente = products
        .where((p) => p.statut == FilteredProductStatus.enAttente)
        .length;
    var enCours = products
        .where((p) => p.statut == FilteredProductStatus.enCoursTraitement)
        .length;
    var termines =
        products.where((p) => p.statut == FilteredProductStatus.termine).length;
    var suspendus = products
        .where((p) => p.statut == FilteredProductStatus.suspendu)
        .length;
    var poidsTotal =
        products.fold<double>(0, (sum, p) => sum + p.poidsOriginal);
    var poidsFiltre =
        products.fold<double>(0, (sum, p) => sum + (p.poidsFiltre ?? 0));
    var origineDuControle =
        products.where((p) => p.estOrigineDuControle).length;
    var origineDeLExtraction =
        products.where((p) => p.estOrigineDeLExtraction).length;

    return FilteredProductStats(
      totalProduits: totalProduits,
      enAttente: enAttente,
      enCours: enCours,
      termines: termines,
      suspendus: suspendus,
      poidsTotal: poidsTotal,
      poidsFiltre: poidsFiltre,
      origineDuControle: origineDuControle,
      origineDeLExtraction: origineDeLExtraction,
    );
  }

  /// Rendement global de filtrage
  double get rendementGlobal {
    if (poidsTotal > 0) {
      return (poidsFiltre / poidsTotal) * 100;
    }
    return 0.0;
  }

  /// Progression du filtrage
  double get progressionFiltrage {
    if (totalProduits > 0) {
      return (termines / totalProduits) * 100;
    }
    return 0.0;
  }
}
