import 'package:flutter/foundation.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Types d'attribution spécifiques à l'extraction
enum ExtractionAttributionType {
  filtration('filtration', 'Pour Filtration', 'Produits extraits non filtrés');

  const ExtractionAttributionType(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;
}

/// Modèle pour une attribution depuis l'extraction vers le filtrage
class ExtractionAttribution {
  final String id;
  final ExtractionAttributionType type;
  final SiteAttribution siteDestination;
  final List<String> produitsExtraitsIds;
  final DateTime dateAttribution;
  final String extracteurId;
  final String extracteurNom;
  final String? instructions;
  final String? observations;
  final String statut; // 'en_attente', 'accepte', 'en_cours', 'termine'

  const ExtractionAttribution({
    required this.id,
    required this.type,
    required this.siteDestination,
    required this.produitsExtraitsIds,
    required this.dateAttribution,
    required this.extracteurId,
    required this.extracteurNom,
    this.instructions,
    this.observations,
    this.statut = 'en_attente',
  });

  /// Copie avec modifications
  ExtractionAttribution copyWith({
    String? id,
    ExtractionAttributionType? type,
    SiteAttribution? siteDestination,
    List<String>? produitsExtraitsIds,
    DateTime? dateAttribution,
    String? extracteurId,
    String? extracteurNom,
    String? instructions,
    String? observations,
    String? statut,
  }) {
    return ExtractionAttribution(
      id: id ?? this.id,
      type: type ?? this.type,
      siteDestination: siteDestination ?? this.siteDestination,
      produitsExtraitsIds: produitsExtraitsIds ?? this.produitsExtraitsIds,
      dateAttribution: dateAttribution ?? this.dateAttribution,
      extracteurId: extracteurId ?? this.extracteurId,
      extracteurNom: extracteurNom ?? this.extracteurNom,
      instructions: instructions ?? this.instructions,
      observations: observations ?? this.observations,
      statut: statut ?? this.statut,
    );
  }

  /// Convertit en Map pour sauvegarde
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'site_destination': siteDestination.name,
      'produits_extraits_ids': produitsExtraitsIds,
      'date_attribution': dateAttribution.toIso8601String(),
      'extracteur_id': extracteurId,
      'extracteur_nom': extracteurNom,
      'instructions': instructions,
      'observations': observations,
      'statut': statut,
    };
  }

  /// Crée depuis une Map
  factory ExtractionAttribution.fromMap(Map<String, dynamic> map) {
    return ExtractionAttribution(
      id: map['id'] ?? '',
      type: ExtractionAttributionType.values.firstWhere(
        (t) => t.value == map['type'],
        orElse: () => ExtractionAttributionType.filtration,
      ),
      siteDestination: SiteAttribution.values.firstWhere(
        (s) => s.name == map['site_destination'],
        orElse: () => SiteAttribution.koudougou,
      ),
      produitsExtraitsIds:
          List<String>.from(map['produits_extraits_ids'] ?? []),
      dateAttribution: DateTime.parse(map['date_attribution']),
      extracteurId: map['extracteur_id'] ?? '',
      extracteurNom: map['extracteur_nom'] ?? '',
      instructions: map['instructions'],
      observations: map['observations'],
      statut: map['statut'] ?? 'en_attente',
    );
  }
}

/// Service pour gérer les attributions depuis l'extraction
class ExtractionAttributionService {
  static final ExtractionAttributionService _instance =
      ExtractionAttributionService._internal();
  factory ExtractionAttributionService() => _instance;
  ExtractionAttributionService._internal();

  // Stockage en mémoire des attributions
  final Map<String, ExtractionAttribution> _attributions = {};
  final Map<String, Map<String, dynamic>> _produitsExtraits = {};

  /// Récupère tous les produits extraits disponibles pour attribution
  Future<List<Map<String, dynamic>>> getProduitsExtraitsDisponibles() async {
    // Simulation de produits extraits prêts pour attribution au filtrage
    final produits = [
      {
        'id': 'ext_prod_001',
        'codeContenant': 'EXT_KDG_2024_001',
        'typeCollecte': 'recolte',
        'collecteId': 'rec_001',
        'producteur': 'OUEDRAOGO Moussa',
        'village': 'Koudougou',
        'siteOrigine': 'Koudougou',
        'typeContenant': 'Bidon 25L',
        'poidsExtrait': 18.5,
        'poidsOriginal': 22.0,
        'teneurEau': 18.2,
        'predominanceFlorale': 'Karité',
        'qualite': 'Extra',
        'dateExtraction': DateTime.now().subtract(const Duration(days: 2)),
        'extracteur': 'KONE Salif',
        'estAttribue': false,
        'estPretPourFiltrage': true,
        'observations': 'Extraction réussie, produit de qualité',
      },
      {
        'id': 'ext_prod_002',
        'codeContenant': 'EXT_BOB_2024_002',
        'typeCollecte': 'individuel',
        'collecteId': 'ind_002',
        'producteur': 'TRAORE Fatou',
        'village': 'Bobo-Dioulasso',
        'siteOrigine': 'Bobo-Dioulasso',
        'typeContenant': 'Bidon 20L',
        'poidsExtrait': 15.2,
        'poidsOriginal': 18.0,
        'teneurEau': 17.8,
        'predominanceFlorale': 'Acacia',
        'qualite': 'Premium',
        'dateExtraction': DateTime.now().subtract(const Duration(days: 1)),
        'extracteur': 'SAWADOGO Pierre',
        'estAttribue': false,
        'estPretPourFiltrage': true,
        'observations': 'Excellente qualité, rendement optimal',
      },
      {
        'id': 'ext_prod_003',
        'codeContenant': 'EXT_MAN_2024_003',
        'typeCollecte': 'scoop',
        'collecteId': 'scoop_003',
        'producteur': 'SCOOP Mangodara',
        'village': 'Mangodara',
        'siteOrigine': 'Mangodara',
        'typeContenant': 'Fût 50L',
        'poidsExtrait': 42.8,
        'poidsOriginal': 48.5,
        'teneurEau': 16.9,
        'predominanceFlorale': 'Multifloral',
        'qualite': 'Standard',
        'dateExtraction': DateTime.now().subtract(const Duration(hours: 18)),
        'extracteur': 'COMPAORÉ Marie',
        'estAttribue': false,
        'estPretPourFiltrage': true,
        'observations': 'Volume important, nécessite filtrage rapide',
      },
    ];

    // Stocker les produits en mémoire
    for (final produit in produits) {
      _produitsExtraits[produit['id'] as String] = produit;
    }

    // Filtrer les produits non attribués
    return produits.where((p) => p['estAttribue'] != true).toList();
  }

  /// Crée une nouvelle attribution pour le filtrage
  Future<ExtractionAttribution> creerAttribution({
    required ExtractionAttributionType type,
    required SiteAttribution siteDestination,
    required List<String> produitsExtraitsIds,
    required String extracteurId,
    required String extracteurNom,
    String? instructions,
    String? observations,
  }) async {
    // Vérifier que tous les produits existent et sont disponibles
    for (final produitId in produitsExtraitsIds) {
      final produit = _produitsExtraits[produitId];
      if (produit == null) {
        throw Exception('Produit extrait non trouvé: $produitId');
      }
      if (produit['estAttribue'] == true) {
        throw Exception('Produit déjà attribué: ${produit['codeContenant']}');
      }
      if (produit['estPretPourFiltrage'] != true) {
        throw Exception(
            'Produit pas prêt pour le filtrage: ${produit['codeContenant']}');
      }
    }

    // Générer un ID unique
    final id = 'ext_attr_${DateTime.now().millisecondsSinceEpoch}';

    // Créer l'attribution
    final attribution = ExtractionAttribution(
      id: id,
      type: type,
      siteDestination: siteDestination,
      produitsExtraitsIds: produitsExtraitsIds,
      dateAttribution: DateTime.now(),
      extracteurId: extracteurId,
      extracteurNom: extracteurNom,
      instructions: instructions,
      observations: observations,
    );

    // Sauvegarder
    _attributions[id] = attribution;

    // Marquer les produits comme attribués
    for (final produitId in produitsExtraitsIds) {
      _produitsExtraits[produitId]!['estAttribue'] = true;
      _produitsExtraits[produitId]!['attributionId'] = id;
    }

    if (kDebugMode) {
      print(
          '✅ Attribution créée: ${produitsExtraitsIds.length} produits attribués pour ${type.label}');
    }

    return attribution;
  }

  /// Récupère toutes les attributions
  Future<List<ExtractionAttribution>> getAttributions({
    ExtractionAttributionType? type,
    String? extracteurId,
    String? statut,
  }) async {
    var attributions = _attributions.values.toList();

    // Appliquer les filtres
    if (type != null) {
      attributions = attributions.where((a) => a.type == type).toList();
    }
    if (extracteurId != null) {
      attributions =
          attributions.where((a) => a.extracteurId == extracteurId).toList();
    }
    if (statut != null) {
      attributions = attributions.where((a) => a.statut == statut).toList();
    }

    // Trier par date (plus récent en premier)
    attributions.sort((a, b) => b.dateAttribution.compareTo(a.dateAttribution));

    return attributions;
  }

  /// Récupère une attribution par son ID
  Future<ExtractionAttribution?> getAttribution(String id) async {
    return _attributions[id];
  }

  /// Récupère les produits d'une attribution
  Future<List<Map<String, dynamic>>> getProduitsAttribution(
      String attributionId) async {
    final attribution = _attributions[attributionId];
    if (attribution == null) {
      return [];
    }

    final produits = <Map<String, dynamic>>[];
    for (final produitId in attribution.produitsExtraitsIds) {
      final produit = _produitsExtraits[produitId];
      if (produit != null) {
        produits.add(produit);
      }
    }

    return produits;
  }

  /// Met à jour le statut d'une attribution
  Future<ExtractionAttribution> updateStatutAttribution(
    String attributionId,
    String nouveauStatut, {
    String? observations,
  }) async {
    final attribution = _attributions[attributionId];
    if (attribution == null) {
      throw Exception('Attribution non trouvée: $attributionId');
    }

    final updatedAttribution = attribution.copyWith(
      statut: nouveauStatut,
      observations: observations ?? attribution.observations,
    );

    _attributions[attributionId] = updatedAttribution;

    if (kDebugMode) {
      print(
          '📝 Statut mis à jour pour attribution $attributionId: $nouveauStatut');
    }

    return updatedAttribution;
  }

  /// Annule une attribution
  Future<void> annulerAttribution(String attributionId) async {
    final attribution = _attributions[attributionId];
    if (attribution == null) {
      throw Exception('Attribution non trouvée: $attributionId');
    }

    // Libérer les produits
    for (final produitId in attribution.produitsExtraitsIds) {
      final produit = _produitsExtraits[produitId];
      if (produit != null) {
        produit['estAttribue'] = false;
        produit['attributionId'] = null;
      }
    }

    // Supprimer l'attribution
    _attributions.remove(attributionId);

    if (kDebugMode) {
      print('❌ Attribution annulée: $attributionId');
    }
  }

  /// Calcule les statistiques des attributions
  Future<Map<String, dynamic>> getStatistiques({
    String? extracteurId,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    var attributions = _attributions.values.toList();

    // Filtrer par extracteur si spécifié
    if (extracteurId != null) {
      attributions =
          attributions.where((a) => a.extracteurId == extracteurId).toList();
    }

    // Filtrer par période si spécifiée
    if (dateDebut != null) {
      attributions = attributions
          .where((a) => a.dateAttribution.isAfter(dateDebut))
          .toList();
    }
    if (dateFin != null) {
      attributions = attributions
          .where((a) => a.dateAttribution.isBefore(dateFin))
          .toList();
    }

    // Calculer les statistiques
    final totalAttributions = attributions.length;
    final enAttente =
        attributions.where((a) => a.statut == 'en_attente').length;
    final acceptees = attributions.where((a) => a.statut == 'accepte').length;
    final enCours = attributions.where((a) => a.statut == 'en_cours').length;
    final terminees = attributions.where((a) => a.statut == 'termine').length;

    var totalProduits = 0;
    var poidsTotal = 0.0;

    for (final attribution in attributions) {
      totalProduits += attribution.produitsExtraitsIds.length;

      for (final produitId in attribution.produitsExtraitsIds) {
        final produit = _produitsExtraits[produitId];
        if (produit != null) {
          poidsTotal += (produit['poidsExtrait'] as double? ?? 0.0);
        }
      }
    }

    return {
      'total_attributions': totalAttributions,
      'en_attente': enAttente,
      'acceptees': acceptees,
      'en_cours': enCours,
      'terminees': terminees,
      'total_produits': totalProduits,
      'poids_total': poidsTotal,
      'taux_acceptation': totalAttributions > 0
          ? (acceptees + enCours + terminees) / totalAttributions * 100
          : 0.0,
    };
  }

  /// Récupère un produit extrait par son ID
  Future<Map<String, dynamic>?> getProduitExtrait(String produitId) async {
    return _produitsExtraits[produitId];
  }

  /// Marque les produits comme prêts pour le filtrage
  Future<void> marquerProduitsPrets(List<String> produitsIds) async {
    for (final produitId in produitsIds) {
      final produit = _produitsExtraits[produitId];
      if (produit != null) {
        produit['estPretPourFiltrage'] = true;
      }
    }

    if (kDebugMode) {
      print(
          '✅ ${produitsIds.length} produits marqués comme prêts pour le filtrage');
    }
  }
}
