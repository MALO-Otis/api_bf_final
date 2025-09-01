// Modèles pour le nouveau système d'attribution intelligent
import 'package:flutter/material.dart';

/// Types d'attribution disponibles
enum AttributionType {
  extraction('Pour Extraction', 'Produits bruts uniquement'),
  filtration('Pour Filtration', 'Produits filtrés uniquement'),
  traitementCire('Pour Traitement Cire', 'Produits cire uniquement');

  const AttributionType(this.label, this.description);
  final String label;
  final String description;
}

/// Types de produits selon leur nature
enum ProductNature {
  brut('Brut'),
  filtre('Filtré'),
  cire('Cire');

  const ProductNature(this.label);
  final String label;
}

/// Sites disponibles pour attribution
enum SiteAttribution {
  koudougou('Koudougou'),
  bobo('Bobo-Dioulasso'),
  po('Pô'),
  mangodara('Mangodara'),
  sindou('Sindou'),
  orodara('Orodara'),
  sapouy('Sapouy'),
  leo('Léo'),
  bagre('Bagré');

  const SiteAttribution(this.nom);
  final String nom;
}

/// Modèle pour un produit contrôlé disponible pour attribution
class ProductControle {
  final String id;
  final String codeContenant;
  final String typeCollecte; // 'recolte', 'individuel', 'scoop', 'miellerie'
  final String collecteId;
  final String producteur;
  final String village;
  final ProductNature nature; // Déterminé par le type de miel
  final String typeContenant;
  final double poids;
  final double? teneurEau;
  final String predominanceFlorale;
  final String qualite;
  final DateTime dateReception;
  final DateTime dateCollecte;
  final String collecteur;
  final String siteOrigine;
  final bool estConforme;
  final String? causeNonConformite;
  final String? observations;
  final bool estAttribue; // Si déjà attribué
  final String? attributionId; // ID de l'attribution si attribué

  const ProductControle({
    required this.id,
    required this.codeContenant,
    required this.typeCollecte,
    required this.collecteId,
    required this.producteur,
    required this.village,
    required this.nature,
    required this.typeContenant,
    required this.poids,
    this.teneurEau,
    required this.predominanceFlorale,
    required this.qualite,
    required this.dateReception,
    required this.dateCollecte,
    required this.collecteur,
    required this.siteOrigine,
    required this.estConforme,
    this.causeNonConformite,
    this.observations,
    this.estAttribue = false,
    this.attributionId,
  });

  ProductControle copyWith({
    String? id,
    String? codeContenant,
    String? typeCollecte,
    String? collecteId,
    String? producteur,
    String? village,
    ProductNature? nature,
    String? typeContenant,
    double? poids,
    double? teneurEau,
    String? predominanceFlorale,
    String? qualite,
    DateTime? dateReception,
    DateTime? dateCollecte,
    String? collecteur,
    String? siteOrigine,
    bool? estConforme,
    String? causeNonConformite,
    String? observations,
    bool? estAttribue,
    String? attributionId,
  }) {
    return ProductControle(
      id: id ?? this.id,
      codeContenant: codeContenant ?? this.codeContenant,
      typeCollecte: typeCollecte ?? this.typeCollecte,
      collecteId: collecteId ?? this.collecteId,
      producteur: producteur ?? this.producteur,
      village: village ?? this.village,
      nature: nature ?? this.nature,
      typeContenant: typeContenant ?? this.typeContenant,
      poids: poids ?? this.poids,
      teneurEau: teneurEau ?? this.teneurEau,
      predominanceFlorale: predominanceFlorale ?? this.predominanceFlorale,
      qualite: qualite ?? this.qualite,
      dateReception: dateReception ?? this.dateReception,
      dateCollecte: dateCollecte ?? this.dateCollecte,
      collecteur: collecteur ?? this.collecteur,
      siteOrigine: siteOrigine ?? this.siteOrigine,
      estConforme: estConforme ?? this.estConforme,
      causeNonConformite: causeNonConformite ?? this.causeNonConformite,
      observations: observations ?? this.observations,
      estAttribue: estAttribue ?? this.estAttribue,
      attributionId: attributionId ?? this.attributionId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code_contenant': codeContenant,
      'type_collecte': typeCollecte,
      'collecte_id': collecteId,
      'producteur': producteur,
      'village': village,
      'nature': nature.name,
      'type_contenant': typeContenant,
      'poids': poids,
      'teneur_eau': teneurEau,
      'predominance_florale': predominanceFlorale,
      'qualite': qualite,
      'date_reception': dateReception.toIso8601String(),
      'date_collecte': dateCollecte.toIso8601String(),
      'collecteur': collecteur,
      'site_origine': siteOrigine,
      'est_conforme': estConforme,
      'cause_non_conformite': causeNonConformite,
      'observations': observations,
      'est_attribue': estAttribue,
      'attribution_id': attributionId,
    };
  }

  factory ProductControle.fromMap(Map<String, dynamic> map) {
    return ProductControle(
      id: map['id'] ?? '',
      codeContenant: map['code_contenant'] ?? '',
      typeCollecte: map['type_collecte'] ?? '',
      collecteId: map['collecte_id'] ?? '',
      producteur: map['producteur'] ?? '',
      village: map['village'] ?? '',
      nature: ProductNature.values.firstWhere(
        (n) => n.name == map['nature'],
        orElse: () => ProductNature.brut,
      ),
      typeContenant: map['type_contenant'] ?? '',
      poids: (map['poids'] ?? 0.0).toDouble(),
      teneurEau: map['teneur_eau']?.toDouble(),
      predominanceFlorale: map['predominance_florale'] ?? '',
      qualite: map['qualite'] ?? '',
      dateReception: DateTime.parse(map['date_reception']),
      dateCollecte: DateTime.parse(map['date_collecte']),
      collecteur: map['collecteur'] ?? '',
      siteOrigine: map['site_origine'] ?? '',
      estConforme: map['est_conforme'] ?? true,
      causeNonConformite: map['cause_non_conformite'],
      observations: map['observations'],
      estAttribue: map['est_attribue'] ?? false,
      attributionId: map['attribution_id'],
    );
  }
}

/// Regroupement des produits par collecte
class CollecteGroup {
  final String collecteId;
  final String typeCollecte;
  final String producteur;
  final DateTime dateCollecte;
  final String collecteur;
  final String siteOrigine;
  final List<ProductControle> produits;
  final bool isExpanded;

  const CollecteGroup({
    required this.collecteId,
    required this.typeCollecte,
    required this.producteur,
    required this.dateCollecte,
    required this.collecteur,
    required this.siteOrigine,
    required this.produits,
    this.isExpanded = false,
  });

  int get totalProduits => produits.length;
  int get produitsConformes => produits.where((p) => p.estConforme).length;
  int get produitsNonConformes => produits.where((p) => !p.estConforme).length;
  int get produitsAttribues => produits.where((p) => p.estAttribue).length;
  int get produitsDisponibles => produits.where((p) => !p.estAttribue).length;
  double get poidsTotal => produits.fold(0.0, (sum, p) => sum + p.poids);

  CollecteGroup copyWith({
    String? collecteId,
    String? typeCollecte,
    String? producteur,
    DateTime? dateCollecte,
    String? collecteur,
    String? siteOrigine,
    List<ProductControle>? produits,
    bool? isExpanded,
  }) {
    return CollecteGroup(
      collecteId: collecteId ?? this.collecteId,
      typeCollecte: typeCollecte ?? this.typeCollecte,
      producteur: producteur ?? this.producteur,
      dateCollecte: dateCollecte ?? this.dateCollecte,
      collecteur: collecteur ?? this.collecteur,
      siteOrigine: siteOrigine ?? this.siteOrigine,
      produits: produits ?? this.produits,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

/// Modèle pour une attribution créée
class AttributionProduits {
  final String id;
  final AttributionType type;
  final SiteAttribution siteDestination;
  final List<String> produitsIds;
  final DateTime dateAttribution;
  final String attributeurId;
  final String attributeurNom;
  final String? instructions;
  final String? observations;
  final String statut; // 'en_attente', 'accepte', 'en_cours', 'termine'

  const AttributionProduits({
    required this.id,
    required this.type,
    required this.siteDestination,
    required this.produitsIds,
    required this.dateAttribution,
    required this.attributeurId,
    required this.attributeurNom,
    this.instructions,
    this.observations,
    this.statut = 'en_attente',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'site_destination': siteDestination.name,
      'produits_ids': produitsIds,
      'date_attribution': dateAttribution.toIso8601String(),
      'attributeur_id': attributeurId,
      'attributeur_nom': attributeurNom,
      'instructions': instructions,
      'observations': observations,
      'statut': statut,
    };
  }

  factory AttributionProduits.fromMap(Map<String, dynamic> map) {
    return AttributionProduits(
      id: map['id'] ?? '',
      type: AttributionType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => AttributionType.extraction,
      ),
      siteDestination: SiteAttribution.values.firstWhere(
        (s) => s.name == map['site_destination'],
        orElse: () => SiteAttribution.koudougou,
      ),
      produitsIds: List<String>.from(map['produits_ids'] ?? []),
      dateAttribution: DateTime.parse(map['date_attribution']),
      attributeurId: map['attributeur_id'] ?? '',
      attributeurNom: map['attributeur_nom'] ?? '',
      instructions: map['instructions'],
      observations: map['observations'],
      statut: map['statut'] ?? 'en_attente',
    );
  }
}

/// Utilitaires pour les attributions
class AttributionUtils {
  /// Détermine si un produit peut être attribué selon le type d'attribution
  static bool peutEtreAttribue(ProductControle produit, AttributionType type) {
    if (!produit.estConforme || produit.estAttribue) {
      return false;
    }

    switch (type) {
      case AttributionType.extraction:
        return produit.nature == ProductNature.brut;
      case AttributionType.filtration:
        return produit.nature == ProductNature.filtre;
      case AttributionType.traitementCire:
        return produit.nature == ProductNature.cire;
    }
  }

  /// Filtre les produits selon le type d'attribution
  static List<ProductControle> filtrerProduitsParType(
    List<ProductControle> produits,
    AttributionType type,
  ) {
    return produits.where((p) => peutEtreAttribue(p, type)).toList();
  }

  /// Détermine la nature du produit selon le type de miel
  static ProductNature determinerNature(String typeMiel) {
    final type = typeMiel.toLowerCase();
    if (type.contains('cire')) {
      return ProductNature.cire;
    } else if (type.contains('filtr') || type.contains('liquid')) {
      return ProductNature.filtre;
    } else {
      return ProductNature.brut;
    }
  }

  /// Couleur pour le type de collecte
  static Color getCouleurTypeCollecte(String typeCollecte) {
    switch (typeCollecte.toLowerCase()) {
      case 'recolte':
        return Colors.green;
      case 'individuel':
        return Colors.blue;
      case 'scoop':
        return Colors.orange;
      case 'miellerie':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Icône pour le type de collecte
  static IconData getIconeTypeCollecte(String typeCollecte) {
    switch (typeCollecte.toLowerCase()) {
      case 'recolte':
        return Icons.agriculture;
      case 'individuel':
        return Icons.person;
      case 'scoop':
        return Icons.groups;
      case 'miellerie':
        return Icons.factory;
      default:
        return Icons.inventory;
    }
  }

  /// Couleur pour la nature du produit
  static Color getCouleurNature(ProductNature nature) {
    switch (nature) {
      case ProductNature.brut:
        return Colors.amber;
      case ProductNature.filtre:
        return Colors.blue;
      case ProductNature.cire:
        return Colors.brown;
    }
  }

  /// Icône pour la nature du produit
  static IconData getIconeNature(ProductNature nature) {
    switch (nature) {
      case ProductNature.brut:
        return Icons.water_drop;
      case ProductNature.filtre:
        return Icons.filter_alt;
      case ProductNature.cire:
        return Icons.texture;
    }
  }

  /// Couleur pour le type d'attribution
  static Color getCouleurAttribution(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return Colors.green;
      case AttributionType.filtration:
        return Colors.blue;
      case AttributionType.traitementCire:
        return Colors.brown;
    }
  }

  /// Icône pour le type d'attribution
  static IconData getIconeAttribution(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return Icons.science;
      case AttributionType.filtration:
        return Icons.filter_alt;
      case AttributionType.traitementCire:
        return Icons.texture;
    }
  }
}
