/// 🎯 MODÈLES UNIFIÉS POUR LE SYSTÈME D'ATTRIBUTION V2
///
/// Ce fichier contient tous les modèles nécessaires pour le nouveau
/// système d'attribution unifié intégrant extraction, filtrage et traitement cire

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏷️ NATURE DES PRODUITS
///
/// Définit la nature d'un produit pour déterminer son traitement
enum ProductNature {
  brut('Brut'), // Pour extraction
  liquide('Liquide'), // Pour filtrage
  cire('Cire'), // Pour traitement cire
  filtre('Filtré'); // Déjà filtré

  const ProductNature(this.label);
  final String label;
}

/// 📋 TYPE D'ATTRIBUTION
///
/// Définit les différents types de processus d'attribution
enum AttributionType {
  extraction('Extraction', 'extraction'),
  filtration('Filtrage', 'filtration'),
  traitementCire('Traitement Cire', 'traitement_cire');

  const AttributionType(this.label, this.value);
  final String label;
  final String value;
}

/// 🧪 MODÈLE PRODUIT CONTRÔLÉ
///
/// Représente un produit ayant passé le contrôle qualité et disponible pour attribution
class ProductControle {
  final String id;
  final String codeContenant;
  final DateTime dateReception;
  final String producteur;
  final String village;
  final String commune;
  final String quartier;
  final ProductNature nature;
  final String typeContenant;
  final String numeroContenant;
  final double poidsTotal;
  final double poidsMiel;
  final String qualite;
  final double? teneurEau;
  final String predominanceFlorale;
  final bool estConforme;
  final String? causeNonConformite;
  final String? observations;
  final DateTime dateControle;
  final String? controleur;
  final bool estAttribue;
  final String? attributionId;
  final String? typeAttribution;
  final DateTime? dateAttribution;
  final String? controlId; // 🆕 ID du document de contrôle qualité
  final String siteOrigine;
  final String collecteId;
  final String typeCollecte;
  final DateTime dateCollecte;
  final bool estControle;
  final String statutControle;
  final Map<String, dynamic>? metadata;

  const ProductControle({
    required this.id,
    required this.codeContenant,
    required this.dateReception,
    required this.producteur,
    required this.village,
    required this.commune,
    required this.quartier,
    required this.nature,
    required this.typeContenant,
    required this.numeroContenant,
    required this.poidsTotal,
    required this.poidsMiel,
    required this.qualite,
    this.teneurEau,
    required this.predominanceFlorale,
    required this.estConforme,
    this.causeNonConformite,
    this.observations,
    required this.dateControle,
    this.controleur,
    this.estAttribue = false,
    this.attributionId,
    this.typeAttribution,
    this.dateAttribution,
    this.controlId, // 🆕 ID du document de contrôle qualité
    required this.siteOrigine,
    required this.collecteId,
    required this.typeCollecte,
    required this.dateCollecte,
    this.estControle = true,
    this.statutControle = 'valide',
    this.metadata,
  });

  /// Vérifie si le produit est urgent (> 7 jours)
  bool get isUrgent {
    final daysSinceReception = DateTime.now().difference(dateReception).inDays;
    return daysSinceReception > 7;
  }

  /// Retourne la couleur associée à la qualité
  Color get qualiteColor {
    switch (qualite.toLowerCase()) {
      case 'excellent':
        return Colors.green[700]!;
      case 'très bon':
        return Colors.green[500]!;
      case 'bon':
        return Colors.orange[600]!;
      case 'moyen':
        return Colors.orange[400]!;
      case 'passable':
        return Colors.red[400]!;
      default:
        return Colors.grey[600]!;
    }
  }

  /// Retourne l'icône associée à la nature
  IconData get natureIcon {
    switch (nature) {
      case ProductNature.brut:
        return Icons.science;
      case ProductNature.liquide:
        return Icons.water_drop;
      case ProductNature.cire:
        return Icons.spa;
      case ProductNature.filtre:
        return Icons.filter_alt;
    }
  }

  /// Retourne la couleur associée à la nature
  Color get natureColor {
    switch (nature) {
      case ProductNature.brut:
        return Colors.brown;
      case ProductNature.liquide:
        return Colors.blue;
      case ProductNature.cire:
        return Colors.amber[700]!;
      case ProductNature.filtre:
        return Colors.green;
    }
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codeContenant': codeContenant,
      'dateReception': dateReception.toIso8601String(),
      'producteur': producteur,
      'village': village,
      'commune': commune,
      'quartier': quartier,
      'nature': nature.name,
      'typeContenant': typeContenant,
      'numeroContenant': numeroContenant,
      'poidsTotal': poidsTotal,
      'poidsMiel': poidsMiel,
      'qualite': qualite,
      'teneurEau': teneurEau,
      'predominanceFlorale': predominanceFlorale,
      'estConforme': estConforme,
      'causeNonConformite': causeNonConformite,
      'observations': observations,
      'dateControle': dateControle.toIso8601String(),
      'controleur': controleur,
      'estAttribue': estAttribue,
      'attributionId': attributionId,
      'typeAttribution': typeAttribution,
      'dateAttribution': dateAttribution?.toIso8601String(),
      'controlId': controlId, // 🆕 ID du document de contrôle qualité
      'siteOrigine': siteOrigine,
      'collecteId': collecteId,
      'typeCollecte': typeCollecte,
      'dateCollecte': dateCollecte.toIso8601String(),
      'estControle': estControle,
      'statutControle': statutControle,
      'metadata': metadata,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Création depuis Map Firestore
  factory ProductControle.fromMap(Map<String, dynamic> map) {
    return ProductControle(
      id: map['id'] ?? '',
      codeContenant: map['codeContenant'] ?? '',
      dateReception: _parseDateTime(map['dateReception']),
      producteur: map['producteur'] ?? '',
      village: map['village'] ?? '',
      commune: map['commune'] ?? '',
      quartier: map['quartier'] ?? '',
      nature: ProductNature.values.firstWhere(
        (n) => n.name == map['nature'],
        orElse: () => ProductNature.brut,
      ),
      typeContenant: map['typeContenant'] ?? '',
      numeroContenant: map['numeroContenant'] ?? '',
      poidsTotal: (map['poidsTotal'] as num?)?.toDouble() ?? 0.0,
      poidsMiel: (map['poidsMiel'] as num?)?.toDouble() ?? 0.0,
      qualite: map['qualite'] ?? '',
      teneurEau: (map['teneurEau'] as num?)?.toDouble(),
      predominanceFlorale: map['predominanceFlorale'] ?? '',
      estConforme: map['estConforme'] ?? false,
      causeNonConformite: map['causeNonConformite'],
      observations: map['observations'],
      dateControle: _parseDateTime(map['dateControle']),
      controleur: map['controleur'],
      estAttribue: map['estAttribue'] ?? false,
      attributionId: map['attributionId'],
      typeAttribution: map['typeAttribution'],
      dateAttribution: map['dateAttribution'] != null
          ? _parseDateTime(map['dateAttribution'])
          : null,
      controlId: map['controlId'], // 🆕 ID du document de contrôle qualité
      siteOrigine: map['siteOrigine'] ?? '',
      collecteId: map['collecteId'] ?? '',
      typeCollecte: map['typeCollecte'] ?? '',
      dateCollecte: _parseDateTime(map['dateCollecte']),
      estControle: map['estControle'] ?? true,
      statutControle: map['statutControle'] ?? 'valide',
      metadata: map['metadata'],
    );
  }

  /// Parse DateTime depuis différents formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  /// Crée une copie avec des modifications
  ProductControle copyWith({
    String? id,
    String? codeContenant,
    DateTime? dateReception,
    String? producteur,
    String? village,
    String? commune,
    String? quartier,
    ProductNature? nature,
    String? typeContenant,
    String? numeroContenant,
    double? poidsTotal,
    double? poidsMiel,
    String? qualite,
    double? teneurEau,
    String? predominanceFlorale,
    bool? estConforme,
    String? causeNonConformite,
    String? observations,
    DateTime? dateControle,
    String? controleur,
    bool? estAttribue,
    String? attributionId,
    String? typeAttribution,
    DateTime? dateAttribution,
    String? controlId, // 🆕 ID du document de contrôle qualité
    String? siteOrigine,
    String? collecteId,
    String? typeCollecte,
    DateTime? dateCollecte,
    bool? estControle,
    String? statutControle,
    Map<String, dynamic>? metadata,
  }) {
    return ProductControle(
      id: id ?? this.id,
      codeContenant: codeContenant ?? this.codeContenant,
      dateReception: dateReception ?? this.dateReception,
      producteur: producteur ?? this.producteur,
      village: village ?? this.village,
      commune: commune ?? this.commune,
      quartier: quartier ?? this.quartier,
      nature: nature ?? this.nature,
      typeContenant: typeContenant ?? this.typeContenant,
      numeroContenant: numeroContenant ?? this.numeroContenant,
      poidsTotal: poidsTotal ?? this.poidsTotal,
      poidsMiel: poidsMiel ?? this.poidsMiel,
      qualite: qualite ?? this.qualite,
      teneurEau: teneurEau ?? this.teneurEau,
      predominanceFlorale: predominanceFlorale ?? this.predominanceFlorale,
      estConforme: estConforme ?? this.estConforme,
      causeNonConformite: causeNonConformite ?? this.causeNonConformite,
      observations: observations ?? this.observations,
      dateControle: dateControle ?? this.dateControle,
      controleur: controleur ?? this.controleur,
      estAttribue: estAttribue ?? this.estAttribue,
      attributionId: attributionId ?? this.attributionId,
      typeAttribution: typeAttribution ?? this.typeAttribution,
      dateAttribution: dateAttribution ?? this.dateAttribution,
      controlId:
          controlId ?? this.controlId, // 🆕 ID du document de contrôle qualité
      siteOrigine: siteOrigine ?? this.siteOrigine,
      collecteId: collecteId ?? this.collecteId,
      typeCollecte: typeCollecte ?? this.typeCollecte,
      dateCollecte: dateCollecte ?? this.dateCollecte,
      estControle: estControle ?? this.estControle,
      statutControle: statutControle ?? this.statutControle,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 📊 ATTRIBUTION DE CONTRÔLE
///
/// Modèle pour les attributions créées depuis le contrôle qualité
class ControlAttribution {
  final String id;
  final AttributionType type;
  final ProductNature natureProduitsAttribues;
  final String utilisateur;
  final List<String> listeContenants;
  final String sourceCollecteId;
  final String sourceType;
  final String siteOrigine;
  final String siteReceveur;
  final DateTime dateCollecte;
  final DateTime dateCreation;
  final String statut;
  final String? commentaires;
  final Map<String, dynamic>? metadata;

  const ControlAttribution({
    required this.id,
    required this.type,
    required this.natureProduitsAttribues,
    required this.utilisateur,
    required this.listeContenants,
    required this.sourceCollecteId,
    required this.sourceType,
    required this.siteOrigine,
    required this.siteReceveur,
    required this.dateCollecte,
    required this.dateCreation,
    this.statut = 'attribué',
    this.commentaires,
    this.metadata,
  });

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'natureProduitsAttribues': natureProduitsAttribues.name,
      'utilisateur': utilisateur,
      'listeContenants': listeContenants,
      'sourceCollecteId': sourceCollecteId,
      'sourceType': sourceType,
      'siteOrigine': siteOrigine,
      'siteReceveur': siteReceveur,
      'dateCollecte': dateCollecte.toIso8601String(),
      'dateCreation': dateCreation.toIso8601String(),
      'statut': statut,
      'commentaires': commentaires,
      'metadata': metadata,
    };
  }

  /// Création depuis Map Firestore
  factory ControlAttribution.fromMap(Map<String, dynamic> map) {
    return ControlAttribution(
      id: map['id'] ?? '',
      type: AttributionType.values.firstWhere(
        (t) => t.value == map['type'],
        orElse: () => AttributionType.extraction,
      ),
      natureProduitsAttribues: ProductNature.values.firstWhere(
        (n) => n.name == map['natureProduitsAttribues'],
        orElse: () => ProductNature.brut,
      ),
      utilisateur: map['utilisateur'] ?? '',
      listeContenants: List<String>.from(map['listeContenants'] ?? []),
      sourceCollecteId: map['sourceCollecteId'] ?? '',
      sourceType: map['sourceType'] ?? '',
      siteOrigine: map['siteOrigine'] ?? '',
      siteReceveur: map['siteReceveur'] ?? '',
      dateCollecte: ProductControle._parseDateTime(map['dateCollecte']),
      dateCreation: ProductControle._parseDateTime(map['dateCreation']),
      statut: map['statut'] ?? 'attribué',
      commentaires: map['commentaires'],
      metadata: map['metadata'],
    );
  }
}

/// 🛠️ UTILITAIRES POUR L'ATTRIBUTION
class AttributionUtils {
  /// Vérifie si un produit peut être attribué pour un type donné
  static bool peutEtreAttribue(ProductControle produit, AttributionType type) {
    // VERIFICATION CRITIQUE: Le produit DOIT être contrôlé ET conforme
    if (!produit.estControle || !produit.estConforme || produit.estAttribue) {
      return false;
    }

    // Vérifier que le statut de contrôle est validé
    if (produit.statutControle != 'valide' &&
        produit.statutControle != 'termine') {
      return false;
    }

    // Vérification selon le type d'attribution
    switch (type) {
      case AttributionType.extraction:
        return produit.nature == ProductNature.brut;
      case AttributionType.filtration:
        return produit.nature == ProductNature.liquide;
      case AttributionType.traitementCire:
        // Pour la cire, on accepte même si pas encore contrôlée
        return produit.nature == ProductNature.cire;
    }
  }

  /// Retourne la couleur associée à un type d'attribution
  static Color getCouleurType(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return Colors.brown;
      case AttributionType.filtration:
        return Colors.blue;
      case AttributionType.traitementCire:
        return Colors.amber[700]!;
    }
  }

  /// Retourne l'icône associée à un type d'attribution
  static IconData getIconeType(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return Icons.science;
      case AttributionType.filtration:
        return Icons.water_drop;
      case AttributionType.traitementCire:
        return Icons.spa;
    }
  }

  /// Retourne la description d'un type d'attribution
  static String getDescriptionType(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return 'Processus d\'extraction du miel brut';
      case AttributionType.filtration:
        return 'Processus de filtrage du miel liquide';
      case AttributionType.traitementCire:
        return 'Processus de traitement de la cire';
    }
  }
}
